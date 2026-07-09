# 2026-07-09 Session Retrospective: Phase 3 Backend Validation

## Goal

Continue Phase 3 validation by testing Azure Blob Storage remote backend
behavior after creating the backend Resource Group, Storage Account, and Blob
Container manually.

## What Happened

- Switched from the Phase 2 tag to the Phase 3 branch after creating dev
  resources with local state.
- Initialized the Phase 3 remote backend with `terraform init -reconfigure`
  instead of `terraform init -migrate-state`.
- This configured Terraform to use the remote backend, but it did not copy the
  existing local state into Azure Blob Storage.
- Confirmed that `environments/dev` is not a Terraform root module. It contains
  environment inputs and state files, while the real root module is the
  repository root.
- Confirmed that `terraform state list` prints Terraform resource addresses,
  not Azure resource names. For example, `azurerm_resource_group.main` can map
  to an Azure Resource Group whose real name includes the environment suffix.
- Pushed the existing dev local state to the configured remote backend and
  verified that `terraform plan -var-file=environments/dev/dev.tfvars` reported
  no changes.
- Initialized and planned both staging and prod remote backend configurations.

## Important Lesson

`terraform init -reconfigure` and `terraform init -migrate-state` solve
different problems.

`-reconfigure` tells Terraform to forget the previous backend selection and use
the backend settings supplied now. It does not move state.

`-migrate-state` tells Terraform to copy state from the previously configured
backend to the newly configured backend.

If `-reconfigure` is used first by mistake and the remote state is empty, a
valid local state file can still be pushed explicitly:

```bash
terraform state push environments/dev/terraform.tfstate
```

Expected result: Terraform writes the local dev state snapshot to the currently
configured remote backend.

Reason: after backend reconfiguration, Terraform no longer has the old backend
migration context, so an explicit state push is the direct recovery path.

## Commands Worth Remembering

Initialize the dev remote backend from the repository root:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform configures the AzureRM backend with the
`dev/terraform.tfstate` key.

Reason: backend files are relative to the root module, not to the environment
directory.

Check the active backend metadata:

```bash
jq -r '.backend.type, .backend.config.key, .backend.config.storage_account_name' .terraform/terraform.tfstate
```

Expected result: the output shows `azurerm`, the selected environment key, and
the backend Storage Account name.

Reason: `.terraform/terraform.tfstate` stores backend metadata, while normal
Terraform state stores managed resource mappings.

Validate that dev remote state matches real resources:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: no changes after the dev local state has been pushed to the
remote backend.

Reason: no changes means configuration, state, and Azure resources agree.

Initialize staging:

```bash
terraform init -reconfigure \
  -backend-config=environments/staging/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Then plan:

```bash
terraform plan -var-file=environments/staging/staging.tfvars
```

Expected result: Terraform uses `staging/terraform.tfstate` and produces a plan
for the staging values.

Reason: staging has its own backend key and variable file, so it should not
share state with dev.

Initialize prod:

```bash
terraform init -reconfigure \
  -backend-config=environments/prod/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Then plan:

```bash
terraform plan -var-file=environments/prod/prod.tfvars
```

Expected result: Terraform uses `prod/terraform.tfstate` and produces a plan for
the prod values.

Reason: planning prod verifies backend wiring without creating production
learning resources.

## Validation Completed

- Dev remote backend initialized.
- Dev local state pushed to remote backend.
- Dev plan returned no changes.
- Staging remote backend initialized and planned.
- Prod remote backend initialized and planned.

No `terraform apply` was needed for staging or prod during this session.

## Cleanup Reminder

The dev learning resources should be destroyed when they are no longer needed:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"

terraform plan -destroy -var-file=environments/dev/dev.tfvars
terraform destroy -var-file=environments/dev/dev.tfvars
```

Expected result: the destroy plan should show only the dev resources managed by
the dev remote state.

Reason: learning resources should not be left running after validation unless
they are intentionally needed for the next exercise.

## Follow-Up

- Decide whether to run the dev destroy now or keep the resources temporarily
  for Phase 3 PR verification.
- In the PR description, state that staging and prod were validated with
  `terraform init` and `terraform plan`, but were not applied.
- Consider documenting the mistaken `-reconfigure` recovery path in the Phase 3
  guide if this error feels likely to happen again.
