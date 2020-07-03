module "testnet" {
  source             = "./modules/lotus_network"
  name               = "testnet"
  domain_name        = local.domain_name
  ami                = "ami-053bc2e89490c5ab7"
  key_name           = "lotus1"
  vpc_id             = module.lotus_vpc.vpc_id
  azs = module.lotus_vpc.azs
  environment        = "dev"
  bootstrapper_count = 5
  miner_count        = 10
  miner_volumes      = 10
  public_subnet_id = module.lotus_vpc.public_subnets[0]
  public_subnet_cidr = module.lotus_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id = module.lotus_vpc.private_subnets[0]
  private_subnet_cidr = module.lotus_vpc.private_subnets_cidr_blocks[0]

}

/* module "testnet2" { */
/*   source            = "./modules/lotus_network" */
/*   name              = "testnet2" */
/*   domain_name       = local.domain_name */
/*   ami               = "ami-053bc2e89490c5ab7" */
/*   key_name          = "lotus1" */
/*   vpc_id            = module.lotus_vpc.vpc_id */
/*   azs = module.lotus_vpc.azs */
/*   environment       = "dev" */
/*   private0_cidr       = "10.0.5.0/24" */
/*   private1_cidr       = "10.0.6.0/24" */
/* } */
