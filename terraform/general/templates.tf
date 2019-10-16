data "template_file" "nginx_faucet" {
  template = "${file("tmpl/nginx_faucet.conf")}"

  vars = {
    server_name = "${local.faucet_subdomain}.${replace(data.aws_route53_zone.default.name, "/.$/", "")}"
    remote_host = "147.75.80.29:777"
  }
}
