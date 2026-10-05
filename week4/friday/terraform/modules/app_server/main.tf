# modules/app_server/main.tf
#
# Requirement 1: capture the Multipass VM's IP dynamically rather than
# hardcoding it. `multipass info --format json` is queried live, at
# apply time, via the external data source -- the IP is never typed
# into a .tf file by hand.

data "external" "vm_ip" {
  program = [
    "bash", "-c",
    "multipass info ${var.multipass_vm_name} --format json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({\"ip\": d[\"info\"][\"${var.multipass_vm_name}\"][\"ipv4\"][0]}))'"
  ]
}

# A null_resource has no cloud equivalent to "create" -- the Multipass
# VM already exists (we launched it directly with `multipass launch`).
# This resource's job is to prove Terraform can reach it over SSH and
# to give the VM an address in Terraform's state, which is what makes
# `terraform output` able to hand a real IP to Ansible later.
resource "null_resource" "server" {
  triggers = {
    vm_ip = data.external.vm_ip.result.ip
    name  = var.name
  }

  connection {
    type        = "ssh"
    host        = data.external.vm_ip.result.ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "30s"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Terraform connected to kijanikiosk-${var.name} (${var.environment})'",
      "hostname",
      "uname -a"
    ]
  }
}
