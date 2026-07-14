resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  storage_account_prefix = substr(replace(lower(var.project_name), "-", ""), 0, 15)
  phase_6_tags           = merge(var.tags, { phase = "6" })
}

resource "azurerm_user_assigned_identity" "vm_workload" {
  name                = "${var.project_name}-uami"
  location            = var.location
  resource_group_name = module.network.resource_group_name

  tags = local.phase_6_tags
}

resource "azurerm_storage_account" "workload" {
  name                     = "${local.storage_account_prefix}${random_string.storage_suffix.result}"
  resource_group_name      = module.network.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.phase_6_tags
}

resource "azurerm_storage_container" "workload" {
  name                  = "identity-rbac"
  storage_account_id    = azurerm_storage_account.workload.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "workload_blob_reader" {
  scope                = azurerm_storage_container.workload.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.vm_workload.principal_id
  principal_type       = "ServicePrincipal"
}
