variable "storage_type" {
  default = "gp2"
}

variable "engine" {
  default = "postgres"
}

variable "engine_version" {
  default = "11.6"
}

variable "allocated_storage" {
  default = 32
}

variable "name" {
  default = "chainwatch"
}

variable "username" {
  default = "postgres"
}

variable "publicly_accessible" {
  default = true
}

variable "port" {}
variable "instance_class" {}
variable "password" {}
variable "vpc_security_group_ids" {}
variable "db_subnet_group_name" {}

resource "aws_db_instance" "this" {
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  name                   = var.name
  username               = var.username
  password               = var.password
  publicly_accessible    = var.publicly_accessible
  port                   = var.port
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  final_snapshot_identifier = "foo"
  skip_final_snapshot    = true
}

output "address" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "username" {
  value = aws_db_instance.this.username
}
