output "resource_group_name" {
  description = "Name of the resource group owned by the network module."
  value       = azurerm_resource_group.main.name
}

output "network_interface_id" {
  description = "ID of the network interface attached to the Linux VM."
  value       = azurerm_network_interface.main.id
}

output "public_ip_address" {
  description = "Public IP address assigned to the network interface."
  value       = azurerm_public_ip.main.ip_address
}
