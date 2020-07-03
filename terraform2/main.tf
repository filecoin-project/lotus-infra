module "testnet" {
  source = "./modules/lotus_network"
  name =  "testnet"
  domain_name = local.domain_name
  ami = "ami-053bc2e89490c5ab7"
  key_name = "lotus1"
  vpc_id = aws_vpc.lotus_vpc.id
  availability_zone = "us-west-2a"
  environment = "dev"
  bootstrapper_count = 5
  miner_count = 10
  miner_volumes = 10
  
}

module "testnet2" {
  source = "./modules/lotus_network"
  name =  "testnet2"
  domain_name = local.domain_name
  ami = "ami-053bc2e89490c5ab7"
  key_name = "lotus1"
  vpc_id = aws_vpc.lotus_vpc.id
  availability_zone = "us-west-2a"
  environment = "dev"
}
