variable "zone_id" {}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "seeders_enabled" {
  type = number
  default = 0
}

locals {
  vault_password_file = "${path.module}/.vault_password"
  worker_count = 5
  worker_thread_count = 2
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "painnet"
  azs                  = data.aws_availability_zones.available.names
  cidr                 = var.cidr
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true
}

resource "aws_security_group" "this" {
  name   = "painnet"
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

module "t0201" {
  source = "../modules/seeder_group"

  miner_addr                  = "t0201"
  instance_type               = "t2.large"
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[0]
  worker0_ebs_volume_ids      = slice(aws_ebs_volume.t0201, 0 * local.worker_thread_count * var.seeders_enabled, 1 * local.worker_thread_count * var.seeders_enabled)
  worker1_ebs_volume_ids      = slice(aws_ebs_volume.t0201, 1 * local.worker_thread_count * var.seeders_enabled, 2 * local.worker_thread_count * var.seeders_enabled)
  worker2_ebs_volume_ids      = slice(aws_ebs_volume.t0201, 2 * local.worker_thread_count * var.seeders_enabled, 3 * local.worker_thread_count * var.seeders_enabled)
  worker3_ebs_volume_ids      = slice(aws_ebs_volume.t0201, 3 * local.worker_thread_count * var.seeders_enabled, 4 * local.worker_thread_count * var.seeders_enabled)
  worker4_ebs_volume_ids      = slice(aws_ebs_volume.t0201, 4 * local.worker_thread_count * var.seeders_enabled, 5 * local.worker_thread_count * var.seeders_enabled)
}

module "t0202" {
  source = "../modules/seeder_group"

  miner_addr                  = "t0202"
  instance_type               = "t2.large"
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[0]
  worker0_ebs_volume_ids      = slice(aws_ebs_volume.t0202, 0 * local.worker_thread_count * var.seeders_enabled, 1 * local.worker_thread_count * var.seeders_enabled)
  worker1_ebs_volume_ids      = slice(aws_ebs_volume.t0202, 1 * local.worker_thread_count * var.seeders_enabled, 2 * local.worker_thread_count * var.seeders_enabled)
  worker2_ebs_volume_ids      = slice(aws_ebs_volume.t0202, 2 * local.worker_thread_count * var.seeders_enabled, 3 * local.worker_thread_count * var.seeders_enabled)
  worker3_ebs_volume_ids      = slice(aws_ebs_volume.t0202, 3 * local.worker_thread_count * var.seeders_enabled, 4 * local.worker_thread_count * var.seeders_enabled)
  worker4_ebs_volume_ids      = slice(aws_ebs_volume.t0202, 4 * local.worker_thread_count * var.seeders_enabled, 5 * local.worker_thread_count * var.seeders_enabled)
}

resource "aws_ebs_volume" "t0201" {
  count             = local.worker_count * local.worker_thread_count
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 32
  type              = "gp2"

  tags = {
    Name = "t0201v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ebs_volume" "t0202" {
  count             = local.worker_count * local.worker_thread_count
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 32
  type              = "gp2"

  tags = {
    Name = "t0202v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}
