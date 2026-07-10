# 2026-07-10 Session Retrospective: Phase 4 Azure RBAC

## Goal

Debug the failing Phase 4 GitHub Actions workflow and document the Azure RBAC
permissions required by the GitHub Actions service principal.

## What Happened

- Checked PR #9 GitHub Actions logs with `gh`.
- Confirmed Azure OIDC login succeeded.
- Found `terraform init` failed while retrieving the backend Storage Account.
- Identified missing management-plane authorization:
  `Microsoft.Storage/storageAccounts/read`.
- Added `Reader`, then found the next failure was Storage Account key lookup:
  `Microsoft.Storage/storageAccounts/listKeys/action`.
- Chose not to grant `Storage Account Key Operator Service Role`.
- Updated the workflow to initialize the backend with Microsoft Entra ID and
  GitHub OIDC by passing `use_azuread_auth=true` and `use_oidc=true`.
- Kept local manual execution separate by documenting
  `use_azuread_auth=true` and `use_cli=true`.
- Found that local `terraform init` can still fail if the signed-in Azure CLI
  user lacks backend blob data-plane access.
- Confirmed local `terraform init` and `terraform plan` work after local user
  RBAC and required `TF_VAR_*` values are set.
- Updated Phase 4 documentation and the Phase 4 plan with the required roles
  and verification commands.

## Error Pattern

The workflow failed during `terraform init`:

```text
Error: retrieving Storage Account
unexpected status 403 (403 Forbidden)
AuthorizationFailed
Microsoft.Storage/storageAccounts/read
```

After granting `Reader`, the next workflow run reached the backend container
client step and failed on Storage Account key lookup:

```text
Failed to get existing workspaces
retrieving key for Storage Account
Microsoft.Storage/storageAccounts/listKeys/action
```

Expected result after the final fix: GitHub Actions can initialize the Azure
Blob Storage backend before running `terraform validate`, without retrieving a
Storage Account key.

Reason: OIDC authentication proves the workflow can log in as the Azure
application, but Azure RBAC still controls what that identity can read or write.
The second error showed that the backend was still trying to use Access Key
Lookup. Passing `use_azuread_auth=true` and `use_oidc=true` switches the backend
to Microsoft Entra ID and GitHub OIDC for state blob access.

A local test with `use_cli=true` failed differently:

```text
AuthorizationPermissionMismatch
listing blobs
```

Reason: the local backend path uses the signed-in Azure CLI user, not the GitHub
Actions service principal. That user also needs `Storage Blob Data Contributor`
on the backend Resource Group or narrower backend container scope.

## Required Roles

Assign this role at the backend Resource Group scope:

```text
Storage Blob Data Contributor
```

Expected result: Terraform can access the state blob through Azure RBAC.

Reason: `Storage Blob Data Contributor` covers data-plane access to the
Terraform state blob. With Microsoft Entra ID backend authentication, Terraform
does not need `Microsoft.Storage/storageAccounts/listKeys/action`.

`Reader` is only needed when the backend must look up the blob endpoint from the
Azure management plane, such as with `lookup_blob_endpoint=true`. This repo does
not set that option.

## Commands Worth Remembering

Recover IDs:

```bash
export AZURE_SP_OBJECT_ID="$(az ad sp show \
  --id "$AZURE_CLIENT_ID" \
  --query id \
  --output tsv)"
export TFSTATE_RESOURCE_GROUP_ID="$(az group show \
  --name terraform-learning-tfstate-rg \
  --query id \
  --output tsv)"
```

Grant access:

```bash
az role assignment create \
  --assignee-object-id "$AZURE_SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID"
```

Confirm access:

```bash
az role assignment list \
  --assignee "$AZURE_SP_OBJECT_ID" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID" \
  --query "[].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Expected result: Azure prints the backend data-plane role.

```text
Role                           Scope
-----------------------------  ------------------------------------------------
Storage Blob Data Contributor  /subscriptions/.../resourceGroups/terraform-learning-tfstate-rg
```

Check local user access:

```bash
export AZURE_USER_OBJECT_ID="$(az ad signed-in-user show \
  --query id \
  --output tsv)"

az role assignment list \
  --assignee "$AZURE_USER_OBJECT_ID" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID" \
  --query "[].{role:roleDefinitionName, scope:scope}" \
  --output table
```

Grant local user access if needed:

```bash
az role assignment create \
  --assignee-object-id "$AZURE_USER_OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID"
```

If a role was assigned directly to the Storage Account, search more broadly:

```bash
az role assignment list \
  --assignee "$AZURE_SP_OBJECT_ID" \
  --query "[?contains(scope, 'terraform-learning-tfstate-rg')].{role:roleDefinitionName, scope:scope}" \
  --output table
```

CI backend initialization:

```bash
terraform init \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_oidc=true"
```

Local backend initialization:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true" \
&& terraform validate
```

Expected result: CI uses GitHub OIDC, while local manual commands use the
pre-authenticated Azure CLI session.

Reason: `use_oidc=true` depends on the GitHub Actions OIDC token environment,
which local shells do not have.

Use `&& terraform validate` so a failed init does not get hidden by a later
validate command that can reuse old local `.terraform` metadata.

Local plan variable setup:

```bash
export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"

terraform plan -var-file=environments/dev/dev.tfvars.example
```

Expected result: Terraform reads the remote state and prints a plan for the dev
example values.

Reason: `subscription_id`, `admin_ssh_public_key`, and `allowed_ssh_cidr` are
not committed to the repository. They must come from local shell variables for
manual plans.

## Validation Completed

- `gh pr checks 9`
- GitHub Actions log inspection with `gh`
- Azure RBAC role assignment confirmation by command
- `git diff --check`

No `terraform apply` or `terraform destroy` was run.

## Follow-Up

- Re-run the failed GitHub Actions workflow after pushing the backend auth
  change.
- Confirm `terraform init` and `terraform validate` pass in PR #9.
- Re-run local `terraform init -reconfigure` and `terraform plan` if the
  backend authentication settings change again.
- Destroy learning resources when they are no longer needed.
