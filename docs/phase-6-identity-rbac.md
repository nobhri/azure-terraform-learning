# Phase 6: Identity And RBAC

Phase 6 gives the dev VM a user-assigned managed identity and grants that
identity read-only access to one private Blob Container. The backend Storage
Account remains separate from this workload experiment.

## Identity And Access Model

```text
Actor                       Authentication             Main authorization
--------------------------  -------------------------  ---------------------------
Local Azure CLI user        Azure CLI login            Manual Terraform operations
GitHub Actions principal    GitHub OIDC                 CI init and validation
VM managed identity         Azure Instance Metadata    Read the workload container
```

Authentication establishes who the actor is. Authorization decides which
actions that actor may perform at an Azure scope. The managed identity avoids a
client secret on the VM, but it still needs an RBAC role assignment.

`Storage Blob Data Reader` is a data-plane role: it permits reading Blob data.
It does not grant management-plane permission to configure the Storage Account.
The assignment uses the Blob Container resource ID as its scope, so the VM does
not receive access to every container in the Storage Account.

## Terraform Design

The dev root module owns the managed identity, workload Storage Account,
container, and role assignment. It passes the identity ID into the shared
`linux-vm` module for attachment.

The Storage Account name combines a shortened project prefix with an
eight-character lowercase random suffix. Azure Storage Account names are
globally unique and accept only lowercase letters and numbers. Terraform stores
the generated suffix in state, so it remains stable for that environment while
an independent fork gets a different name. Only the resources introduced in
this phase receive the `phase = "6"` tag; existing resources keep their original
learning-phase tags.

## Prepare And Verify

Set the same local inputs used by the earlier dev phases, then initialize from
the dev root module:

```bash
cd environments/dev

terraform init -reconfigure \
  -backend-config=backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"

terraform fmt -check -recursive ../..
terraform validate
terraform plan
```

Expected result: the plan adds a random suffix, managed identity, workload
Storage Account, private container, and container-scoped reader assignment. It
also updates the existing VM to attach the identity.

Reason: reviewing these resources together exposes the complete principal,
role, and scope relationship before any permission is applied.

Before applying, the local Azure identity must be able to create role
assignments at the selected scope. This requires
`Microsoft.Authorization/roleAssignments/write`; ordinary resource management
permission may not include it.

## Inspect The Result

Inspect the identity attached to the VM:

```bash
az vm show \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw vm_name)" \
  --query identity \
  --output json
```

Expected result: the VM shows the user-assigned identity from the Terraform
output.

List its role assignments:

```bash
az role assignment list \
  --assignee "$(terraform output -raw managed_identity_principal_id)" \
  --query "[].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Expected result: `Storage Blob Data Reader` appears at the private container
scope.

From the VM, check that Azure Instance Metadata can issue a Storage token
without displaying the token itself:

```bash
curl --fail --silent --output /dev/null \
  --header Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/&client_id=<managed-identity-client-id>" \
  --noproxy "*"
```

Expected result: `curl` exits with status zero and prints no token. Use
`terraform output -raw managed_identity_client_id` on the developer machine to
obtain the client ID before connecting to the VM.

Reason: successful token acquisition proves authentication. A separate Blob
read/write exercise proves authorization: Reader should allow a read and deny a
write. Never paste an access token into chat or documentation.

Destroy learning resources after the exercise unless they are intentionally
needed for Phase 7.
