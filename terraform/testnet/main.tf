resource "packet_device" "lotus_bootstrap_yyz" {
  count               = 2
  hostname            = "lotus-bootstrap-${count.index}.yyz"
  plan                = "x1.small.x86"
  facilities          = ["yyz1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
}

resource "packet_device" "lotus_bootstrap_hkg" {
  count               = 2
  hostname            = "lotus-bootstrap-${count.index}.hkg"
  plan                = "x1.small.x86"
  facilities          = ["hkg1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
}

resource "null_resource" "lotus_bootstrap_yyz" {
  count      = 2
  depends_on = [packet_device.lotus_bootstrap_yyz]

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
        lotus_reset       = var.lotus_reset
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
  depends_on = [packet_device.lotus_bootstrap_hkg]

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
        lotus_reset       = var.lotus_reset
        lotus_copy_binary = var.lotus_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["bootstrap"]
    }
  }
}

resource "packet_device" "lotus_fountain" {
  hostname            = "lotus-fountain"
  plan                = "x1.small.x86"
  facilities          = ["yyz1"]
  operating_system    = "ubuntu_18_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
}

resource "null_resource" "lotus_fountain" {
  depends_on = [packet_device.lotus_fountain, dnsimple_record.faucet, aws_route53_record.fountain]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_fountain.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.fountain.fqdn}",
      ]

      playbook {
        file_path = "../../ansible/lotus_fountain.yml"
      }

      extra_vars = {
        lotus_reset                = var.lotus_reset
        lotus_copy_binary          = var.lotus_copy_binary
        lotus_fountain_copy_binary = var.lotus_fountain_copy_binary
        lotus_fountain_server_name = "${dnsimple_record.faucet.hostname}"
        certbot_create_certificate = var.certbot_create_certificate
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["fountain"]
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
  name    = "lotus-bootstrap-${count.index}.hkg"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_hkg[count.index].access_public_ipv4}"]
  ttl     = 30
}

resource "aws_route53_record" "yyz" {
  count   = 2
  name    = "lotus-bootstrap-${count.index}.yyz"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_yyz[count.index].access_public_ipv4}"]
  ttl     = 30
}

resource "aws_route53_record" "fountain" {
  name    = "lotus-fountain.yyz"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_fountain.access_public_ipv4}"]
  ttl     = 30
}

resource "dnsimple_record" "faucet" {
  domain = var.testnet_domain
  name   = "faucet"
  value  = packet_device.lotus_fountain.access_public_ipv4
  type   = "A"
  ttl    = 300
}
