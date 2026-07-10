variable "subscription_id" {
  description = "Azure subscription ID where the dev resources are created."
  type        = string
}

variable "project_name" {
  description = "Prefix used for dev Azure resource names."
  type        = string
  default     = "terraform-learning-dev"
}

variable "location" {
  description = "Azure region where the dev resources are created."
  type        = string
  default     = "japaneast"
}

variable "vm_size" {
  description = "Azure VM size for dev."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the dev Linux VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Public SSH key used to sign in to the dev Linux VM."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "IPv4 CIDR range allowed to connect to SSH in dev."
  type        = string
}

variable "tags" {
  description = "Common tags applied to dev resources."
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
    phase       = "2"
  }
}
