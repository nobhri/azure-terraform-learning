# Phase 5 Plan: Modules

## Goal

Refactor the existing VM and network resources into Terraform modules while
preserving the current Azure architecture.

This phase should change code shape more than infrastructure behavior. The
primary learning goal is how modules separate reusable infrastructure logic
from environment-specific configuration.

## Planned Changes

- Add a reusable network module.
- Add a reusable Linux VM module.
- Convert `dev`, `staging`, and `prod` into Terraform root-module wrappers.
- Move environment-specific backend configuration into each environment
  directory.
- Move environment-specific input values into each environment wrapper.
- Keep the existing Azure resource types and naming model unless a small change
  is required by the refactor.
- Add a Phase 5 guide under `docs/`.
- Update the roadmap and README current focus after Phase 4 is complete.

## Proposed Directory Shape

```text
modules/
  network/
    main.tf
    variables.tf
    outputs.tf
  linux-vm/
    main.tf
    variables.tf
    outputs.tf
environments/
  dev/
    main.tf
    variables.tf
    outputs.tf
    backend.hcl
    terraform.tfvars.example
  staging/
    main.tf
    variables.tf
    outputs.tf
    backend.hcl
    terraform.tfvars.example
  prod/
    main.tf
    variables.tf
    outputs.tf
    backend.hcl
    terraform.tfvars.example
```

Expected result: each environment directory becomes a Terraform root module.

Reason: running Terraform from `environments/dev` makes the selected working
directory imply the selected environment, reducing root-level backend and
var-file pairing mistakes.

## Module Boundary

The network module should own:

- Resource Group, unless a later phase chooses to split it out
- Virtual Network
- Subnet
- Network Security Group
- NSG association
- Public IP, if still needed for SSH
- Network Interface

The Linux VM module should own:

- Linux Virtual Machine
- Admin username
- SSH public key input
- VM size
- OS image settings
- Tags

The VM module should receive the NIC ID from the network module.

Expected result: the dependency still flows from network resources into the VM.

Reason: modules should preserve the Azure dependency model already learned in
Phase 1 instead of hiding it completely.

## Environment Wrapper Shape

Each environment wrapper should call the modules with explicit values:

```hcl
module "network" {
  source = "../../modules/network"

  environment      = "dev"
  location         = var.location
  resource_prefix  = var.resource_prefix
  allowed_ssh_cidr = var.allowed_ssh_cidr
  tags             = var.tags
}

module "linux_vm" {
  source = "../../modules/linux-vm"

  environment              = "dev"
  location                 = var.location
  resource_group_name      = module.network.resource_group_name
  network_interface_id     = module.network.network_interface_id
  admin_username           = var.admin_username
  admin_ssh_public_key     = var.admin_ssh_public_key
  vm_size                  = var.vm_size
  tags                     = var.tags
}
```

Expected result: environment wrappers show the values that differ per
environment and the wiring between modules.

Reason: wrappers should be thin, readable, and explicit enough for learning.

## Backend Commands

After this refactor, local dev commands should run from the environment
directory:

```bash
cd environments/dev

terraform init -reconfigure \
  -backend-config=backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"

terraform validate
terraform plan
```

Expected result: Terraform initializes and plans only the dev wrapper.

Reason: the wrapper directory becomes the root module, so `backend.hcl` and
`terraform.tfvars` are local to the selected environment.

## State Migration Decision

Prefer a controlled migration rather than recreating resources if dev resources
are still present.

Recommended learning path:

1. Start with dev only.
2. Initialize the dev wrapper against the existing dev backend key.
3. Use `terraform state list` to inspect current addresses.
4. Use declarative `moved` blocks to map root resource addresses into module
   resource addresses. Keep `terraform state mv` as a manual fallback.
5. Run `terraform plan` until dev shows no unexpected replacement.
6. Repeat for staging and prod only if they have real resources that must be
   preserved.

Expected result: moving resources into modules changes Terraform addresses
without recreating Azure resources unnecessarily.

Reason: module refactors require state address migration because resource
addresses change from `azurerm_resource_group.main` to names like
`module.network.azurerm_resource_group.main`. A `moved` block keeps that mapping
reviewable in version control.

## Verification

Run formatting:

```bash
terraform fmt -recursive
```

Expected result: Terraform files are formatted across modules and environments.

Reason: the refactor adds nested Terraform directories.

Validate dev:

```bash
cd environments/dev
terraform init -reconfigure \
  -backend-config=backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"
terraform validate
terraform plan
```

Expected result: dev validates and the plan shows either no changes after state
migration or only intentional changes.

Reason: dev is the safest environment for confirming the module refactor.

Validate staging and prod with plan only unless there is a specific reason to
apply them:

```bash
cd environments/staging
terraform init -reconfigure \
  -backend-config=backend.hcl \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="use_azuread_auth=true" \
  -backend-config="use_cli=true"
terraform validate
terraform plan
```

Expected result: staging validates and plans against the staging backend key.

Reason: this checks environment wrapper wiring without creating learning
resources unnecessarily.

## Out Of Scope

- New Azure resource types
- Private endpoints
- Managed identity and RBAC changes
- GitHub Actions plan automation
- GitHub Actions apply automation
- Task runner abstraction
