variable "instance_type" {}
variable "vault_password_file" {}
variable "vpc_security_group_ids" {}
variable "subnet_id" {}
variable "miner_addr" {}
variable "zone_id" {}
variable "ebs_volume_ids" {}
variable "index" {}

locals {
  devices = ["/dev/xvdca", "/dev/xvdcb", "/dev/xvdcc", "/dev/xvdcd"]
  name    = "${var.miner_addr}w${var.index}"
  count   = length(var.ebs_volume_ids) > 0 ? 1 : 0
}

resource "aws_instance" "this" {
  count                       = local.count
  ami                         = "ami-0e2e3e63c545211e2"
  instance_type               = var.instance_type
  key_name                    = "filecoin"
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 128
  }

  tags = {
    Name  = local.name
    Miner = var.miner_addr
  }
}

resource "aws_volume_attachment" "this" {
  count        = length(var.ebs_volume_ids)
  device_name  = local.devices[count.index]
  volume_id    = var.ebs_volume_ids[count.index].id
  instance_id  = aws_instance.this[0].id
  force_detach = false
}

resource "null_resource" "this" {
  count      = local.count
  depends_on = [aws_instance.this, aws_volume_attachment.this, aws_route53_record.this]

  connection {
    host = aws_instance.this[0].public_ip
    user = "ubuntu"
  }

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../../ansible/aws_seeder.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.this[0].fqdn}",
      ]

      playbook {
        file_path = "${path.module}/../../../ansible/aws_seeder.yml"
      }

      extra_vars = {
        ansible_user = "ubuntu"
        hostname     = aws_route53_record.this[0].fqdn
        devices      = join(";", aws_volume_attachment.this.*.device_name)
      }

      # shared attributes
      become        = true
      become_method = "sudo"
      enabled       = true
      vault_id      = [var.vault_password_file]
      groups        = ["seeder"]
    }
  }

  provisioner "remote-exec" {
      inline     = ["sudo umount ${join(" ", formatlist("%s1", aws_volume_attachment.this.*.device_name))}"]
      when       = destroy
      on_failure = continue
  }
}

resource "aws_route53_record" "this" {
  count   = local.count
  name    = "${local.name}.seeder"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.this[0].public_ip}"]
  ttl     = 30
}

output "fqdn" {
  value = aws_route53_record.this.*.fqdn
}
