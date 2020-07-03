module "faucet" {
  source = "../lotus_node"
  id = "${var.name}-faucet"
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
  id = "${var.name}-stats"
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
  id = "${var.name}-chainwatch"
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
  id = "${var.name}-bootstrapper"
  scale = var.bootstrapper_count
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
module "presealers" {
  source = "../lotus_node"
  id = "${var.name}-presealer"
  scale = var.miner_count * (var.preseal_mode ? 1 : 0)
  volumes = var.miner_volumes
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
  id = "${var.name}-miner"
  scale = var.miner_count * (var.preseal_mode ? 0 : 1)
  volumes = var.miner_volumes
  instance_type = var.faucet_instance_type
  availability_zone = var.availability_zone
  ami = var.ami
  zone_id = aws_route53_zone.main.id
  key_name = var.key_name
  environment = var.environment
  lotus_network = var.name
}
module "sealers" {
  source = "../lotus_node"
  id = "${var.name}-sealer"
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
