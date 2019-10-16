output "public_ips_ams1" {
  value = "${packet_device.ams1.*.access_public_ipv4}"
}

output "public_ips_ewr1" {
  value = "${packet_device.ewr1.*.access_public_ipv4}"
}

output "public_ips_nrt1" {
  value = "${packet_device.nrt1.*.access_public_ipv4}"
}

output "public_ips_sjc1" {
  value = "${packet_device.sjc1.*.access_public_ipv4}"
}
