data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}

locals {
  faucet_subdomain = "lotus-faucet"
}

resource "aws_route53_record" "faucet" {
  name    = "faucet-record"
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  type    = "A"
  records = ["${aws_instance.nginx.public_ip}"]
  ttl     = 30
}
