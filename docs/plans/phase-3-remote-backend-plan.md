# Phase 3 Plan: Remote Backend

## Goal

Move Terraform state from local files to Azure Blob Storage while keeping the
existing `dev`, `staging`, and `prod` environment boundaries.

This phase should not add GitHub Actions, `terraform plan` automation, or
`terraform apply` automation. The learning goal is remote state and backend
configuration only.

## Planned Changes

- Change the Terraform backend in `main.tf` from `local` to `azurerm`.
- Update each environment backend file:
  - `environments/dev/backend.hcl`
  - `environments/staging/backend.hcl`
  - `environments/prod/backend.hcl`
- Use one Azure Storage Account and one Blob Container for state.
- Use a different backend `key` for each environment:
  - `dev/terraform.tfstate`
  - `staging/terraform.tfstate`
  - `prod/terraform.tfstate`
- Add a Phase 3 guide under `docs/`.
- Update `README.md` so Phase 3 is the current focus.

## Backend Shape

The root Terraform configuration should declare the backend type without
subscription-specific values:

```hcl
terraform {
  backend "azurerm" {}
}
```

The environment backend files should provide the backend settings:

```hcl
resource_group_name  = "terraform-learning-tfstate-rg"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
```

Use the same Resource Group, Storage Account, and Container for all
environments. The committed backend files change only `key` per environment.
Pass the globally unique Storage Account name during `terraform init` so it does
not need to be committed.

## Documentation To Add

Create `docs/phase-3-remote-backend.md` with:

- What remote state is
- Why local state is not enough for team workflows
- What Azure Blob Storage provides
- What state locking means
- Why backend config is separate from normal Terraform variables
- How `dev`, `staging`, and `prod` state keys stay separate
- How to bootstrap the backend storage with Azure CLI
- How to reinitialize Terraform with the remote backend
- How to think about local state migration
- Safety notes about not sharing state contents

## Bootstrap Commands To Document

Choose a Storage Account name:

```bash
export TFSTATE_STORAGE_ACCOUNT="tflearn$(openssl rand -hex 6)"
```

Expected result: the shell variable contains a recognizable, globally unique
Storage Account name candidate.

Reason: Azure Storage Account names must be globally unique, lowercase, and
between 3 and 24 characters.

Create the backend Resource Group:

```bash
az group create \
  --name terraform-learning-tfstate-rg \
  --location japaneast
```

Expected result: Azure creates a Resource Group for Terraform state storage.

Reason: the remote backend needs to exist before Terraform can store state in
it.

Create the Storage Account:

```bash
az storage account create \
  --name "$TFSTATE_STORAGE_ACCOUNT" \
  --resource-group terraform-learning-tfstate-rg \
  --location japaneast \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2
```

Expected result: Azure creates a Storage Account that can hold Terraform state.

Reason: Azure Blob Storage is the remote backend used by the `azurerm` backend.

Create the Blob Container:

```bash
az storage container create \
  --name tfstate \
  --account-name "$TFSTATE_STORAGE_ACCOUNT" \
  --auth-mode login
```

Expected result: Azure creates a `tfstate` Blob Container.

Reason: Terraform stores each environment state file as a blob inside this
container.

Initialize the dev backend:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform configures the Azure Blob Storage backend and uses
the `dev/terraform.tfstate` key.

Reason: backend settings are selected during `terraform init`, before normal
input variables are evaluated.

Document optional dev state migration:

```bash
terraform init -migrate-state \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform asks whether to copy existing dev local state to the
remote backend.

Reason: migration is useful to learn that backend changes move where Terraform
stores the state mapping; they do not recreate resources by themselves.

## Verification

Run formatting:

```bash
terraform fmt
```

Expected result: Terraform files are formatted.

Reason: formatting does not require Azure access or an initialized backend.

After the backend storage exists, run:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
terraform validate
```

Expected result: Terraform initializes the remote backend and reports that the
configuration is valid.

Reason: `terraform validate` needs initialized provider and backend metadata.

Do not run `terraform apply` or `terraform destroy` unless explicitly requested.

## Out Of Scope

- GitHub Actions
- OIDC authentication
- CI `terraform plan`
- CI `terraform apply`
- GitHub Environments
- Approval gates
