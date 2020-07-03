# an instance to run chainwatch, status, and faucet.
module "toolshed" {
  source            = "../lotus_node"
  name              = "toolshed"
  scale             = 1
  instance_type     = var.toolshed_instance_type
  availability_zone = var.azs[0]
  ami               = var.ami
  zone_id           = aws_route53_zone.subdomain.id
  key_name          = var.key_name
  environment       = var.environment
  lotus_network     = var.name
  vpc_security_group_ids = [aws_security_group.lotus.id, aws_security_group.chainwatch.id]
  private_subnet_id = aws_subnet.private0.id
  vpc_id = var.vpc_id
}

# Nodes running in bootstrapper mode
module "bootstrappers" {
  source            = "../lotus_node"
  name              = "bootstrapper"
  scale             = var.bootstrapper_count
  instance_type     = var.bootstrapper_instance_type
  availability_zone = var.azs[0]
  ami               = var.ami
  zone_id           = aws_route53_zone.subdomain.id
  key_name          = var.key_name
  environment       = var.environment
  lotus_network     = var.name
  vpc_security_group_ids = [aws_security_group.lotus.id]
  private_subnet_id = aws_subnet.private0.id
  vpc_id = var.vpc_id
}

# nodes with additional volumes
module "miners" {
  source            = "../lotus_node"
  name              = "miner"
  scale             = var.miner_count
  volumes           = var.miner_volumes
  instance_type     = var.miner_instance_type
  availability_zone = var.azs[0]
  ami               = var.ami
  zone_id           = aws_route53_zone.subdomain.id
  key_name          = var.key_name
  environment       = var.environment
  lotus_network     = var.name
  vpc_security_group_ids = [aws_security_group.lotus.id]
  private_subnet_id = aws_subnet.private0.id
  vpc_id = var.vpc_id
}

# Nodes to mess around with
module "scratch" {
  source            = "../lotus_node"
  name              = "scratch"
  scale             = var.scratch_count
  volumes           = var.scratch_volumes
  instance_type     = var.miner_instance_type
  availability_zone = var.azs[0]
  ami               = var.ami
  zone_id           = aws_route53_zone.subdomain.id
  key_name          = var.key_name
  environment       = var.environment
  lotus_network     = var.name
  vpc_security_group_ids = [aws_security_group.lotus.id]
  private_subnet_id = aws_subnet.private0.id
  vpc_id = var.vpc_id
}
