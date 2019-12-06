variable "instance_type" {}
variable "vault_password_file" {}
variable "security_groups" {}
variable "lotus_seed_sector_size" {}
variable "lotus_seed_num_sectors" {}
variable "lotus_seed_reset_repo" {}
variable "lotus_seed_copy_binary" {}
variable "lotus_seed_binary_src" {}
variable "lotus_seed_miner_addr" {}
variable "zone_id" {}
variable "name" {}

resource "aws_instance" "lotus_seed" {
  ami             = "ami-01caa26d7860f2195"
  instance_type   = var.instance_type
  key_name        = "filecoin"
  security_groups = var.security_groups

  root_block_device {
    volume_type = "gp2"
    volume_size = 512
  }

  tags = {
    Name = "Lotus Seed"
  }
}

resource "null_resource" "lotus_seed" {
  depends_on = [aws_instance.lotus_seed]

  connection {
    host = aws_instance.lotus_seed.public_ip
    user = "ubuntu"
  }

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../../ansible/lotus_seed.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_instance.lotus_seed.public_ip}",
      ]

      playbook {
        file_path = "${path.module}/../../../ansible/lotus_seed.yml"
      }

      extra_vars = {
        ansible_ssh_user       = "ubuntu"
        lotus_seed_copy_binary = var.lotus_seed_copy_binary
        lotus_seed_binary_src  = var.lotus_seed_binary_src
        lotus_seed_sector_size = var.lotus_seed_sector_size
        lotus_seed_num_sectors = var.lotus_seed_num_sectors
        lotus_seed_reset_repo  = var.lotus_seed_reset_repo
        lotus_seed_miner_addr  = var.lotus_seed_miner_addr
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
  name    = "lotus-seed.${var.name}"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.lotus_seed.public_ip}"]
  ttl     = 30
}
