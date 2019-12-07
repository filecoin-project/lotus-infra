variable "instance_type" {}
variable "vault_password_file" {}
variable "vpc_security_group_ids" {}
variable "subnet_id" {}
variable "lotus_seed_sector_size" {}
variable "lotus_seed_num_sectors" {}
variable "lotus_seed_sector_offset_0" {}
variable "lotus_seed_sector_offset_1" {}
variable "lotus_seed_reset_repo" {}
variable "lotus_seed_copy_binary" {}
variable "lotus_seed_binary_src" {}
variable "lotus_seed_miner_addr" {}
variable "zone_id" {}
variable "instance_count" {}
variable "ebs_volume_id" {}

resource "aws_instance" "lotus_seed" {
  count                       = var.instance_count
  ami                         = "ami-01caa26d7860f2195"
  instance_type               = var.instance_type
  key_name                    = "filecoin"
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 512
  }

  tags = {
    Name = "Lotus Seed"
  }
}

resource "aws_volume_attachment" "this" {
  count        = var.instance_count
  device_name  = "/dev/sdx"
  volume_id    = var.ebs_volume_id[count.index].id
  instance_id  = aws_instance.lotus_seed[count.index].id
  force_detach = false
}

resource "null_resource" "lotus_seed" {
  count      = var.instance_count
  depends_on = [aws_instance.lotus_seed, aws_volume_attachment.this, aws_route53_record.dns]

  connection {
    host = aws_instance.lotus_seed[count.index].public_ip
    user = "ubuntu"
  }

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../../ansible/lotus_seed.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.dns[count.index].fqdn}",
      ]

      playbook {
        file_path = "${path.module}/../../../ansible/lotus_seed.yml"
      }

      extra_vars = {
        ansible_ssh_user           = "ubuntu"
        name                       = "${var.lotus_seed_miner_addr}s${count.index}.seal"
        lotus_seed_copy_binary     = var.lotus_seed_copy_binary
        lotus_seed_binary_src      = var.lotus_seed_binary_src
        lotus_seed_sector_size     = var.lotus_seed_sector_size
        lotus_seed_sector_offset_0 = var.lotus_seed_sector_offset_0[count.index]
        lotus_seed_sector_offset_1 = var.lotus_seed_sector_offset_1[count.index]
        lotus_seed_num_sectors     = var.lotus_seed_num_sectors
        lotus_seed_reset_repo      = var.lotus_seed_reset_repo
        lotus_seed_miner_addr      = var.lotus_seed_miner_addr
      }

      # shared attributes
      become        = true
      become_method = "sudo"
      enabled       = true
      vault_id      = [var.vault_password_file]
      groups        = ["seeds"]
    }
  }
}

resource "aws_route53_record" "dns" {
  count   = var.instance_count
  name    = "${var.lotus_seed_miner_addr}s${count.index}.seal"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.lotus_seed[count.index].public_ip}"]
  ttl     = 30
}

output "dns_names" {
  value = aws_route53_record.dns.*.fqdn
}
