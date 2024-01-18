data "aws_route53_zone" "domain_name" {
  zone_id = var.zone_id
}

resource "aws_route53_zone" "subdomain" {
  name = "${var.name}.${data.aws_route53_zone.domain_name.name}"
}

resource "aws_route53_record" "subdomain_ns" {
  name    = "${var.name}.${data.aws_route53_zone.domain_name.name}"
  zone_id = var.zone_id
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.subdomain.name_servers
}

# Vainity DNS records for the tools.
# Point everything at the toolshed.

resource "aws_route53_record" "faucet" {
  zone_id = aws_route53_zone.subdomain.zone_id
  name    = "faucet"
  type    = "CNAME"
  ttl     = 5
  records = ["toolshed-0.${aws_route53_zone.subdomain.name}"]
}
