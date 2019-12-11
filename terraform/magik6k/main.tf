resource "packet_device" "magik6k" {
  count               = 3
  hostname            = "magik6k-${count.index}"
  plan                = "c2.medium.x86"
  facilities          = ["dfw2"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
}

locals {
  ssh_keys = {
    kubuxu   = "2c7b5374-2cd9-4206-9f9d-ca0d443e77f4"
    magik6k  = "d8f6e481-3204-4bd7-8922-81a33a46d28e"
    magik6k2 = "cbf19736-a4ca-4cd1-8982-6404869edb91"
    magik6k3 = "b6d323cd-773b-4e63-8098-405e9ba5cf9e"
    ognots   = "e0eb55a6-b2e7-48f8-9bd9-a7c5987332dc"
  }
}


resource "null_resource" "magik6k" {
  count      = 3
  depends_on = [packet_device.magik6k]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_base.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${packet_device.magik6k[count.index].access_public_ipv4}",
      ]

      playbook {
        file_path = "../../ansible/lotus_base.yml"
      }

      extra_vars = {
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["base"]
    }
  }
}
