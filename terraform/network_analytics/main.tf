variable "instance_type" {
  default = "m5.2xlarge"
}

variable "instance_type_large" {
  default = "m5.4xlarge"
}

variable "zone_id" {
  default = "Z4QUK41V3HPV5"
}

resource "aws_security_group" "main" {
  name   = "fc-network-analytics"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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
  cidr_block        = "172.31.253.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "compute" {
  count                       = 4
  ami                         = "ami-07c1207a9d40bc3bd"
  instance_type               = var.instance_type
  key_name                    = "filecoin"
  vpc_security_group_ids      = [aws_security_group.main.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 512
  }

  tags = {
    Name  = "na.compute${count.index}"
  }
}

resource "aws_route53_record" "compute" {
  count   = length(aws_instance.compute)
  name    = "compute${count.index}.na"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.compute[count.index].public_ip}"]
  ttl     = 30
}

resource "aws_instance" "compute_large" {
  count                       = 1
  ami                         = "ami-07c1207a9d40bc3bd"
  instance_type               = var.instance_type_large
  key_name                    = "filecoin"
  vpc_security_group_ids      = [aws_security_group.main.id]
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 512
  }

  tags = {
    Name  = "na.compute${count.index}-large"
  }
}

resource "aws_route53_record" "compute_large" {
  count   = length(aws_instance.compute_large)
  name    = "compute${count.index}-large.na"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.compute_large[count.index].public_ip}"]
  ttl     = 30
}

resource "aws_route53_record" "sentinel" {
  zone_id = var.zone_id
  type    = "CNAME"
  name    = "sentinel"
  records = ["compute0-large.na.kittyhawk.wtf"]
  ttl     = 30
}

data "aws_availability_zones" "available" {}
