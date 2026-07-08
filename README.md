# Azure Terraform Learning

This repository documents a step-by-step journey to learn Terraform on Azure.

Each phase introduces only the concepts added since the previous phase. The
goal is not to design the final architecture upfront, but to refactor and
improve the configuration step by step as the Azure and Terraform concepts
become necessary.

## Phases

- Phase 0: Repository Setup
- Phase 1: Azure Minimum Configuration
- Phase 2: Multiple Environments
- Phase 3: Remote Backend and GitHub Actions
- Phase 4: Modules
- Phase 5: Advanced Network Design
- Phase 6: CI/CD Improvements

## Roadmap

This roadmap keeps the learning path incremental and Azure-first while avoiding
Azure-only structure where possible. Environment directories, modules, and CI
boundaries should stay portable enough that an AWS version can later follow the
same shape with provider-specific resources swapped underneath.

### Phase 0: Repository Setup

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

### Phase 1: Azure Minimum Configuration

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

### Phase 2: Multiple Environments

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

### Phase 3: Remote Backend And GitHub Actions

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

### Phase 4: Modules

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

### Phase 5: Advanced Network Design

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

### Phase 6: CI/CD Improvements

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

## Phase 1: Azure Minimum Configuration

This phase creates one Linux VM on Azure with the minimum Terraform structure
needed to run and reach it over SSH.

### What This Adds

- Local Terraform backend
- Azure Resource Group
- Virtual Network and Subnet required by the VM
- Network Security Group allowing SSH only from a trusted CIDR
- Public IP, Network Interface, and one Linux VM

### Why

The goal of Phase 1 is to learn the smallest useful Terraform flow on Azure:

1. Define Azure resources in Terraform.
2. Review the execution plan.
3. Apply the plan to create infrastructure.
4. Destroy the resources after learning.

Password login is disabled and SSH access is limited to a specified source IP range, following Azure security best practices for a public VM.

### Prerequisites

- Terraform installed
- Azure CLI installed
- Azure subscription
- SSH key pair

Log in to Azure:

```bash
az login
az account set --subscription "<subscription-id>"
```

Check your public IP address:

```bash
curl -4 ifconfig.me
```

Check whether you already have an SSH public key:

```bash
ls ~/.ssh/*.pub
```

If no public key exists, create one:

```bash
ssh-keygen -t ed25519 -C "azure-terraform-learning"
```

When prompted for the file path, press Enter to use the default path. For this learning project, an empty passphrase is acceptable if you want to keep the steps simple.

### Usage

Set Terraform variables in your shell instead of creating a `terraform.tfvars` file in this repository:

```bash
export TF_VAR_subscription_id="$(az account show --query id -o tsv)"
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

Check that the variables are set without printing their values:

```bash
test -n "$TF_VAR_subscription_id" && echo "subscription_id OK"
test -n "$TF_VAR_admin_ssh_public_key" && echo "admin_ssh_public_key OK"
test -n "$TF_VAR_allowed_ssh_cidr" && echo "allowed_ssh_cidr OK"
```

This keeps local values out of the repository. `admin_ssh_public_key` is a public key, but `subscription_id` and `allowed_ssh_cidr` are still better kept outside tracked files for this learning project.

Do not paste these values into chat or commit local Terraform state. With the local backend, Terraform writes `terraform.tfstate` in this directory after `apply`; it is ignored by Git, but it can still contain Azure resource IDs and IP addresses.

Initialize Terraform:

```bash
terraform init
```

Format and validate:

```bash
terraform fmt
terraform validate
```

Review the plan:

```bash
terraform plan
```

Create the VM:

```bash
terraform apply
```

Connect to the VM:

```bash
ssh azureuser@$(terraform output -raw public_ip_address)
```

Destroy the resources when finished:

```bash
terraform destroy
```

### Troubleshooting

If this command fails:

```bash
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

With this error:

```text
cat: /Users/<username>/.ssh/id_ed25519.pub: No such file or directory
```

It means the SSH public key does not exist at the default path. Create it:

```bash
ssh-keygen -t ed25519 -C "azure-terraform-learning"
```

Then run the export command again:

```bash
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
```

If `ls ~/.ssh/*.pub` shows a different public key file, use that path instead. For example:

```bash
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

If `terraform apply` fails while creating the Network Security Group with an error like this:

```text
SecurityRuleInvalidAddressPrefix: ... invalid Address prefix. Value provided: 2400:.../32
```

It usually means `TF_VAR_allowed_ssh_cidr` was set from an IPv6 address. This phase uses an IPv4-only VM public IP configuration, so set the SSH source CIDR from your public IPv4 address:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

If that command returns nothing, use another IPv4 lookup endpoint:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -s https://api.ipify.org)/32"
```

Then run `terraform plan` and `terraform apply` again. If the first apply already created some resources before failing, Terraform will continue from the current state.
