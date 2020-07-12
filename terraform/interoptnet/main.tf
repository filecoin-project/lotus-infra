variable "zone_id" {}
variable "chainwatch_password" {}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

locals {
  vault_password_file = "${path.module}/.vault_password"
  devices = ["/dev/xvdca", "/dev/xvdcb", "/dev/xvdcc", "/dev/xvdcd"]
  workers = 2
  swap = 1
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "interopnet"
  azs                  = data.aws_availability_zones.available.names
  cidr                 = var.cidr
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true
}

module "chainwatch" {
  source = "../modules/chainwatch"

  instance_class         = "db.m5.xlarge"
  port                   = 5432
  password               = var.chainwatch_password
  vpc_security_group_ids = [aws_security_group.chainwatch.id]
  db_subnet_group_name   = aws_db_subnet_group.chainwatch.name
}

resource "aws_db_subnet_group" "chainwatch" {
  name       = "chainwatch"
  subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
}

resource "aws_security_group" "chainwatch" {
  name   = "interopnet_db"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_security_group" "this" {
  name   = "interopnet"
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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
