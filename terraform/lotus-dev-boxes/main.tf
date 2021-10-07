## CAUTION
#  Do not edit the following unless you know what you're doing

terraform {
  backend "s3" {
    bucket         = "filecoin-terraform-state"
    key            = "filecoin-lotus-dev-boxes.tfstate"
    dynamodb_table = "filecoin-terraform-state"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-2"
}

module "lotus_dev_boxes" {
  source             = "../modules/lotus_dev_boxes"
  boxes              = local.machines
  subnet_id          = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  security_group_ids = [aws_security_group.mod.id]
}

resource "aws_security_group" "mod" {
  name        = "lotus_dev_boxes"
  description = "ports for lotus"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress = [
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
    },
    {
      description      = "Range of ports for lotus"
      from_port        = 1234
      to_port          = 3456
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
    }
  ]

  egress = [
    {
      description      = "Fully open egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
    }
  ]

  tags = {
    Name = "lotus dev boxes"
  }
}


## @TODO support multiple regions
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "filecoin-terraform-state"
    key    = "filecoin-mainnet-eks-us-east-2-dev.tfstate"
    region = "us-east-1"
  }
}
