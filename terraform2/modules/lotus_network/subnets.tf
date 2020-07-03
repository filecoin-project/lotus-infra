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
