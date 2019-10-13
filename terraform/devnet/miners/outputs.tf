output "public_ips" {
  value = "${packet_device.miners.*.access_public_ipv4}"
}
