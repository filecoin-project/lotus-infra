variable "instance_type" {
  default = "m5.large"
}

variable "zone_id" {
  default = "Z20IIH8V8YZVBW"
}

variable "ami" {
  default = "ami-085925f297f89fce1"
}

locals {
  names = [
    "nicolas",
    "philipp",
    "mathilde",
    "ludovic",
    "gabbi",
    "linus",
    "jeff",
  ]
}

resource "aws_security_group" "main" {
  name   = "drand-testnet"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_subnet" "main" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.252.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "nodes" {
  count                       = length(local.names)
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = "filecoin"
  vpc_security_group_ids      = [aws_security_group.main.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = "true"
  user_data                   = <<EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get upgrade -y
  hostname "${local.names[count.index]}.drand"
  EOF

  root_block_device {
    volume_type = "gp2"
    volume_size = 32
  }

  tags = {
    Name  = "${local.names[count.index]}.drand"
  }
}

resource "aws_route53_record" "nodes" {
  count   = length(aws_instance.nodes)
  name    = "${local.names[count.index]}.drand"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.nodes[count.index].public_ip}"]
  ttl     = 30
}

data "aws_availability_zones" "available" {}
