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

data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}

module "seed01" {
  source = "../modules/seeder"

  name = "seed01"
  instance_type = "c5d.24xlarge"
  vault_password_file = "${path.module}/.vault_password"
  security_groups = [aws_security_group.seed.name]
  zone_id = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size = var.lotus_seed_sector_size
  lotus_seed_num_sectors = var.lotus_seed_num_sectors
  lotus_seed_copy_binary = var.lotus_seed_copy_binary
  lotus_seed_reset_repo = var.lotus_seed_reset_repo
  lotus_seed_binary_src = var.lotus_seed_binary_src
  lotus_seed_miner_addr  = "t0101"
}
