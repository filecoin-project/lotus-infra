# To add a new lotus network:
# 1. Append a new network to public_ and private_ subnets
# 2. Copy a lotus_network configuration stanza and edit appropriately
# 3. terraform apply
#
# Note: there has to be at least two "private" subnets, even if unused.

locals {
  domain_name     = "fildev.network"
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.2.0/24", "10.0.3.0/24", "10.0.255.0/24", "10.0.4.0/24"]
  private_subnets = ["10.0.128.0/24", "10.0.129.0/24", "10.0.130.0/24", "10.0.131.0/24"]
}

/*****************
 * us-west-2
 *****************/
module "yafnet" {
  source                      = "../../modules/devnet"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "yaf"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  toolshed_count              = 2
  bootstrapper_count          = 2
  preminer_count              = 6
  scratch_count               = 2
  toolshed_instance_type      = "m5a.xlarge"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "m5a.4xlarge"
  bootstrapper_instance_type  = "m5a.xlarge"
  scratch_instance_type       = "m5a.xlarge"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[0]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[0]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[0]
}

module "butterflynet" {
  source                      = "../../modules/devnet"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "butterfly"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  toolshed_count              = 2
  bootstrapper_count          = 2
  preminer_count              = 6
  scratch_count               = 2
  toolshed_instance_type      = "m5a.large"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "m5a.4xlarge"
  bootstrapper_instance_type  = "m5a.large"
  scratch_instance_type       = "m5a.large"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[1]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[1]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[1]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[1]
}

module "seeding" {
  source                      = "../../modules/seeding"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "seeding"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  presealer_count             = 0
  presealer_instance_type     = "c5.24xlarge"
  presealer_iam_profile       = aws_iam_instance_profile.presealer.id
  public_subnet_id            = module.fildev_network_vpc.public_subnets[2]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[2]
}

module "calibrationnet" {
  source                      = "../../modules/devnet"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "calibration"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  toolshed_count              = 2
  bootstrapper_count          = 4
  preminer_count              = 3
  scratch_count               = 2
  toolshed_instance_type      = "m5a.large"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "m5a.4xlarge"
  bootstrapper_instance_type  = "m5a.large"
  scratch_instance_type       = "m5a.large"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[3]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[3]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[3]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[3]
}

/*****************
 * us-east-1
 *****************/

module "testnet" {
  source                      = "../../modules/devnet"
  providers = {
    aws = aws.us-east-1
  }
  name                        = "testnet"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-0bcc094591f354be2"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc_east.vpc_id
  environment                 = "prod"
  toolshed_count              = 6
  toolshed_external           = 1
  bootstrapper_count          = 0
  preminer_count              = 3
  preminer_external           = 1
  scratch_count               = 2
  scratch_external            = 1
  toolshed_instance_type      = "m5a.4xlarge"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "p3.2xlarge"
  preminer_volume_size        = 384
  bootstrapper_instance_type  = "m5a.2xlarge"
  scratch_instance_type       = "m5a.2xlarge"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc_east.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc_east.public_subnets[0]
  public_subnet_cidr          = module.fildev_network_vpc_east.public_subnets_cidr_blocks[0]
  private_subnet_id           = module.fildev_network_vpc_east.database_subnets[0]
  private_subnet_cidr         = module.fildev_network_vpc_east.database_subnets_cidr_blocks[0]
}
