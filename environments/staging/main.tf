terraform {
  required_version = ">= 1.6.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {}
}

module "network" {
  source = "../../modules/network"

  resource_prefix  = var.project_name
  location         = var.location
  allowed_ssh_cidr = var.allowed_ssh_cidr
  tags             = var.tags
}

module "linux_vm" {
  source = "../../modules/linux-vm"

  resource_prefix      = var.project_name
  location             = var.location
  resource_group_name  = module.network.resource_group_name
  network_interface_id = module.network.network_interface_id
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key
  vm_size              = var.vm_size
  tags                 = var.tags
}
