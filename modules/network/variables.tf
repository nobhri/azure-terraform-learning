variable "resource_prefix" {
  description = "Prefix used for network resource names."
  type        = string
}

variable "location" {
  description = "Azure region where network resources are created."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "IPv4 CIDR range allowed to connect to SSH."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr must be a valid IPv4 CIDR block, for example 203.0.113.10/32."
  }
}

variable "tags" {
  description = "Common tags applied to network resources."
  type        = map(string)
}
