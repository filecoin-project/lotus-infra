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

  ingress {
    from_port   = 1347
    to_port     = 1347
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

/*
module "seedm0" {
  source = "../modules/seeder"

  instance_count             = length(aws_ebs_volume.seedm0)
  instance_type              = "r5.24xlarge"
  lotus_seed_miner_addr      = "t0111"
  lotus_seed_sector_offset_0 = var.lotus_seed_sector_offset_0
  lotus_seed_sector_offset_1 = var.lotus_seed_sector_offset_1
  vault_password_file        = local.vault_password_file
  subnet_id                  = module.vpc.public_subnets[0]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size     = var.lotus_seed_sector_size
  lotus_seed_num_sectors     = var.lotus_seed_num_sectors
  lotus_seed_copy_binary     = var.lotus_seed_copy_binary
  lotus_seed_reset_repo      = var.lotus_seed_reset_repo
  lotus_seed_binary_src      = var.lotus_seed_binary_src
  ebs_volume_id              = aws_ebs_volume.seedm0
}
*/
/*
module "t0111" {
  source = "../modules/presealing_miner"

  instance_type              = "p3.2xlarge"
  lotus_seed_miner_addr      = "t0111"
  subnet_id                  = module.vpc.public_subnets[0]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  ebs_volume_id              = aws_ebs_volume.seedm3
}
*/

resource "aws_ebs_volume" "seedm0" {
  count             = length(var.lotus_seed_sector_offset_0)
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.ebs_volume_size
  type              = "gp2"

  tags = {
    Name = "seedm0s${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

/*
module "seedm1" {
  source = "../modules/seeder"

  instance_count             = length(aws_ebs_volume.seedm0)
  instance_type              = "r5.24xlarge"
  lotus_seed_miner_addr      = "t0222"
  lotus_seed_sector_offset_0 = var.lotus_seed_sector_offset_0
  lotus_seed_sector_offset_1 = var.lotus_seed_sector_offset_1
  vault_password_file        = local.vault_password_file
  subnet_id                  = module.vpc.public_subnets[1]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size     = var.lotus_seed_sector_size
  lotus_seed_num_sectors     = var.lotus_seed_num_sectors
  lotus_seed_copy_binary     = var.lotus_seed_copy_binary
  lotus_seed_reset_repo      = var.lotus_seed_reset_repo
  lotus_seed_binary_src      = var.lotus_seed_binary_src
  ebs_volume_id              = aws_ebs_volume.seedm1
}
*/
module "t0222" {
  source = "../modules/presealing_miner"

  instance_type              = "p3.2xlarge"
  lotus_seed_miner_addr      = "t0222"
  subnet_id                  = module.vpc.public_subnets[1]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  ebs_volume_id              = aws_ebs_volume.seedm1
}

resource "aws_ebs_volume" "seedm1" {
  count             = length(var.lotus_seed_sector_offset_0)
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = var.ebs_volume_size
  type              = "gp2"

  tags = {
    Name = "seedm1s${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}


/*
module "seedm2" {
  source = "../modules/seeder"

  instance_count             = length(aws_ebs_volume.seedm0)
  instance_type              = "r5.24xlarge"
  lotus_seed_miner_addr      = "t0333"
  lotus_seed_sector_offset_0 = var.lotus_seed_sector_offset_0
  lotus_seed_sector_offset_1 = var.lotus_seed_sector_offset_1
  vault_password_file        = local.vault_password_file
  subnet_id                  = module.vpc.public_subnets[2]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size     = var.lotus_seed_sector_size
  lotus_seed_num_sectors     = var.lotus_seed_num_sectors
  lotus_seed_copy_binary     = var.lotus_seed_copy_binary
  lotus_seed_reset_repo      = var.lotus_seed_reset_repo
  lotus_seed_binary_src      = var.lotus_seed_binary_src
  ebs_volume_id              = aws_ebs_volume.seedm2
}
*/

module "t0333" {
  source = "../modules/presealing_miner"

  instance_type              = "p3.2xlarge"
  lotus_seed_miner_addr      = "t0333"
  subnet_id                  = module.vpc.public_subnets[2]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  ebs_volume_id              = aws_ebs_volume.seedm2
}


resource "aws_ebs_volume" "seedm2" {
  count             = length(var.lotus_seed_sector_offset_0)
  availability_zone = data.aws_availability_zones.available.names[2]
  size              = var.ebs_volume_size
  type              = "gp2"

  tags = {
    Name = "seedm2s${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

/*
module "seedm3" {
  source = "../modules/seeder"

  instance_count             = length(aws_ebs_volume.seedm0)
  instance_type              = "r5.24xlarge"
  lotus_seed_miner_addr      = "t0444"
  lotus_seed_sector_offset_0 = var.lotus_seed_sector_offset_0
  lotus_seed_sector_offset_1 = var.lotus_seed_sector_offset_1
  vault_password_file        = local.vault_password_file
  subnet_id                  = module.vpc.public_subnets[3]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size     = var.lotus_seed_sector_size
  lotus_seed_num_sectors     = var.lotus_seed_num_sectors
  lotus_seed_copy_binary     = var.lotus_seed_copy_binary
  lotus_seed_reset_repo      = var.lotus_seed_reset_repo
  lotus_seed_binary_src      = var.lotus_seed_binary_src
  ebs_volume_id              = aws_ebs_volume.seedm3
}
*/

module "t0444" {
  source = "../modules/presealing_miner"

  instance_type              = "p3.2xlarge"
  lotus_seed_miner_addr      = "t0444"
  subnet_id                  = module.vpc.public_subnets[3]
  vpc_security_group_ids     = [aws_security_group.seed.id]
  zone_id                    = data.aws_route53_zone.default.zone_id
  ebs_volume_id              = aws_ebs_volume.seedm3
}

resource "aws_ebs_volume" "seedm3" {
  count             = length(var.lotus_seed_sector_offset_0)
  availability_zone = data.aws_availability_zones.available.names[3]
  size              = var.ebs_volume_size
  type              = "gp2"

  tags = {
    Name = "seedm3s${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

/*
output "sealing_machines" {
  value = concat(module.seedm0.dns_names, module.seedm1.dns_names, module.seedm2.dns_names, module.seedm3.dns_names)
}
*/

output "sealing_machines" {
  value = [module.t0222.dns_name, module.t0333.dns_name, module.t0444.dns_name]
}
