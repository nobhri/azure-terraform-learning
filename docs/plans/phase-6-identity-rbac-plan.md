# Phase 6 Plan: Identity And RBAC

## Goal

Add Azure identity and RBAC concepts used by data platform infrastructure while
keeping the resource scope small.

This phase should teach who can access what, at which Azure scope, and through
which identity. It should not add private endpoints, private DNS, or broader
network control.

## Planned Changes

- Add a user-assigned managed identity.
- Attach the managed identity to the learning VM.
- Add a small Storage Account for identity and RBAC experiments.
- Add a Blob Container for access testing.
- Add a Blob data-plane role assignment at the container scope.
- Document local user, GitHub Actions service principal, and managed identity
  as separate actors.
- Add a Phase 6 guide under `docs/`.
- Update the roadmap and README current focus now that Phase 5 is complete.

Implement the new identity, Storage Account, container, and role assignment in
the `dev` root module. Keep the shared `linux-vm` module responsible only for
attaching identity IDs supplied by its caller. This keeps the Phase 6 dependency
graph visible without adding a new module before the resources are understood.

## Identity Model To Teach

The phase should distinguish these actors:

```text
Actor                       Where it runs              Main purpose
--------------------------  -------------------------  ------------------------
Local Azure CLI user        Developer machine          Manual Terraform commands
GitHub Actions SP           GitHub Actions runner      CI validation
VM managed identity         Azure VM                   Azure access from workload
```

Expected result: each identity has a clear purpose.

Reason: Azure access problems are easier to debug when authentication identity
and authorization scope are separated.

## RBAC Scope Model

Use a narrow, visible scope for the new learning resources.

Scopes to compare conceptually:

- backend Resource Group for Terraform state access
- workload Resource Group for VM and experiment resources
- Storage Account for storage-specific access
- Blob Container for the narrowest storage data-plane access

Expected result: role assignments can be compared at different Azure scopes.

Reason: data platform work often depends on understanding whether a permission
is granted at subscription, Resource Group, Storage Account, container, or
service-specific scope.

Use the Blob Container as the implemented role assignment scope. It is the
narrowest scope in this experiment and makes the least-privilege boundary
visible. Storage Account scope can be tried later as a deliberate comparison.

## Proposed Resources

Add a user-assigned managed identity:

```hcl
resource "azurerm_user_assigned_identity" "vm_workload" {
  name                = "${var.project_name}-uami"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
```

Expected result: Azure creates a reusable managed identity in the environment
Resource Group.

Reason: user-assigned managed identities are explicit resources that can be
attached to compute and granted RBAC roles.

Attach it to the VM:

```hcl
identity {
  type         = "UserAssigned"
  identity_ids = var.identity_ids
}
```

Expected result: the VM can request Azure tokens as the managed identity.

Reason: workloads should avoid long-lived credentials when they can use managed
identity.

Add a small Storage Account and container for access testing. Build the globally
unique Storage Account name from a short project prefix and a lowercase
`random_string` suffix. The suffix remains stable in Terraform state after its
first creation, while forks using independent state receive different names.

Expected result: the managed identity has a concrete Azure data-plane target.

Reason: Storage Blob access is familiar from the Terraform backend, but this
phase should use a separate workload Storage Account so backend permissions and
workload permissions do not get mixed together.

## Role Assignment Experiments

Grant the VM managed identity read-only blob access first:

```text
Storage Blob Data Reader
```

Expected result: a workload using the VM managed identity can read blobs but not
write them.

Reason: read-only access is a safe starting point for observing data-plane
permissions.

After the reader behavior is understood, optionally change to:

```text
Storage Blob Data Contributor
```

Expected result: the managed identity can read and write blobs in the selected
scope.

Reason: comparing reader and contributor behavior makes the permission boundary
clear.

Keep management-plane roles separate from data-plane roles.

Expected result: a role that can manage a Storage Account is not confused with
a role that can read or write blob data.

Reason: Phase 4 already showed that Azure management-plane and data-plane
permissions fail differently.

## Validation Commands

Inspect the VM identity:

```bash
az vm show \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw vm_name)" \
  --query identity \
  --output json
```

Expected result: Azure shows the user-assigned identity attached to the VM.

Reason: this confirms the compute resource has the identity before testing RBAC.

List role assignments for the managed identity:

```bash
az role assignment list \
  --assignee "<managed-identity-principal-id>" \
  --query "[].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Expected result: Azure prints the role assigned to the managed identity and the
scope where it applies.

Reason: RBAC debugging starts by confirming the principal, role, and scope.

From the VM, request a managed identity token:

```bash
curl --fail --silent --output /dev/null \
  --header Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/&client_id=<managed-identity-client-id>" \
  --noproxy "*"
```

Expected result: the command exits successfully without printing the access
token.

Reason: this proves the workload can authenticate as the managed identity. Do
not print or paste the token into chat or documentation.

Before apply, confirm the Terraform actor can create role assignments at the
container scope. Authentication and Storage Account management permissions do
not by themselves grant `Microsoft.Authorization/roleAssignments/write`.

## Terraform Verification

Run formatting:

```bash
terraform fmt -recursive
```

Expected result: Terraform files are formatted.

Reason: identity and RBAC changes may touch modules and environment wrappers.

Run validation:

```bash
cd environments/dev
terraform validate
```

Expected result: Terraform validates the identity and role assignment
configuration.

Reason: provider schema checks can catch incorrect identity and RBAC arguments.

Run a plan for dev:

```bash
cd environments/dev
terraform plan
```

Expected result: Terraform shows the managed identity, attachment, Storage
Account, container, and role assignment that will be created or changed.

Reason: the plan should be reviewed before applying RBAC changes.

## Documentation To Add

Create `docs/phase-6-identity-rbac.md` with:

- local user vs GitHub Actions service principal vs managed identity
- authentication vs authorization
- management plane vs data plane
- role, principal, and scope
- why backend state permissions are separate from workload permissions
- why managed identity avoids long-lived workload credentials
- how to inspect identity and role assignments with Azure CLI
- how to test managed identity from the VM without sharing tokens

## Out Of Scope

- Private Endpoint
- Private DNS Zone
- Route Table
- NAT Gateway
- GitHub Actions apply automation
- Custom RBAC roles
- Databricks workspace deployment
