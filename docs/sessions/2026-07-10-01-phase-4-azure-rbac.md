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
- Confirmed the service principal needs both `Reader` and `Storage Blob Data
  Contributor` on the backend Resource Group.
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

Expected result after the fix: GitHub Actions can initialize the Azure Blob
Storage backend before running `terraform validate`.

Reason: OIDC authentication proves the workflow can log in as the Azure
application, but Azure RBAC still controls what that identity can read or write.

## Required Roles

Assign both roles at the backend Resource Group scope:

```text
Reader
Storage Blob Data Contributor
```

Expected result: Terraform can read the Storage Account resource and access the
state blob.

Reason: `Reader` covers management-plane reads such as
`Microsoft.Storage/storageAccounts/read`. `Storage Blob Data Contributor` covers
data-plane access to the Terraform state blob.

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
  --role "Reader" \
  --scope "$TFSTATE_RESOURCE_GROUP_ID"

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

Expected result: Azure prints both required roles.

```text
Role                           Scope
-----------------------------  ------------------------------------------------
Reader                         /subscriptions/.../resourceGroups/terraform-learning-tfstate-rg
Storage Blob Data Contributor  /subscriptions/.../resourceGroups/terraform-learning-tfstate-rg
```

If a role was assigned directly to the Storage Account, search more broadly:

```bash
az role assignment list \
  --assignee "$AZURE_SP_OBJECT_ID" \
  --query "[?contains(scope, 'terraform-learning-tfstate-rg')].{role:roleDefinitionName, scope:scope}" \
  --output table
```

## Validation Completed

- `gh pr checks 9`
- GitHub Actions log inspection with `gh`
- Azure RBAC role assignment confirmation by command
- `git diff --check`

No `terraform apply` or `terraform destroy` was run.

## Follow-Up

- Re-run the failed GitHub Actions workflow after Azure RBAC propagation.
- Confirm `terraform init` and `terraform validate` pass in PR #9.
- Destroy learning resources when they are no longer needed.
