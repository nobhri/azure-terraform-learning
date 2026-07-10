# 2026-07-10 Session Retrospective: Phase 5 Modules

## Goal

Start Phase 5 by refactoring the existing Azure network and Linux VM resources
into reusable Terraform modules without changing the Azure architecture.

## What Changed

- Added a network module that owns the Resource Group, VNet, subnet, NSG,
  Public IP, and NIC.
- Added a Linux VM module that receives the Resource Group name and NIC ID from
  the network module.
- Converted `dev`, `staging`, and `prod` into independent Terraform root
  modules.
- Moved backend configuration and provider lock files into each environment.
- Added declarative `moved` blocks for the old root resource addresses.
- Renamed each committed variable example to `terraform.tfvars.example` so a
  copied local file is loaded automatically from its environment directory.
- Updated GitHub Actions to initialize and validate from `environments/dev`.
- Added the Phase 5 guide and updated the current focus in the README.

## Important Learning

Running Terraform from `environments/dev` does not hide the shared modules.
The relative source `../../modules/network` is resolved from the environment
root module and points back to the repository-level `modules` directory.

The first local backend initialization failed with a URL beginning with:

```text
https://.blob.core.windows.net/
```

The empty hostname showed that `TFSTATE_STORAGE_ACCOUNT` was unset. Restoring
that shell variable fixed backend initialization; the module path was not the
cause.

Declarative `moved` blocks make the address migration reviewable in code. A
successful plan should show existing resources moving from addresses such as
`azurerm_resource_group.main` to
`module.network.azurerm_resource_group.main`, without unexpected replacement.

## Validation Completed

- `terraform fmt -check -recursive`
- `terraform -chdir=environments/dev validate`
- `git diff --check`
- Local dev `terraform init -reconfigure` completed successfully.
- Local dev `terraform plan` completed successfully.

No `terraform apply` or `terraform destroy` was run.

## Follow-Up

- Review the complete Phase 5 diff and dev plan details.
- Confirm the plan contains no unexpected create, replace, or destroy actions.
- Validate staging and prod only when work begins in those environments.
- Destroy learning resources when they are no longer needed.
