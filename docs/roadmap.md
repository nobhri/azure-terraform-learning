# Terraform Learning Roadmap

This roadmap keeps the learning path incremental and Azure-first while avoiding
Azure-only structure where possible. Environment directories, modules, and CI
boundaries should stay portable enough that an AWS version can later follow the
same shape with provider-specific resources swapped underneath.

## Phase 0: Repository Setup

Create the repository foundation before adding infrastructure.

What this adds:

- GitHub repository
- README
- `.gitignore`
- Branch protection
- Initial commit

Why this phase is needed:

Terraform work should start from a safe Git workflow because infrastructure
changes are easier to review when each phase is small and traceable. Branch
protection also sets the habit that infrastructure changes should go through
review instead of being pushed directly to `main`.

## Phase 1: Azure Minimum Configuration

Create the smallest useful Azure Linux VM configuration with Terraform.

What this adds:

- Resource Group
- Virtual Network
- Subnet
- Network Interface
- Public IP, if SSH access from the internet is needed
- Network Security Group
- Linux Virtual Machine

Concepts learned:

- Provider
- Resource
- Variable
- Output
- Local backend
- `terraform plan`
- `terraform apply`
- `terraform destroy`
- `terraform state`

Why this phase is needed:

Azure does not create a Linux VM as a standalone object. A VM needs a NIC, the
NIC needs a subnet, and the subnet needs a virtual network. NSG and Public IP
resources are added only to make SSH access explicit and controlled. This phase
therefore teaches the real minimum dependency graph for an Azure VM while still
keeping all Terraform state local and easy to inspect.

## Phase 2: Multiple Environments

Split the working Phase 1 configuration into separate environments.

What this adds:

- `dev`
- `staging`
- `prod`
- `.tfvars` usage
- Environment-specific local state
- Environment directory structure

Why this phase is needed:

Most infrastructure code must represent more than one environment. This phase
adds only environment separation while keeping the backend local, so the new
lesson is how variables, directory layout, and state boundaries prevent `dev`,
`staging`, and `prod` from accidentally sharing the same resources.

## Phase 3: Remote Backend And GitHub Actions

Move state from local files to Azure Blob Storage and introduce GitHub Actions.

What this adds:

- Azure Blob Storage remote backend
- Remote state
- GitHub Actions
- OIDC authentication from GitHub to Azure

Why this phase is needed:

Local state is useful for learning, but team workflows need shared state,
locking, and a repeatable execution path. Azure Blob Storage becomes the remote
backend, and GitHub Actions becomes the place where Terraform runs. From this
phase onward, `terraform apply` should be performed through GitHub Actions
only; local Terraform use should focus on formatting, validation, and reviewing
plans when appropriate.

## Phase 4: Modules

Refactor VM and network code into modules after the non-module version is
understood.

What this adds:

- Module
- Input variable
- Output
- Module design
- Environment wrappers that call modules

Why this phase is needed:

Modules are easier to design after the direct resources are already working.
This phase keeps the Azure resources mostly the same and changes the code shape:
environment directories become thin wrappers, while reusable VM and network
logic moves into modules. This mirrors Terraform best practice by separating
environment configuration from reusable infrastructure building blocks without
introducing that abstraction too early.

## Phase 5: Advanced Network Design

Extend the minimal Phase 1 network into explicit Azure network design.

What this may add:

- Route Table
- NAT Gateway
- Bastion
- Private Endpoint
- Private DNS
- NSG design

Why this phase is needed:

Phase 1 includes networking only because a VM cannot run without it and SSH
needs controlled access. This phase changes the goal: the focus is no longer
"networking required to run a VM", but "networking as an Azure architecture
topic". Route control, private access, DNS, egress, and NSG rule design can be
added one at a time without mixing them into the initial VM lesson.

## Phase 6: CI/CD Improvements

Improve the GitHub Actions workflow after remote backend and module boundaries
exist.

What this may add:

- `terraform fmt`
- `terraform validate`
- `terraform plan`
- `terraform apply`
- GitHub Environments
- Environment protection
- Approvals

Why this phase is needed:

Once applies run through GitHub Actions, the workflow itself becomes part of the
infrastructure system. This phase adds quality gates and approval boundaries so
formatting, validation, planning, and applying happen consistently across
environments. Keeping this after modules and remote state makes the CI/CD
improvements easier to reason about and closer to a production Terraform
workflow.
