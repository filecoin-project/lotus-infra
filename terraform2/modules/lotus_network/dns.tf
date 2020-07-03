resource "aws_route53_zone" "subdomain" {
  name = "${var.name}.${var.domain_name}"
  vpc {
    vpc_id = var.vpc_id
  }
}

# Vainity DNS records for the tools.
# Point everything at the toolshed.

resource "aws_route53_record" "faucet" {
  zone_id = aws_route53_zone.subdomain.zone_id
  name = "faucet"
  type = "CNAME"
  ttl = 5
  records = ["toolshed-0.${var.name}.${var.domain_name}"]
}

resource "aws_route53_record" "chainwatch" {
  zone_id = aws_route53_zone.subdomain.zone_id
  name = "chainwatch"
  type = "CNAME"
  ttl = 5
  records = ["toolshed-0.${var.name}.${var.domain_name}"]
}

resource "aws_route53_record" "stats" {
  zone_id = aws_route53_zone.subdomain.zone_id
  name = "stats"
  type = "CNAME"
  ttl = 5
  records = ["toolshed-0.${var.name}.${var.domain_name}"]
}
