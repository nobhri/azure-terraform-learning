resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.resource_prefix}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [var.network_interface_id]

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 ? [var.identity_ids] : []

    content {
      type         = "UserAssigned"
      identity_ids = identity.value
    }
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}
