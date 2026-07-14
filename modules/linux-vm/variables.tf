variable "resource_prefix" {
  description = "Prefix used for the Linux VM name."
  type        = string
}

variable "location" {
  description = "Azure region where the Linux VM is created."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group that contains the Linux VM."
  type        = string
}

variable "network_interface_id" {
  description = "ID of the network interface attached to the Linux VM."
  type        = string
}

variable "identity_ids" {
  description = "IDs of user-assigned managed identities attached to the Linux VM."
  type        = list(string)
  default     = []
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "Public SSH key used to sign in to the Linux VM."
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
}

variable "tags" {
  description = "Common tags applied to the Linux VM."
  type        = map(string)
}
