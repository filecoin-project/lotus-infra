resource "aws_security_group" "seed" {
  name        = "lotus-seed-all-2"
  description = "Allow all traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

module "seed01" {
  source = "../modules/seeder"

  instance_type = "c5d.24xlarge"
  vault_password_file = "${path.module}/.vault_password"
  security_groups = [aws_security_group.seed.name]
}
