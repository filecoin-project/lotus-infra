resource "aws_db_subnet_group" "chainwatch" {
  name       = "chainwatch"
  subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
}

resource "aws_security_group" "chainwatch" {
  name   = "testnet_chainwatch"
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

module "chainwatch" {
  source = "../modules/chainwatch"

  instance_class         = "db.m5.xlarge"
  port                   = 5432
  password               = var.chainwatch_password
  vpc_security_group_ids = [aws_security_group.chainwatch.id]
  db_subnet_group_name   = aws_db_subnet_group.chainwatch.name
}
