# Chainwatch database

resource "aws_db_instance" "chainwatch_db" {
  allocated_storage      = 32
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.6"
  instance_class         = var.chainwatch_db_instance_type
  name                   = "chainwatch"
  username               = var.chainwatch_username
  password               = var.chainwatch_password
  publicly_accessible    = true
  port                   = var.chainwatch_port
  vpc_security_group_ids = [aws_security_group.chainwatch.id]
  db_subnet_group_name = aws_db_subnet_group.chainwatch.name
  skip_final_snapshot    = true
  identifier_prefix      = var.name
}

resource "aws_db_subnet_group" "chainwatch" {
  name_prefix = var.name
  subnet_ids = [aws_subnet.private0.id, aws_subnet.private1.id]
}

resource "aws_security_group" "chainwatch" {
  name_prefix = var.name
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.chainwatch_port
    to_port     = var.chainwatch_port
    protocol    = "tcp"
    cidr_blocks = [var.private0_cidr, var.private1_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
