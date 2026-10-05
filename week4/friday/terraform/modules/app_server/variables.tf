# modules/app_server/variables.tf
#
# This is the module's interface contract. Anyone calling this module
# (the root config, or a future engineer) must provide these values.
# No defaults on anything environment-specific -- a wrong default is
# worse than being forced to supply the value explicitly.

variable "name" {
  description = "Service name: api, payments, or logs. Used in the VM identifier and in output labelling."
  type        = string
}

variable "environment" {
  description = "Deployment environment: staging or production."
  type        = string
  default     = "staging"
}

variable "ssh_user" {
  description = "SSH username used to connect to the Multipass VM."
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key used to connect to the Multipass VM."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "multipass_vm_name" {
  description = "The exact Multipass instance name for this server (e.g. kijanikiosk-api)."
  type        = string
}
