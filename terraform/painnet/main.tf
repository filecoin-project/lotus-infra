variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ami" {
  default = "ami-085925f297f89fce1"
}

variable "public_subnets" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "seeders_enabled" {
  type = number
  default = 0
}

variable "miners_enabled" {
  type = number
  default = 0
}

locals {
  vault_password_file = "${path.module}/.vault_password"
  worker_count = 6
  worker_thread_count = 6

  # These zones have p3.2xlarge instances
  azs = ["us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "testnet"
  azs                  = local.azs
  cidr                 = var.cidr
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true
}

resource "aws_security_group" "this" {
  name   = "testnet"
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

module "t01000sg" {
  source = "../modules/seeder_group"

  miner_addr                  = "t01000"
  instance_type               = "r5a.24xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[0]
  availability_zone           = local.azs[0]
  worker0_ebs_volume_ids      = slice(aws_ebs_volume.t01000, 0 * local.worker_thread_count * var.seeders_enabled, 1 * local.worker_thread_count * var.seeders_enabled)
  worker1_ebs_volume_ids      = slice(aws_ebs_volume.t01000, 1 * local.worker_thread_count * var.seeders_enabled, 2 * local.worker_thread_count * var.seeders_enabled)
  worker2_ebs_volume_ids      = slice(aws_ebs_volume.t01000, 2 * local.worker_thread_count * var.seeders_enabled, 3 * local.worker_thread_count * var.seeders_enabled)
  worker3_ebs_volume_ids      = slice(aws_ebs_volume.t01000, 3 * local.worker_thread_count * var.seeders_enabled, 4 * local.worker_thread_count * var.seeders_enabled)
  worker4_ebs_volume_ids      = slice(aws_ebs_volume.t01000, 4 * local.worker_thread_count * var.seeders_enabled, 5 * local.worker_thread_count * var.seeders_enabled)
  worker5_ebs_volume_ids      = slice(aws_ebs_volume.t01000, 5 * local.worker_thread_count * var.seeders_enabled, 6 * local.worker_thread_count * var.seeders_enabled)
}

module "t01000pm" {
  source = "../modules/presealing_miner"

  miner_addr                  = "t01000"
  instance_type               = "p3.2xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[0]
  availability_zone           = local.azs[0]
  ebs_volume_ids              = slice(aws_ebs_volume.t01000, 0, length(aws_ebs_volume.t01000) * var.miners_enabled)
}

resource "aws_ebs_volume" "t01000" {
  count             = local.worker_count * local.worker_thread_count
  availability_zone = local.azs[0]
  size              = 2048
  type              = "gp2"

  tags = {
    Name = "t01000v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

module "t01001sg" {
  source = "../modules/seeder_group"

  miner_addr                  = "t01001"
  instance_type               = "r5a.24xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[2]
  availability_zone           = local.azs[2]
  worker0_ebs_volume_ids      = slice(aws_ebs_volume.t01001, 0 * local.worker_thread_count * var.seeders_enabled, 1 * local.worker_thread_count * var.seeders_enabled)
  worker1_ebs_volume_ids      = slice(aws_ebs_volume.t01001, 1 * local.worker_thread_count * var.seeders_enabled, 2 * local.worker_thread_count * var.seeders_enabled)
  worker2_ebs_volume_ids      = slice(aws_ebs_volume.t01001, 2 * local.worker_thread_count * var.seeders_enabled, 3 * local.worker_thread_count * var.seeders_enabled)
  worker3_ebs_volume_ids      = slice(aws_ebs_volume.t01001, 3 * local.worker_thread_count * var.seeders_enabled, 4 * local.worker_thread_count * var.seeders_enabled)
  worker4_ebs_volume_ids      = slice(aws_ebs_volume.t01001, 4 * local.worker_thread_count * var.seeders_enabled, 5 * local.worker_thread_count * var.seeders_enabled)
  worker5_ebs_volume_ids      = slice(aws_ebs_volume.t01001, 5 * local.worker_thread_count * var.seeders_enabled, 6 * local.worker_thread_count * var.seeders_enabled)
}

module "t01001pm" {
  source = "../modules/presealing_miner"

  miner_addr                  = "t01001"
  instance_type               = "p3.2xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[2]
  availability_zone           = local.azs[2]
  ebs_volume_ids              = slice(aws_ebs_volume.t01001, 0, length(aws_ebs_volume.t01000) * var.miners_enabled)
}

resource "aws_ebs_volume" "t01001" {
  count             = local.worker_count * local.worker_thread_count
  availability_zone = local.azs[2]
  size              = 2048
  type              = "gp2"

  tags = {
    Name = "t01001v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

module "t01002sg" {
  source = "../modules/seeder_group"

  miner_addr                  = "t01002"
  instance_type               = "r5a.24xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[2]
  availability_zone           = local.azs[2]
  worker0_ebs_volume_ids      = slice(aws_ebs_volume.t01002, 0 * local.worker_thread_count * var.seeders_enabled, 1 * local.worker_thread_count * var.seeders_enabled)
  worker1_ebs_volume_ids      = slice(aws_ebs_volume.t01002, 1 * local.worker_thread_count * var.seeders_enabled, 2 * local.worker_thread_count * var.seeders_enabled)
  worker2_ebs_volume_ids      = slice(aws_ebs_volume.t01002, 2 * local.worker_thread_count * var.seeders_enabled, 3 * local.worker_thread_count * var.seeders_enabled)
  worker3_ebs_volume_ids      = slice(aws_ebs_volume.t01002, 3 * local.worker_thread_count * var.seeders_enabled, 4 * local.worker_thread_count * var.seeders_enabled)
  worker4_ebs_volume_ids      = slice(aws_ebs_volume.t01002, 4 * local.worker_thread_count * var.seeders_enabled, 5 * local.worker_thread_count * var.seeders_enabled)
  worker5_ebs_volume_ids      = slice(aws_ebs_volume.t01002, 5 * local.worker_thread_count * var.seeders_enabled, 6 * local.worker_thread_count * var.seeders_enabled)
}

module "t01002pm" {
  source = "../modules/presealing_miner"

  miner_addr                  = "t01002"
  instance_type               = "p3.2xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[2]
  availability_zone           = local.azs[2]
  ebs_volume_ids              = slice(aws_ebs_volume.t01002, 0, length(aws_ebs_volume.t01000) * var.miners_enabled)
}

resource "aws_ebs_volume" "t01002" {
  count             = local.worker_count * local.worker_thread_count
  availability_zone = local.azs[2]
  size              = 2048
  type              = "gp2"

  tags = {
    Name = "t01002v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

module "t01003sg" {
  source = "../modules/seeder_group"

  miner_addr                  = "t01003"
  instance_type               = "r5a.24xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[3]
  availability_zone           = local.azs[3]
  worker0_ebs_volume_ids      = slice(aws_ebs_volume.t01003, 0 * local.worker_thread_count * var.seeders_enabled, 1 * local.worker_thread_count * var.seeders_enabled)
  worker1_ebs_volume_ids      = slice(aws_ebs_volume.t01003, 1 * local.worker_thread_count * var.seeders_enabled, 2 * local.worker_thread_count * var.seeders_enabled)
  worker2_ebs_volume_ids      = slice(aws_ebs_volume.t01003, 2 * local.worker_thread_count * var.seeders_enabled, 3 * local.worker_thread_count * var.seeders_enabled)
  worker3_ebs_volume_ids      = slice(aws_ebs_volume.t01003, 3 * local.worker_thread_count * var.seeders_enabled, 4 * local.worker_thread_count * var.seeders_enabled)
  worker4_ebs_volume_ids      = slice(aws_ebs_volume.t01003, 4 * local.worker_thread_count * var.seeders_enabled, 5 * local.worker_thread_count * var.seeders_enabled)
  worker5_ebs_volume_ids      = slice(aws_ebs_volume.t01003, 5 * local.worker_thread_count * var.seeders_enabled, 6 * local.worker_thread_count * var.seeders_enabled)
}

module "t01003pm" {
  source = "../modules/presealing_miner"

  miner_addr                  = "t01003"
  instance_type               = "p3.2xlarge"
  ami                         = var.ami
  vault_password_file         = local.vault_password_file
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[3]
  availability_zone           = local.azs[3]
  ebs_volume_ids              = slice(aws_ebs_volume.t01003, 0, length(aws_ebs_volume.t01000) * var.miners_enabled)
}

resource "aws_ebs_volume" "t01003" {
  count             = local.worker_count * local.worker_thread_count
  availability_zone = local.azs[3]
  size              = 2048
  type              = "gp2"

  tags = {
    Name = "t01003v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}
