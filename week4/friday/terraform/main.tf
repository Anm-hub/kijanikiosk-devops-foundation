# main.tf (root module)
#
# Requirement 1: remote backend with state locking "enabled" where the
# backend supports it. MinIO (S3-compatible) does NOT provide native
# locking -- documented as a known limitation in hardening-decisions.md,
# per the brief's own instruction. This is a deliberate, acknowledged
# trade-off for the local/no-cloud-account path, not an oversight.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  backend "s3" {
    bucket = "kijanikiosk-tfstate"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
    endpoints = {
      s3 = "http://localhost:9000"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

# Requirement 1: Use the app_server module via for_each across three
# server definitions (api, payments, logs). No hardcoded values in this
# block -- every value either comes from a variable or from local.servers.
locals {
  servers = {
    api = {
      multipass_vm_name = "kijanikiosk-api"
    }
    payments = {
      multipass_vm_name = "kijanikiosk-payments"
    }
    logs = {
      multipass_vm_name = "kijanikiosk-logs"
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name                 = each.key
  multipass_vm_name    = each.value.multipass_vm_name
  environment          = var.environment
  ssh_user             = var.ssh_user
  ssh_private_key_path = var.ssh_private_key_path
}
