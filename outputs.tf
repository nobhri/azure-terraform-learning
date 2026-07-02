output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Name of the created Linux VM."
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Public IP address of the Linux VM."
  value       = azurerm_public_ip.main.ip_address
}
