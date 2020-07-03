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
}
