output "nginx_public_ip" {
  value = "${aws_instance.nginx.public_ip}"
}

output "faucet_fqdn" {
  value = "${aws_route53_record.faucet.fqdn}"
}

output "availability_zone" {
  value = "${aws_subnet.public.availability_zone}"
}
