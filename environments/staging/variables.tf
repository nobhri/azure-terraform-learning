variable "subscription_id" {
  description = "Azure subscription ID where the staging resources are created."
  type        = string
}

variable "project_name" {
  description = "Prefix used for staging Azure resource names."
  type        = string
  default     = "terraform-learning-staging"
}

variable "location" {
  description = "Azure region where the staging resources are created."
  type        = string
  default     = "japaneast"
}

variable "vm_size" {
  description = "Azure VM size for staging."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the staging Linux VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Public SSH key used to sign in to the staging Linux VM."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "IPv4 CIDR range allowed to connect to SSH in staging."
  type        = string
}

variable "tags" {
  description = "Common tags applied to staging resources."
  type        = map(string)
  default = {
    environment = "staging"
    managed_by  = "terraform"
    phase       = "2"
  }
}
