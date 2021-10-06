output "ssh_connection_strings" {
  value = [
    for i in aws_instance.mod : format("ssh ubuntu@%s - %#v", i.public_ip, i.tags_all)
  ]
}
