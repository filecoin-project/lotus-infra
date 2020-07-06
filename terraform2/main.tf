# To add a new lotus network:
# 1. Append a new network to public_ and private_ subnets
# 2. Copy a lotus_network configuration stanza and edit appropriately
# 3. terraform apply
#
# Note: there has to be at least two "private" subnets, even if unused.

locals {
  domain_name     = "fildev.network"
  cidr            = "10.0.0.0/16"
  /* public_subnets  = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"] */
  /* private_subnets = ["10.0.128.0/24", "10.0.129.0/24", "10.0.129.0/24"] */
  public_subnets  = ["10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.128.0/24", "10.0.129.0/24"]
}

module "fishnet" {
  source                      = "./modules/devnet"
  name                        = "fish"
  domain_name                 = local.domain_name
  domain_name_zone_id         = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  bootstrapper_count          = 4
  preminer_count              = 3
  scratch_count               = 2
  toolshed_instance_type      = "m5a.large"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.fishnet_chainwatch_password
  preminer_instance_type      = "m5a.2xlarge"
  bootstrapper_instance_type  = "m5a.large"
  scratch_instance_type       = "m5a.large"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[0]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[0]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[0]

}

/*
module "testnet2" {
  source                = "./modules/devnet"
  name                  = "testnet2"
  domain_name           = local.domain_name
  ami                   = "ami-053bc2e89490c5ab7"
  key_name              = "lotus1"
  vpc_id                = module.fildev_network_vpc.vpc_id
  environment           = "dev"
  database_subnet_group = module.fildev_network_vpc.database_subnet_group
  public_subnet_id      = module.fildev_network_vpc.public_subnets[1]
  public_subnet_cidr    = module.fildev_network_vpc.public_subnets_cidr_blocks[1]
  private_subnet_id     = module.fildev_network_vpc.database_subnets[1]
  private_subnet_cidr   = module.fildev_network_vpc.database_subnets_cidr_blocks[1]
}
*/

/* module "testnet3" { */
/*   source                = "./modules/lotus_network" */
/*   name                  = "testnet3" */
/*   domain_name           = local.domain_name */
/*   ami                   = "ami-053bc2e89490c5ab7" */
/*   key_name              = "lotus1" */
/*   vpc_id                = module.fildev_network_vpc.vpc_id */
/*   environment           = "dev" */
/*   database_subnet_group = module.fildev_network_vpc.database_subnet_group */
/*   public_subnet_id      = module.fildev_network_vpc.public_subnets[0] */
/*   public_subnet_cidr    = module.fildev_network_vpc.public_subnets_cidr_blocks[0] */
/*   private_subnet_id     = module.fildev_network_vpc.database_subnets[0] */
/*   private_subnet_cidr   = module.fildev_network_vpc.database_subnets_cidr_blocks[0] */

/* } */
