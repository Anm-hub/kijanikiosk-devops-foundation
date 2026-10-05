# modules/app_server/outputs.tf
#
# What the root module (and later pipeline.sh) can read from this module.

output "public_ip" {
  description = "The Multipass VM's IPv4 address, resolved dynamically via the external data source."
  value       = data.external.vm_ip.result.ip
}

output "ssh_command" {
  description = "Ready-to-use SSH command for this server."
  value       = "ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${data.external.vm_ip.result.ip}"
}

output "name" {
  description = "The service name this instance represents (api, payments, or logs)."
  value       = var.name
}
