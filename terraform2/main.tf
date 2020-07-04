# To add a new lotus network:
# 1. Append a new network to public_ and private_ subnets
# 2. Copy a lotus_network configuration stanza and edit appropriately
# 3. terraform apply
#
# Note: there has to be at least two "private" subnets, even if unused.

locals {
  domain_name     = "example.com"
  cidr            = "10.0.0.0/16"
  /* public_subnets  = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"] */
  /* private_subnets = ["10.0.128.0/24", "10.0.129.0/24", "10.0.129.0/24"] */
  public_subnets  = ["10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.128.0/24", "10.0.129.0/24"]
}

module "testnet" {
  source                = "./modules/lotus_network"
  name                  = "testnet"
  domain_name           = local.domain_name
  ami                   = "ami-053bc2e89490c5ab7"
  key_name              = "lotus1"
  vpc_id                = module.lotus_vpc.vpc_id
  environment           = "dev"
  bootstrapper_count    = 5
  miner_count           = 10
  miner_volumes         = 10
  database_subnet_group = module.lotus_vpc.database_subnet_group
  public_subnet_id      = module.lotus_vpc.public_subnets[0]
  public_subnet_cidr    = module.lotus_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id     = module.lotus_vpc.database_subnets[0]
  private_subnet_cidr   = module.lotus_vpc.database_subnets_cidr_blocks[0]

}

module "testnet2" {
  source                = "./modules/lotus_network"
  name                  = "testnet2"
  domain_name           = local.domain_name
  ami                   = "ami-053bc2e89490c5ab7"
  key_name              = "lotus1"
  vpc_id                = module.lotus_vpc.vpc_id
  environment           = "dev"
  database_subnet_group = module.lotus_vpc.database_subnet_group
  public_subnet_id      = module.lotus_vpc.public_subnets[1]
  public_subnet_cidr    = module.lotus_vpc.public_subnets_cidr_blocks[1]
  private_subnet_id     = module.lotus_vpc.database_subnets[1]
  private_subnet_cidr   = module.lotus_vpc.database_subnets_cidr_blocks[1]

}

/* module "testnet3" { */
/*   source                = "./modules/lotus_network" */
/*   name                  = "testnet3" */
/*   domain_name           = local.domain_name */
/*   ami                   = "ami-053bc2e89490c5ab7" */
/*   key_name              = "lotus1" */
/*   vpc_id                = module.lotus_vpc.vpc_id */
/*   environment           = "dev" */
/*   database_subnet_group = module.lotus_vpc.database_subnet_group */
/*   public_subnet_id      = module.lotus_vpc.public_subnets[0] */
/*   public_subnet_cidr    = module.lotus_vpc.public_subnets_cidr_blocks[0] */
/*   private_subnet_id     = module.lotus_vpc.database_subnets[0] */
/*   private_subnet_cidr   = module.lotus_vpc.database_subnets_cidr_blocks[0] */

/* } */
