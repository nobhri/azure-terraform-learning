variable "subscription_id" {
  description = "Azure subscription ID where the prod resources are created."
  type        = string
}

variable "project_name" {
  description = "Prefix used for prod Azure resource names."
  type        = string
  default     = "terraform-learning-prod"
}

variable "location" {
  description = "Azure region where the prod resources are created."
  type        = string
  default     = "japaneast"
}

variable "vm_size" {
  description = "Azure VM size for prod."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the prod Linux VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Public SSH key used to sign in to the prod Linux VM."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "IPv4 CIDR range allowed to connect to SSH in prod."
  type        = string
}

variable "tags" {
  description = "Common tags applied to prod resources."
  type        = map(string)
  default = {
    environment = "prod"
    managed_by  = "terraform"
    phase       = "2"
  }
}
