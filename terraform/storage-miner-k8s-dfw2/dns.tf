locals {
  subdomain = "fm"
  zone_name = "kittyhawk.wtf"
}

data "aws_route53_zone" "default" {
  name = local.zone_name
}

resource "aws_route53_record" "k8s_master" {
  count   = length(packet_device.k8s_master)
  name    = "${packet_device.k8s_master[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.k8s_master[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "miner" {
  count   = length(packet_device.miner)
  name    = "${packet_device.miner[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.miner[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "miner_noresrv" {
  count   = length(packet_device.miner_noreserv)
  name    = "${packet_device.miner_noreserv[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.miner_noreserv[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "seal_worker" {
  count   = length(packet_device.seal_worker)
  name    = "${packet_device.seal_worker[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.seal_worker[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "seal_worker_gpu" {
  count   = length(packet_device.seal_worker_gpu)
  name    = "${packet_device.seal_worker_gpu[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.seal_worker_gpu[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "generic" {
  count   = length(packet_device.generic)
  name    = "${packet_device.generic[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.generic[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "monitoring" {
  count   = length(packet_device.monitoring)
  name    = "${packet_device.monitoring[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.monitoring[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "ceph_osd" {
  count   = length(packet_device.ceph_osd)
  name    = "${packet_device.ceph_osd[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.ceph_osd[count.index].access_public_ipv4}"]
  ttl     = 300
}

resource "aws_route53_record" "ceph_mon" {
  count   = length(packet_device.ceph_mon_c2)
  name    = "${packet_device.ceph_mon_c2[count.index].hostname}.${local.subdomain}"
  zone_id = data.aws_route53_zone.default.zone_id
  type    = "A"
  records = ["${packet_device.ceph_mon_c2[count.index].access_public_ipv4}"]
  ttl     = 300
}
