resource "aws_security_group" "lotus_public" {
  name   = "${var.name}-public"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  ingress {
    from_port   = 1347
    to_port     = 1347
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.public_subnet_cidr]
  }
}

resource "aws_security_group" "lotus_private" {
  name_prefix = "${var.name}-private"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.chainwatch_port
    to_port     = var.chainwatch_port
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.private_subnet_cidr]
  }
}
