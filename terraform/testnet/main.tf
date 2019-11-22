resource "packet_device" "lotus_bootstrap_yyz" {
  count               = 2
  hostname            = "lotus-bootstrap-${count.index}"
  plan                = "x1.small.x86"
  facilities          = ["yyz1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = "${var.project_id}"
  project_ssh_key_ids = "${values(local.ssh_keys)}"
}

resource "packet_device" "lotus_bootstrap_hkg" {
  count               = 2
  hostname            = "lotus-bootstrap-${count.index}"
  plan                = "x1.small.x86"
  facilities          = ["hkg1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = "${var.project_id}"
  project_ssh_key_ids = "${values(local.ssh_keys)}"
}

resource "null_resource" "lotus_bootstrap_yyz" {
  count      = 2
  depends_on = ["packet_device.lotus_bootstrap_yyz"]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_bootstrap.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${packet_device.lotus_bootstrap_yyz[count.index].access_public_ipv4}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_copy_binary = true
      }

      # shared attributes
      enabled  = true
      vault_id = ["/home/ognots/.ansible_vault_pass.txt"]
      groups   = ["bootstrap"]
    }
  }
}

resource "null_resource" "lotus_bootstrap_hkg" {
  count      = 2
  depends_on = ["packet_device.lotus_bootstrap_hkg"]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_bootstrap.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${packet_device.lotus_bootstrap_hkg[count.index].access_public_ipv4}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_copy_binary = true
      }

      # shared attributes
      enabled  = true
      vault_id = ["/home/ognots/.ansible_vault_pass.txt"]
      groups   = ["bootstrap"]
    }
  }
}

locals {
  ssh_keys = {
    ognots       = "e0eb55a6-b2e7-48f8-9bd9-a7c5987332dc"
    travisperson = "e9febf12-1da7-43b3-b326-3f84a3ad47fa"
  }
}
