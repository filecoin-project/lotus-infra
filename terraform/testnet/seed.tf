resource "aws_security_group" "seed" {
  name        = "lotus-seed-all"
  description = "Allow all traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lotus_seed" {
  ami             = "ami-01caa26d7860f2195"
  instance_type   = "c5d.24xlarge"
  key_name        = "filecoin"
  security_groups = [aws_security_group.seed.name]

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
    script_sha1 = "${sha1(file("${path.module}/../../ansible/lotus_seed.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_instance.lotus_seed.public_ip}",
      ]

      playbook {
        file_path = "../../ansible/lotus_seed.yml"
      }

      extra_vars = {
        ansible_ssh_user = "ubuntu"
      }

      # shared attributes
      become        = true
      become_method = "sudo"
      enabled       = true
      vault_id      = [".vault_password"]
      groups        = ["seeds"]
    }
  }
}
