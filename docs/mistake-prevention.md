# Mistake Prevention Notes

This document records practical guardrails learned from Phases 1 through 4.

The goal is not to hide Terraform commands. The goal is to make the important
command combinations easy to check before running them.

## Before Terraform Commands

Confirm the current Git branch:

```bash
git status --short --branch
```

Expected result: the branch matches the current task and unrelated files are
not mixed into the worktree.

Reason: infrastructure changes are easier to review when each phase has its own
branch and focused diff.

Confirm the selected Azure subscription:

```bash
az account show --query "{name:name, id:id, tenantId:tenantId}" --output table
```

Expected result: Azure CLI shows the intended learning subscription.

Reason: Terraform provider operations use the selected Azure account context
unless another authentication method is configured.

## Match Backend And Var File

For the current root-module layout, run Terraform from the repository root and
pair the backend and var-file intentionally.

Dev:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"

terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform uses the `dev/terraform.tfstate` backend key and dev
input values.

Reason: backend configuration selects the state location, while the var-file
selects the desired resource names and tags.

Staging:

```bash
terraform init -reconfigure \
  -backend-config=environments/staging/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"

terraform plan -var-file=environments/staging/staging.tfvars
```

Expected result: Terraform uses the `staging/terraform.tfstate` backend key and
staging input values.

Reason: staging should not share dev state or dev resource names.

Prod:

```bash
terraform init -reconfigure \
  -backend-config=environments/prod/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"

terraform plan -var-file=environments/prod/prod.tfvars
```

Expected result: Terraform uses the `prod/terraform.tfstate` backend key and
prod input values.

Reason: production-like state should be isolated even in a learning repository.

## Check The Active Backend

After `terraform init`, inspect the backend metadata:

```bash
jq -r '.backend.type, .backend.config.key, .backend.config.storage_account_name' .terraform/terraform.tfstate
```

Expected result: output shows `azurerm`, the intended environment key, and the
backend Storage Account name.

Reason: `.terraform/terraform.tfstate` stores backend metadata for the working
directory. It is not the same as the remote infrastructure state file.

## Recover The Backend Storage Account Name

If `TFSTATE_STORAGE_ACCOUNT` is missing from the shell, list the Storage
Accounts in the backend Resource Group:

```bash
az storage account list \
  --resource-group terraform-learning-tfstate-rg \
  --query "[].{name:name, created:creationTime, location:primaryLocation}" \
  --output table
```

Expected result: Azure prints the backend Storage Account name, usually with a
`tflearn` prefix.

Reason: the backend Resource Group name is fixed, but the Storage Account name
has a random suffix for global uniqueness.

Set it again when the correct account is clear:

```bash
export TFSTATE_STORAGE_ACCOUNT="<storage-account-name>"
```

Expected result: later `terraform init` commands can pass the Storage Account
name without editing committed backend files.

Reason: Storage Account names are subscription-specific, so this repository does
not commit that value.

## Remember The Actor

Backend access depends on the actor running Terraform.

```text
Actor                 Auth path       Backend option
--------------------  --------------  ----------------
Local user            az login        use_cli=true
GitHub Actions SP     GitHub OIDC     use_oidc=true
```

Expected result: local and CI commands use different backend authentication
options.

Reason: a local shell does not have GitHub's OIDC token environment, and GitHub
Actions does not use the local Azure CLI login.

Both actors need backend blob access:

```text
Storage Blob Data Contributor
```

Expected result: Terraform can read and update the remote state blob.

Reason: `use_azuread_auth=true` uses Azure RBAC data-plane authorization
instead of Storage Account key lookup.

## Do Not Overread Validate

Run:

```bash
terraform validate
```

Expected result: Terraform reports whether the configuration is syntactically
and semantically valid according to initialized provider schemas.

Reason: validation checks configuration shape. It does not prove Azure
resources match the configuration.

Use plan for configuration, state, and real resource comparison:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform reports planned creates, updates, destroys, or no
changes.

Reason: `plan` is the command that compares configuration, state, and remote
infrastructure.

## Keep Apply And Destroy Explicit

Before apply:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: the plan clearly shows the resources that will be created or
changed.

Reason: apply should be based on a reviewed plan, not on command memory.

Before destroy:

```bash
terraform plan -destroy -var-file=environments/dev/dev.tfvars
```

Expected result: the plan clearly shows only the intended learning resources.

Reason: destroy is useful for cleanup, but it should remain an explicit action.

After a successful learning apply, destroy resources when they are no longer
needed:

```bash
terraform destroy -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform removes the dev resources managed by the active dev
state.

Reason: learning resources should not keep running unless they are intentionally
needed for the next exercise.

## When A Command Fails

Capture the pattern before changing several things at once.

Useful checks:

```bash
git status --short --branch
jq -r '.backend.type, .backend.config.key' .terraform/terraform.tfstate
terraform state list
az account show --query "{name:name, id:id, tenantId:tenantId}" --output table
```

Expected result: these commands identify the branch, active backend,
Terraform-managed resource addresses, and Azure account context.

Reason: most mistakes so far have been caused by context mismatch rather than
invalid Terraform syntax.
