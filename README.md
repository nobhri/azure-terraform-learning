# Azure Terraform Learning

This repository documents a step-by-step journey to learn Terraform on Azure.

Each phase introduces a single new concept while keeping changes minimal.

## Phases

- Phase 0: Repository Setup
- Phase 1: Single VM
- Phase 2: Multi Environment
- Phase 3: Remote Backend & CI/CD
- Phase 4: Network
- Phase 5: Modules
- Phase 6: GitHub Actions

## Phase 1: Single Linux VM

This phase creates one Linux VM on Azure with the minimum Terraform structure.

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
