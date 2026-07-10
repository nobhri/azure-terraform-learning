# Phase 3: Remote Backend

This phase moves Terraform state from local files to Azure Blob Storage while
keeping the existing `dev`, `staging`, and `prod` environment boundaries.

The Terraform resource definitions still live at the repository root. Each
environment now selects a different blob key in the same remote backend
container, so the state is shared safely without mixing environments.

## What This Adds

- Azure Blob Storage remote backend
- Remote Terraform state
- State locking
- Environment-specific remote state keys
- Backend bootstrap commands

## Why

Terraform state maps the configuration in this repository to real Azure
resources. Local state is useful when learning alone, but it is not enough for
team workflows because the state file lives on one machine and does not prevent
two people from changing the same environment at the same time.

Azure Blob Storage gives Terraform a shared state location. The AzureRM backend
also supports state locking, which means one Terraform operation can hold the
state lock while it plans or applies changes. That reduces the chance of
concurrent Terraform runs corrupting or racing the same state.

State can contain resource IDs, generated values, and other infrastructure
details. Do not paste state contents into chat, commits, issues, or pull
requests.

## Backend And Tfvars

Backend configuration and normal Terraform variables are separate.

The backend file controls where Terraform stores state:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform configures Azure Blob Storage as the backend and
uses the `dev/terraform.tfstate` blob key.

Reason: Terraform must know where state lives before it evaluates variables.
Backend configuration cannot use values such as `var.project_name`, so the
backend is selected during `terraform init`.

The `.tfvars` file controls values used by the resources:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform plans resources named with the
`terraform-learning-dev` prefix and tagged with `environment = "dev"`.

Reason: the backend key selects the state boundary, while `-var-file` selects
the input values for the resources in that state.

## Environment State Keys

All environments use the same backend Resource Group, Storage Account, and Blob
Container. Only the state key changes:

- `dev/terraform.tfstate`
- `staging/terraform.tfstate`
- `prod/terraform.tfstate`

This keeps the storage setup small while making environment separation visible.
Before running `plan`, `apply`, or `destroy`, make sure the backend file and
`.tfvars` file point to the same environment.

## Prerequisites

- Complete the Phase 2 prerequisites
- Azure CLI logged in to the subscription used for this learning project
- Permission to create a Resource Group, Storage Account, and Blob Container
- `openssl` available locally for generating a random suffix

Log in to Azure:

```bash
az login
az account set --subscription "<subscription-id>"
```

Expected result: Azure CLI is authenticated and set to the subscription used for
this learning project.

Choose a Storage Account name:

```bash
export TFSTATE_STORAGE_ACCOUNT="tflearn$(openssl rand -hex 6)"
```

Expected result: the shell variable contains a Storage Account name such as
`tflearn9f3a12c8d4e0`.

Reason: Azure Storage Account names must be globally unique, lowercase, and
between 3 and 24 characters. The fixed `tflearn` prefix keeps the name
recognizable, and the random suffix makes name collisions unlikely.

If a later shell session no longer has this variable, list the Storage Accounts
in the backend Resource Group:

```bash
az storage account list \
  --resource-group terraform-learning-tfstate-rg \
  --query "[].name" \
  --output table
```

Expected result: Azure prints the backend Storage Account name, usually with a
`tflearn` prefix.

Reason: the Resource Group name is fixed for this learning project, while the
Storage Account name includes a random suffix.

If there is only one Storage Account in the backend Resource Group, restore the
shell variable:

```bash
export TFSTATE_STORAGE_ACCOUNT="$(az storage account list \
  --resource-group terraform-learning-tfstate-rg \
  --query "[0].name" \
  --output tsv)"
```

Expected result: `TFSTATE_STORAGE_ACCOUNT` is set again for `terraform init`
commands.

Reason: backend files intentionally avoid committing the globally unique
Storage Account name.

## Bootstrap The Backend Storage

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
If Azure reports that the name is already taken, run the `export
TFSTATE_STORAGE_ACCOUNT=...` command again and retry this command.

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

## Configure Backend Files

Each committed backend file contains only shared backend settings and the
environment-specific state key:

```hcl
resource_group_name  = "terraform-learning-tfstate-rg"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
```

Expected result: each environment backend file points at the same Resource
Group and Container, and uses its own `key`.

Reason: Terraform backend files are read by `terraform init`. The Storage
Account name is passed separately from the `TFSTATE_STORAGE_ACCOUNT`
environment variable so the globally unique name does not need to be committed.

## Reinitialize Terraform

Initialize the dev backend:

```bash
terraform init -reconfigure \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform configures the Azure Blob Storage backend and uses
the `dev/terraform.tfstate` key.

Reason: `-reconfigure` tells Terraform to use the backend settings passed for
this environment.

Then validate:

```bash
terraform validate
```

Expected result: Terraform reports that the configuration is valid.

Reason: validation checks the Terraform syntax and provider schemas after the
working directory has been initialized.

## Migrating Local State

If an environment already has local state from Phase 2, decide whether to
migrate it or start fresh.

State migration is worth trying once because it shows that Terraform state is
the mapping between this configuration and the real Azure resources already
managed by Terraform. Changing the backend does not recreate resources by
itself; it changes where that mapping is stored.

For this learning project, use `dev` as the migration experiment if it already
has local state and resources that should remain managed:

```bash
terraform init -migrate-state \
  -backend-config=environments/dev/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
```

Expected result: Terraform asks whether to copy the existing local state to the
Azure Blob Storage backend.

Reason: `-migrate-state` tells Terraform to move the current state from the old
backend to the new backend instead of only reconfiguring the backend settings.

Before accepting the prompt, check that the destination key is
`dev/terraform.tfstate`. This prevents accidentally copying one environment's
state to another environment's remote state key.

After migration, run:

```bash
terraform plan -var-file=environments/dev/dev.tfvars
```

Expected result: Terraform should not plan to recreate existing dev resources
just because the backend moved.

Reason: the state mapping should be the same; only the storage location changed.

For `staging` and `prod`, skip migration unless those environments already have
local state and real resources that need to remain managed. Migrating empty
state has little learning value and increases the chance of selecting the wrong
environment key.

For a learning environment with no resources that need to remain, the simplest
path is often to destroy the old resources first, then initialize the remote
backend with `-reconfigure` and create resources again later.

Do not commit local `terraform.tfstate`, `terraform.tfstate.backup`, or real
`.tfvars` files.

## Use Other Environments

For staging:

```bash
terraform init -reconfigure \
  -backend-config=environments/staging/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
terraform plan -var-file=environments/staging/staging.tfvars
```

Expected result: Terraform uses the `staging/terraform.tfstate` key and plans
resources with the staging prefix and tags.

For production:

```bash
terraform init -reconfigure \
  -backend-config=environments/prod/backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT"
terraform plan -var-file=environments/prod/prod.tfvars
```

Expected result: Terraform uses the `prod/terraform.tfstate` key and plans
resources with the production prefix and tags.

Reason: each environment needs both the matching backend file and the matching
`.tfvars` file.

## Safety Check

Before committing, confirm local state and real `.tfvars` files are ignored:

```bash
git status --short
```

Expected result: only intentional documentation and Terraform configuration
changes are shown.

Do not run `terraform apply` or `terraform destroy` unless you intentionally
want to create or remove Azure resources. Destroy learning resources after a
successful apply unless you need them to remain.
