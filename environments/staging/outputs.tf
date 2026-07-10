output "resource_group_name" {
  description = "Name of the staging resource group."
  value       = module.network.resource_group_name
}

output "vm_name" {
  description = "Name of the staging Linux VM."
  value       = module.linux_vm.vm_name
}

output "public_ip_address" {
  description = "Public IP address of the staging Linux VM."
  value       = module.network.public_ip_address
}
