output "resource_group_name" {
  description = "Name of the prod resource group."
  value       = module.network.resource_group_name
}

output "vm_name" {
  description = "Name of the prod Linux VM."
  value       = module.linux_vm.vm_name
}

output "public_ip_address" {
  description = "Public IP address of the prod Linux VM."
  value       = module.network.public_ip_address
}
