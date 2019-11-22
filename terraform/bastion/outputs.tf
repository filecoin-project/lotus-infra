output "public_ip" {
  value = "${packet_device.bastion.*.access_public_ipv4}"
}

output "public_ssh_key_path" {
  value = "/tmp/bastion-key.pub"
}
