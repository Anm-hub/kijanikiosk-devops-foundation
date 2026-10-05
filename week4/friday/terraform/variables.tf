# variables.tf (root module)

variable "environment" {
  description = "Deployment environment: staging or production."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

variable "ssh_user" {
  description = "SSH username used to connect to each Multipass VM."
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key used by Terraform and later by Ansible to connect to each VM. Must match the key pushed to each VM's authorized_keys."
  type        = string
  default     = "~/.ssh/id_rsa"
}
