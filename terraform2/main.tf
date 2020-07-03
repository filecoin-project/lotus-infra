module "testnet" {
  source = "./modules/lotus_network"
  name =  "testnet"
  domain_name = "testnet.com"
  ami = "ami-a0cfeed8"
  key_name = "lotus1"
  availability_zone = "us-west-2a"
  environment = "dev"
  bootstrapper_count = 5
  miner_count = 10
  miner_volumes = 10
  
}

module "testnet2" {
  source = "./modules/lotus_network"
  name =  "testnet2"
  domain_name = "testnet2.com"
  ami = "ami-a0cfeed8"
  key_name = "lotus1"
  availability_zone = "us-west-2a"
  environment = "dev"
}
