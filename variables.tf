variable "subscription_id" {
  description = "Azure subscription ID where the resources will be created."
  type        = string
}

variable "project_name" {
  description = "Prefix used for Azure resource names."
  type        = string
  default     = "terraform-learning"
}

variable "location" {
  description = "Azure region where the resources will be created."
  type        = string
  default     = "japaneast"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Public SSH key used to sign in to the Linux VM."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "IPv4 CIDR range allowed to connect to SSH. Use your public IPv4 address with /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr must be a valid IPv4 CIDR block, for example 203.0.113.10/32."
  }
}

variable "tags" {
  description = "Common tags applied to Azure resources."
  type        = map(string)
  default = {
    environment = "learning"
    managed_by  = "terraform"
    phase       = "1"
  }
}
