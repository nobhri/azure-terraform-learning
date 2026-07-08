# Phase 1: Azure Minimum Configuration

This phase creates one Linux VM on Azure with the minimum Terraform structure
needed to run and reach it over SSH.

Source snapshot:

- [phase-1-complete](https://github.com/nobhri/azure-terraform-learning/tree/phase-1-complete)

## What This Adds

- Local Terraform backend
- Azure Resource Group
- Virtual Network and Subnet required by the VM
- Network Security Group allowing SSH only from a trusted CIDR
- Public IP, Network Interface, and one Linux VM

## Why

The goal of Phase 1 is to learn the smallest useful Terraform flow on Azure:

1. Define Azure resources in Terraform.
2. Review the execution plan.
3. Apply the plan to create infrastructure.
4. Destroy the resources after learning.

Password login is disabled and SSH access is limited to a specified source IP
range, following Azure security best practices for a public VM.

## Prerequisites

- Terraform installed
- Azure CLI installed
- Azure subscription
- SSH key pair

Log in to Azure:

```bash
az login
az account set --subscription "<subscription-id>"
```

Expected result: Azure CLI is authenticated and set to the subscription used for
this learning project.

Check your public IP address:

```bash
curl -4 ifconfig.me
```

Expected result: a single IPv4 address. This is used to limit SSH access to your
current network.

Check whether you already have an SSH public key:

```bash
ls ~/.ssh/*.pub
```

If no public key exists, create one:

```bash
ssh-keygen -t ed25519 -C "azure-terraform-learning"
```

Expected result: an SSH public key file such as `~/.ssh/id_ed25519.pub`.

## Usage

Set Terraform variables in your shell instead of creating a `terraform.tfvars`
file in this repository:

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

Expected result: each command prints `OK`. This keeps local values out of the
repository.

Initialize Terraform:

```bash
terraform init
```

Expected result: Terraform installs the Azure provider and prepares the local
working directory.

Format and validate:

```bash
terraform fmt
terraform validate
```

Expected result: formatting completes and validation reports that the
configuration is valid.

Review the plan:

```bash
terraform plan
```

Expected result: Terraform shows the Azure resources it will create before any
changes are made.

Create the VM:

```bash
terraform apply
```

Expected result: Terraform creates the Resource Group, network resources, NSG,
Public IP, NIC, and Linux VM.

Connect to the VM:

```bash
ssh azureuser@$(terraform output -raw public_ip_address)
```

Expected result: SSH connects to the Linux VM using the configured public key.

Destroy the resources when finished:

```bash
terraform destroy
```

Expected result: Terraform removes the learning resources to avoid ongoing
Azure cost.

## Troubleshooting

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

If `ls ~/.ssh/*.pub` shows a different public key file, use that path instead.
For example:

```bash
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

If `terraform apply` fails while creating the Network Security Group with an
error like this:

```text
SecurityRuleInvalidAddressPrefix: ... invalid Address prefix. Value provided: 2400:.../32
```

It usually means `TF_VAR_allowed_ssh_cidr` was set from an IPv6 address. This
phase uses an IPv4-only VM public IP configuration, so set the SSH source CIDR
from your public IPv4 address:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -4 -s ifconfig.me)/32"
```

If that command returns nothing, use another IPv4 lookup endpoint:

```bash
export TF_VAR_allowed_ssh_cidr="$(curl -s https://api.ipify.org)/32"
```

Then run `terraform plan` and `terraform apply` again. If the first apply
already created some resources before failing, Terraform will continue from the
current state.
