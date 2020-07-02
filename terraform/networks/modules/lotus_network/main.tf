module "faucet" {
  source = "../lotus_node"
  id = "faucet"
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
module "stats" {
  source = "../lotus_node"
  id = "stats"
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
module "chainwatch" {
  source = "../lotus_node"
  id = "chainwatch"
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
module "bootstrappers" {
  source = "../lotus_node"
  id = "bootstrapper"
  scale = var.bootstrapper_count
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
module "miners" {
  source = "../lotus_node"
  id = "miner"
  scale = var.miner_count
  volumes = 2
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
