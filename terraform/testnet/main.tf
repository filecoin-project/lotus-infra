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
        "${aws_route53_record.yyz[count.index].fqdn}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_copy_binary = var.lotus_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
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
        "${aws_route53_record.hkg[count.index].fqdn}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_copy_binary = var.lotus_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["bootstrap"]
    }
  }
}

resource "packet_device" "lotus_genesis" {
  hostname            = "lotus-genesis"
  plan                = "x1.small.x86"
  facilities          = ["hkg1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = "${var.project_id}"
  project_ssh_key_ids = "${values(local.ssh_keys)}"
}

resource "null_resource" "lotus_genesis" {
  depends_on = ["packet_device.lotus_genesis"]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_genesis.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${packet_device.lotus_genesis.access_public_ipv4}",
      ]

      playbook {
        file_path = "../../ansible/lotus_genesis.yml"
      }

      extra_vars = {
        lotus_copy_binary          = var.lotus_copy_binary
        lotus_miner_copy_binary    = var.lotus_miner_copy_binary
        lotus_fountain_copy_binary = var.lotus_fountain_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["genesis"]
    }
  }
}

locals {
  ssh_keys = {
    ognots       = "e0eb55a6-b2e7-48f8-9bd9-a7c5987332dc"
    travisperson = "e9febf12-1da7-43b3-b326-3f84a3ad47fa"
    bastion      = "0241a4c6-a515-4969-aac7-e0335993c941"
  }
}

data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}

resource "aws_route53_record" "hkg" {
  count   = 2
  name    = "bootstrap-${count.index}.hkg"
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_hkg[count.index].access_public_ipv4}"]
  ttl     = 30
}

resource "aws_route53_record" "yyz" {
  count   = 2
  name    = "bootstrap-${count.index}.yyz"
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_yyz[count.index].access_public_ipv4}"]
  ttl     = 30
}
