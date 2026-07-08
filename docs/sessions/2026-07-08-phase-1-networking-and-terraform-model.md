# Session 2026-07-08: Phase 1 Networking And Terraform Model

## Goal

Review the Phase 1 Azure VM Terraform configuration and clarify how Azure networking resources, Terraform state, and CLI inspection fit together before starting Phase 2.

## What We Reviewed

- Azure VM cannot be deployed as a standalone compute object. It needs at least one Network Interface Card.
- A NIC must be placed in a subnet, and a subnet must belong to a virtual network.
- The Phase 1 dependency shape is:

```text
VNet
  -> Subnet
      -> NIC
          -> VM
```

- Public IP and NSG are not what make the VM exist, but they are needed for controlled SSH access from the internet.
- Azure Portal appears to create "just a VM", but it creates or selects the required NIC, VNet, subnet, NSG, public IP, and disk resources behind the scenes.
- Databricks managed resource groups follow a similar idea: managed services still need underlying network and compute resources, but the service creates and manages many of them.
- `location = azurerm_resource_group.main.location` is a readability and consistency choice. It makes related resources follow the resource group's configured region.
- Terraform resource order in the file is mainly for humans. Terraform decides creation order from references and the resulting dependency graph.

## NSG And Connectivity Notes

- The explicit NSG rule allows inbound TCP port 22 from `var.allowed_ssh_cidr`.
- This is intended to allow SSH only from the trusted laptop public IP range.
- No explicit outbound rule is defined, but Azure NSGs include default outbound allow rules.
- Because of that default outbound behavior, commands like `apt`, `pip`, and `curl` should generally work unless another routing, DNS, OS, or Azure setting blocks them.

Useful outbound checks from the VM:

```bash
nslookup www.microsoft.com
curl -I https://archive.ubuntu.com
curl -I https://pypi.org
```

## Terraform Output Notes

- `public_ip_address` is useful for SSH.
- `resource_group_name` and `vm_name` are useful for Azure CLI inspection and VM operations.
- Terraform output can bridge Terraform-managed values into `az` and `ssh` commands.

Example:

```bash
az vm show \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw vm_name)
```

## IP Address Model

- VNet CIDR is the large private address range, such as `10.0.0.0/16`.
- Subnet CIDR is a smaller private range inside the VNet, such as `10.0.1.0/24`.
- The VM's private IP is assigned to the NIC from the subnet range.
- The public IP is a single address allocated from Azure's public IP pool, not from the VNet CIDR.
- The public IP is associated with the NIC's IP configuration, so internet traffic reaches the VM through the NIC.

## Experiments Already Done

- Read Terraform state to inspect managed resources.
- Changed Azure resources manually in the Portal, then ran `terraform plan` to observe drift.

## Recommended Before Phase 2

- Run `terraform graph` to visualize the dependency graph.
- Use Azure CLI to inspect the resources Terraform created:

```bash
az resource list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table

az network nic list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table

az network public-ip list \
  --resource-group $(terraform output -raw resource_group_name) \
  --output table
```

- Try one or two safe drift experiments with `terraform plan`, such as changing tags or VM size in the Azure Portal, then letting Terraform show the difference.
- Avoid running `terraform apply` or `terraform destroy` unless the intended resource change is clear.

## What I Learned

- Azure VM networking is built around NICs, and NICs anchor VMs into subnets and VNets.
- Public IP is not the VM's private address. It is a separate Azure resource associated with the NIC.
- NSG inbound and outbound behavior should be considered separately.
- Terraform is best understood as desired-state management, not just a script that creates resources once.
- `terraform output` is useful for passing Terraform-managed names and addresses to operational tools like Azure CLI and SSH.

## Next Step

Start Phase 2 from the current Terraform architecture, keeping changes incremental and using `terraform fmt`, `terraform validate`, and `terraform plan` as the validation flow.
