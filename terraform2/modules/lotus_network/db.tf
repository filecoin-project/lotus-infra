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
  vpc_security_group_ids = [aws_security_group.lotus_private.id]
 db_subnet_group_name = aws_db_subnet_group.chainwatch.name
  skip_final_snapshot    = true
  identifier_prefix      = var.name
  multi_az = false
}

resource "aws_db_subnet_group" "chainwatch" {
  name_prefix = var.name
  subnet_ids = [var.private_subnet_id, var.public_subnet_id]
}

