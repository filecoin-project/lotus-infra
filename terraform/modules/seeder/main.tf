variable "instance_type" {}
variable "vault_password_file" {}
variable "security_groups" {}

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
        lotus_seed_copy_binary = true
        lotus_seed_binary_src  = "/tmp/lotus-seed"
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
