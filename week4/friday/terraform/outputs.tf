# outputs.tf (root module)
#
# Requirement 1: output all three server public IPs and SSH commands in
# a format pipeline.sh can extract directly. Each server gets its own
# named output (api_server_ip, payments_server_ip, logs_server_ip)
# rather than a single map, so `terraform output -raw <name>` works
# without any JSON parsing in the pipeline script.

output "api_server_ip" {
  description = "Public (local-network) IP address of the kk-api Multipass VM."
  value       = module.app_servers["api"].public_ip
}

output "payments_server_ip" {
  description = "Public (local-network) IP address of the kk-payments Multipass VM."
  value       = module.app_servers["payments"].public_ip
}

output "logs_server_ip" {
  description = "Public (local-network) IP address of the kk-logs Multipass VM."
  value       = module.app_servers["logs"].public_ip
}

output "api_ssh_command" {
  description = "Ready-to-use SSH command for the kk-api server."
  value       = module.app_servers["api"].ssh_command
}

output "payments_ssh_command" {
  description = "Ready-to-use SSH command for the kk-payments server."
  value       = module.app_servers["payments"].ssh_command
}

output "logs_ssh_command" {
  description = "Ready-to-use SSH command for the kk-logs server."
  value       = module.app_servers["logs"].ssh_command
}
