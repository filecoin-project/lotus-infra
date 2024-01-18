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
