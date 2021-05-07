resource "jdcloud_network_security_group" "mod" {
  network_security_group_name = "${var.name}-${var.env}-sg"
  vpc_id                      = jdcloud_vpc.vpc.id
}

resource "jdcloud_network_security_group_rules" "mod_sg_rules" {
  security_group_id = jdcloud_network_security_group.mod.id
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 0
    from_port      = 22
    to_port        = 22
    protocol       = "6"
  }
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 1
    from_port      = 443
    to_port        = 443
    protocol       = "6"
  }
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 1
    from_port      = 80
    to_port        = 80
    protocol       = "6"
  }
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 1
    from_port      = 1234
    to_port        = 1234
    protocol       = "6"
  }
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 1
    from_port      = 2345
    to_port        = 2345
    protocol       = "6"
  }
  # ICMP
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 1
    protocol       = "1"
  }

  # ICMP
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 0
    protocol       = "1"
  }

  # NTP
  security_group_rules {
    address_prefix = "0.0.0.0/0"
    direction      = 1
    protocol       = "17"
  }
}



resource "jdcloud_instance" "mod_client" {
  az            = var.az
  instance_name = "${var.name}-${var.env}-1"
  instance_type = "g.n2.2xlarge"
  # This is CentOS 7.6
  # image_id    = "img-kxs3xhhwy6"
  image_id    = var.image_id
  password    = "CHANGElater88"
  key_names   = jdcloud_key_pairs.ssh_key.key_name
  description = "Managed by terraform"

  subnet_id = jdcloud_subnet.public_a.id
  security_group_ids = [
    jdcloud_network_security_group.mod.id
  ]

  system_disk {
    disk_category = "cloud"
    auto_delete   = true
    device_name   = "vda"
  }
}

resource "jdcloud_eip" "eip" {
  eip_provider   = "bgp"
  bandwidth_mbps = 15
}

resource "jdcloud_eip_association" "eip_assoc" {
  instance_id   = jdcloud_instance.mod_client.id
  elastic_ip_id = jdcloud_eip.eip.id
}
