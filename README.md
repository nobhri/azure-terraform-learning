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
curl ifconfig.me
```

### Usage

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
subscription_id      = "<subscription-id>"
admin_ssh_public_key = "ssh-ed25519 AAAA... your-key-comment"
allowed_ssh_cidr     = "<your-public-ip>/32"
```

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
