resource "packet_device" "lotus_bootstrap_dfw" {
  count                            = 2
  hostname                         = "lotus-bootstrap-${count.index}.dfw"
  plan                             = "x1.small.x86"
  facilities                       = ["dfw2"]
  operating_system                 = "ubuntu_19_04"
  billing_cycle                    = "hourly"
  project_id                       = var.project_id
  project_ssh_key_ids              = values(local.ssh_keys)
  hardware_reservation_id          = "next-available"
  wait_for_reservation_deprovision = true
}

resource "packet_device" "lotus_bootstrap_fra" {
  count                            = 2
  hostname                         = "lotus-bootstrap-${count.index}.fra"
  plan                             = "x1.small.x86"
  facilities                       = ["fra2"]
  operating_system                 = "ubuntu_19_04"
  billing_cycle                    = "hourly"
  project_id                       = var.project_id
  project_ssh_key_ids              = values(local.ssh_keys)
  hardware_reservation_id          = "next-available"
  wait_for_reservation_deprovision = true
}

resource "packet_device" "lotus_bootstrap_sin" {
  count                            = 2
  hostname                         = "lotus-bootstrap-${count.index}.sin"
  plan                             = "x1.small.x86"
  facilities                       = ["sin3"]
  operating_system                 = "ubuntu_19_04"
  billing_cycle                    = "hourly"
  project_id                       = var.project_id
  project_ssh_key_ids              = values(local.ssh_keys)
  hardware_reservation_id          = "next-available"
  wait_for_reservation_deprovision = true
}

resource "null_resource" "lotus_bootstrap_dfw" {
  count      = 2
  depends_on = [packet_device.lotus_bootstrap_dfw]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_bootstrap.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.dfw[count.index].fqdn}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_reset            = var.lotus_reset
        lotus_daemon_bootstrap = "true"
        lotus_copy_binary      = var.lotus_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["bootstrap"]
    }
  }
}

resource "null_resource" "lotus_bootstrap_fra" {
  count      = 2
  depends_on = [packet_device.lotus_bootstrap_fra]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_bootstrap.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.fra[count.index].fqdn}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_reset            = var.lotus_reset
        lotus_daemon_bootstrap = "true"
        lotus_copy_binary      = var.lotus_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["bootstrap"]
    }
  }
}

resource "null_resource" "lotus_bootstrap_sin" {
  count      = 2
  depends_on = [packet_device.lotus_bootstrap_sin]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_bootstrap.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.sin[count.index].fqdn}",
      ]

      playbook {
        file_path = "../../ansible/lotus_bootstrap.yml"
      }

      extra_vars = {
        lotus_reset            = var.lotus_reset
        lotus_daemon_bootstrap = "true"
        lotus_copy_binary      = var.lotus_copy_binary
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
  operating_system    = "ubuntu_19_04"
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
        lotus_daemon_bootstrap     = "true"
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

resource "packet_device" "stats" {
  hostname            = "stats"
  plan                = "x1.small.x86"
  facilities          = ["sea1"]
  operating_system    = "ubuntu_19_04"
  billing_cycle       = "hourly"
  project_id          = var.project_id
  project_ssh_key_ids = values(local.ssh_keys)
}

resource "null_resource" "stats" {
  depends_on = [packet_device.stats]

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/stats.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.stats.fqdn}",
      ]

      playbook {
        file_path = "../../ansible/stats.yml"
      }

      extra_vars = {
        lotus_reset            = var.lotus_reset
        lotus_daemon_bootstrap = "true"
        lotus_copy_binary      = var.lotus_copy_binary
        stats_copy_binary      = var.stats_copy_binary
      }

      # shared attributes
      enabled  = true
      vault_id = [".vault_password"]
      groups   = ["stats"]
    }
  }
}


locals {
  ssh_keys = {
    ognots       = "e0eb55a6-b2e7-48f8-9bd9-a7c5987332dc"
    travisperson = "e9febf12-1da7-43b3-b326-3f84a3ad47fa"
    bastion      = "0241a4c6-a515-4969-aac7-e0335993c941"
  }
  #fcabf618-ee67-42f0-aabd-4321d76b759c - fra2
  #f2aba2a7-8c28-406b-a8f9-2b3364ac082b - fra2
  #c4f61cf4-1b01-4fd5-a2c9-cb079791aeb3 - dfw2
  #fd804351-ad27-475b-8ff9-1b362da5119f - dfw2
  #ee32f8ff-14d8-4f66-a166-a4859b938fc1 - sin3
  #da22f7ac-ea49-4836-b40a-545dbd3f1395 - sin3
  reservations = {
    dfw = ["c4f61cf4-1b01-4fd5-a2c9-cb079791aeb3", "fd804351-ad27-475b-8ff9-1b362da5119f"],
    fra = ["fcabf618-ee67-42f0-aabd-4321d76b759c", "f2aba2a7-8c28-406b-a8f9-2b3364ac082b"],
    sin = ["ee32f8ff-14d8-4f66-a166-a4859b938fc1", "da22f7ac-ea49-4836-b40a-545dbd3f1395"],
  }
}

data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}


resource "aws_route53_record" "dfw" {
  count   = 2
  name    = "lotus-bootstrap-${count.index}.dfw"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_dfw[count.index].access_public_ipv4}"]
  ttl     = 30
}


resource "aws_route53_record" "fra" {
  count   = 2
  name    = "lotus-bootstrap-${count.index}.fra"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_fra[count.index].access_public_ipv4}"]
  ttl     = 30
}

resource "aws_route53_record" "sin" {
  count   = 2
  name    = "lotus-bootstrap-${count.index}.sin"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_bootstrap_sin[count.index].access_public_ipv4}"]
  ttl     = 30
}

resource "aws_route53_record" "fountain" {
  name    = "lotus-fountain.yyz"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.lotus_fountain.access_public_ipv4}"]
  ttl     = 30
}

resource "aws_route53_record" "stats" {
  name    = "stats"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.stats.access_public_ipv4}"]
  ttl     = 30
}

resource "dnsimple_record" "faucet" {
  domain = var.testnet_domain
  name   = "faucet"
  value  = packet_device.lotus_fountain.access_public_ipv4
  type   = "A"
  ttl    = 300
}
