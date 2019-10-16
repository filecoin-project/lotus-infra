data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}

locals {
  faucet_subdomain = "lotus-faucet-test"
}

resource "aws_route53_record" "faucet" {
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  name    = "${local.faucet_subdomain}.${data.aws_route53_zone.default.name}"
  type    = "A"
  records = ["${aws_instance.nginx.public_ip}"]
  ttl     = 30
}
