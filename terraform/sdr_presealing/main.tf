variable "miner_addr" {
  default = "t02000"
}

variable "instance_type" {
  default = "r5a.24xlarge"
  #default = "m5.2xlarge"
}

variable "zone_id" {
  default = "Z4QUK41V3HPV5"
}

locals {
  vault_password_file = "${path.module}/.vault_password"
}

resource "aws_security_group" "this" {
  name   = "sdr_presealing"
  vpc_id = data.aws_vpc.default.id

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

data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "main" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.254.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

module "worker0" {
  source = "../modules/seeder"

  miner_addr                  = var.miner_addr
  instance_type               = var.instance_type
  ami                         = ""
  zone_id                     = var.zone_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = aws_subnet.main.id
  ebs_volume_ids              = [] #aws_ebs_volume.worker0
  vault_password_file         = local.vault_password_file
  index                       = 0
  swap_enabled                = true
}

data "aws_availability_zones" "available" {}

resource "aws_ebs_volume" "worker0" {
  count             = 6
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.miner_addr}v${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}
