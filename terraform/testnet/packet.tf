/*
resource "aws_route53_zone" "subdomain" {
  name = "${var.name}.${data.aws_route53_zone.domain_name.name}"
}
*/

locals {
  facilities        = ["dfw2", "fra2", "sin3"]
  node_per_facility = 2
}

resource "packet_device" "bootstrap" {
  count                            = length(local.facilities) * local.node_per_facility
  hostname                         = "bootstrap-${count.index}"
  plan                             = "x1.small.x86"
  facilities                       = [local.facilities[count.index % length(local.facilities)]]
  operating_system                 = "ubuntu_18_04"
  billing_cycle                    = "hourly"
  project_id                       = var.project_id
  project_ssh_key_ids              = values(local.ssh_keys)
  hardware_reservation_id          = "next-available"
  wait_for_reservation_deprovision = true
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
resource "aws_route53_record" "node" {
  count   = length(packet_device.bootstrap)
  name    = "bootstrap-${count.index}"
  zone_id = var.zone_id
  type    = "A"
  records = [packet_device.bootstrap[count.index].access_public_ipv4]
  ttl     = 30
}


resource "dnsimple_record" "faucet" {
  domain = var.testnet_domain
  name   = "faucet"
  value  = "faucet.${var.zone_id_name}"
  type   = "CNAME"
  ttl    = 300
}
