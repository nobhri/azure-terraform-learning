output "resource_group_name" {
  description = "Name of the dev resource group."
  value       = module.network.resource_group_name
}

output "vm_name" {
  description = "Name of the dev Linux VM."
  value       = module.linux_vm.vm_name
}

output "public_ip_address" {
  description = "Public IP address of the dev Linux VM."
  value       = module.network.public_ip_address
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity attached to the dev VM."
  value       = azurerm_user_assigned_identity.vm_workload.client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID used for the managed identity RBAC assignment."
  value       = azurerm_user_assigned_identity.vm_workload.principal_id
}

output "workload_storage_account_name" {
  description = "Name of the workload Storage Account used for identity and RBAC experiments."
  value       = azurerm_storage_account.workload.name
}

output "workload_storage_container_name" {
  description = "Name of the private Blob Container used for identity and RBAC experiments."
  value       = azurerm_storage_container.workload.name
}
