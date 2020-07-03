resource "aws_subnet" "private0" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private0_cidr
  availability_zone = var.azs[0]
}

resource "aws_subnet" "private1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private1_cidr
  availability_zone = var.azs[0]
}


resource "aws_security_group" "lotus" {
  name   = var.name
  vpc_id = var.vpc_id

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
