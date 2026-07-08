# 2026-07-08 Session 05: Phase 3 Remote Backend

## Goal

Implement Phase 3 from the existing plan documents and record the learning
decisions around Azure Blob Storage remote state.

## What Changed

- Changed the root Terraform backend from `local` to `azurerm`.
- Updated `dev`, `staging`, and `prod` backend files to use Azure Blob Storage
  settings with separate state keys:
  - `dev/terraform.tfstate`
  - `staging/terraform.tfstate`
  - `prod/terraform.tfstate`
- Added the Phase 3 guide:
  - `docs/phase-3-remote-backend.md`
- Updated the README current focus to Phase 3.
- Updated the Phase 3 plan document to match the implemented backend shape.
- Corrected old Phase 2 guide roadmap wording so Phase 3 is remote backend
  only and Phase 4 is GitHub Actions foundation.

## Backend Configuration Decision

The committed backend files do not include `storage_account_name`.

Reason: Azure Storage Account names are globally unique and environment-specific
to the learner's Azure account. Committing a placeholder would require editing
tracked files after bootstrap, and committing a real name would make the repo
less reusable.

Instead, the Storage Account name is passed during `terraform init`:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

The Storage Account name is generated with a fixed prefix and random suffix:

```bash
export TFSTATE_STORAGE_ACCOUNT="tflearn$(openssl rand -hex 6)"
```

This keeps the command simple while producing a lowercase, recognizable,
globally unique name candidate.

## State Migration Decision

Migration from local state to Azure Blob Storage is useful to try once because
it shows that Terraform state is the mapping between configuration and real
Azure resources. Changing the backend changes where that mapping is stored; it
does not recreate resources by itself.

Recommended learning path:

- Try migration only for `dev` if Phase 2 dev resources and local state exist.
- Skip migration for `staging` and `prod` unless those environments have real
  resources that need to remain managed.
- If Phase 2 resources were already destroyed, skip migration and initialize the
  remote backend fresh.

Migration command for dev:

```bash
terraform init -migrate-state \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

After migration, run:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected learning result: existing dev resources should not be recreated just
because the state storage moved.

## Verification Done

Ran:

```bash
terraform fmt
terraform validate
```

Result: both succeeded.

Note: `terraform fmt` printed a `tenv` warning because the sandbox could not
write `~/.tenv/.../last-use.txt`. The Terraform command itself still completed.

Azure backend bootstrap and remote `terraform init` were not completed in this
session because the learner chose to run Azure-side validation manually.

## Current Git State

Work is on branch:

```text
codex-phase-3-implementation
```

The Phase 3 changes are intentionally uncommitted at the time of this
retrospective.

## Useful Next Commands

If testing Phase 2 dev deployment before remote backend migration:

```bash
git stash push -u -m "wip phase 3 remote backend"
git switch --detach phase-2-complete
```

Deploy Phase 2 dev:

```bash
cp environments/dev/dev.tfvars.example environments/dev/dev.tfvars
export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
terraform fmt
terraform validate
terraform plan -var-file=environments/dev/dev.tfvars
terraform apply -var-file=environments/dev/dev.tfvars
```

Destroy Phase 2 dev resources after learning:

```bash
terraform destroy -var-file=environments/dev/dev.tfvars
```

Return to Phase 3 work:

```bash
git switch codex-phase-3-implementation
git stash pop
```

## Follow-Up

- Manually bootstrap the Azure Blob Storage backend.
- Run `terraform init` with the `storage_account_name` backend override.
- Decide whether to do a dev-only `-migrate-state` test or start with fresh
  remote state.
- Commit and push the Phase 3 implementation after validation.
