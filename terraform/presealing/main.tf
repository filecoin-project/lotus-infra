locals {
  tags = {
    "Environment" = "lotus"
    "Terraform"   = "yes"
  }
  vault_password_file = "${path.module}/.vault_password"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "lotus"
  azs                  = data.aws_availability_zones.available.names
  cidr                 = var.cidr
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true

  tags = local.tags
}

resource "aws_security_group" "seed" {
  name   = "sg_seed"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}

module "seedm0" {
  source = "../modules/seeder"

  instance_count           = length(aws_ebs_volume.seedm0)
  instance_type            = "c5.24xlarge"
  lotus_seed_miner_addr    = "t0111"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file      = local.vault_password_file
  subnet_id                = module.vpc.public_subnets[0]
  vpc_security_group_ids   = [aws_security_group.seed.id]
  zone_id                  = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size   = var.lotus_seed_sector_size
  lotus_seed_num_sectors   = var.lotus_seed_num_sectors
  lotus_seed_copy_binary   = var.lotus_seed_copy_binary
  lotus_seed_reset_repo    = var.lotus_seed_reset_repo
  lotus_seed_binary_src    = var.lotus_seed_binary_src
  ebs_volume_id            = aws_ebs_volume.seedm0
}

resource "aws_ebs_volume" "seedm0" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}


module "seedm1" {
  source = "../modules/seeder"

  instance_count           = length(aws_ebs_volume.seedm0)
  instance_type            = "c5.24xlarge"
  lotus_seed_miner_addr    = "t0222"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file      = local.vault_password_file
  subnet_id                = module.vpc.public_subnets[1]
  vpc_security_group_ids   = [aws_security_group.seed.id]
  zone_id                  = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size   = var.lotus_seed_sector_size
  lotus_seed_num_sectors   = var.lotus_seed_num_sectors
  lotus_seed_copy_binary   = var.lotus_seed_copy_binary
  lotus_seed_reset_repo    = var.lotus_seed_reset_repo
  lotus_seed_binary_src    = var.lotus_seed_binary_src
  ebs_volume_id            = aws_ebs_volume.seedm1
}

resource "aws_ebs_volume" "seedm1" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}


module "seedm2" {
  source = "../modules/seeder"

  instance_count           = length(aws_ebs_volume.seedm0)
  instance_type            = "c5.24xlarge"
  lotus_seed_miner_addr    = "t0333"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file      = local.vault_password_file
  subnet_id                = module.vpc.public_subnets[2]
  vpc_security_group_ids   = [aws_security_group.seed.id]
  zone_id                  = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size   = var.lotus_seed_sector_size
  lotus_seed_num_sectors   = var.lotus_seed_num_sectors
  lotus_seed_copy_binary   = var.lotus_seed_copy_binary
  lotus_seed_reset_repo    = var.lotus_seed_reset_repo
  lotus_seed_binary_src    = var.lotus_seed_binary_src
  ebs_volume_id            = aws_ebs_volume.seedm2
}

resource "aws_ebs_volume" "seedm2" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[2]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}

module "seedm3" {
  source = "../modules/seeder"

  instance_count           = length(aws_ebs_volume.seedm0)
  instance_type            = "c5.24xlarge"
  lotus_seed_miner_addr    = "t0444"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file      = local.vault_password_file
  subnet_id                = module.vpc.public_subnets[3]
  vpc_security_group_ids   = [aws_security_group.seed.id]
  zone_id                  = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size   = var.lotus_seed_sector_size
  lotus_seed_num_sectors   = var.lotus_seed_num_sectors
  lotus_seed_copy_binary   = var.lotus_seed_copy_binary
  lotus_seed_reset_repo    = var.lotus_seed_reset_repo
  lotus_seed_binary_src    = var.lotus_seed_binary_src
  ebs_volume_id            = aws_ebs_volume.seedm3
}

resource "aws_ebs_volume" "seedm3" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[3]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}

module "seedm4" {
  source = "../modules/seeder"

  instance_count           = length(aws_ebs_volume.seedm0)
  instance_type            = "c5.24xlarge"
  lotus_seed_miner_addr    = "t0555"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file      = local.vault_password_file
  subnet_id                = module.vpc.public_subnets[0]
  vpc_security_group_ids   = [aws_security_group.seed.id]
  zone_id                  = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size   = var.lotus_seed_sector_size
  lotus_seed_num_sectors   = var.lotus_seed_num_sectors
  lotus_seed_copy_binary   = var.lotus_seed_copy_binary
  lotus_seed_reset_repo    = var.lotus_seed_reset_repo
  lotus_seed_binary_src    = var.lotus_seed_binary_src
  ebs_volume_id            = aws_ebs_volume.seedm4
}

resource "aws_ebs_volume" "seedm4" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}

resource "null_resource" "lotus_seed_start" {
  # make count 1 to execute
  count = 0
  provisioner "ansible" {
    plays {
      hosts = concat(module.seedm0.dns_names, module.seedm1.dns_names, module.seedm2.dns_names, module.seedm3.dns_names, module.seedm4.dns_names)

      module {
        module = "systemd"
        args = {
          name  = "lotus-seed"
          state = "started"
        }
      }

      extra_vars = {
        ansible_ssh_user = "ubuntu"
      }

      # shared attributes
      become        = true
      become_method = "sudo"
      enabled       = true
      vault_id      = [local.vault_password_file]
      groups        = ["seeds"]
    }
  }
}

output "sealing_machines" {
  value = concat(module.seedm0.dns_names, module.seedm1.dns_names, module.seedm2.dns_names, module.seedm3.dns_names, module.seedm4.dns_names)
}
