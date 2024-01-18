# To add a new lotus network:
# 1. Append a new network to public_ and private_ subnets
# 2. Copy a lotus_network configuration stanza and edit appropriately
# 3. terraform apply
#
# Note: there has to be at least two "private" subnets, even if unused.

locals {
  domain_name     = "fildev.network"
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.2.0/24"]
  private_subnets = ["10.0.128.0/24", "10.0.129.0/24"]
}

/*****************
 * us-west-2
 *****************/

module "interopnet" {
  source = "../../modules/devnet"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "interop"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin-mainnet"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  toolshed_count              = 0
  bootstrapper_count          = 0
  preminer_count              = 0
  scratch_count               = 0
  toolshed_instance_type      = "m5a.xlarge"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "m5a.4xlarge"
  preminer_volume_size        = 384
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
  source = "../../modules/devnet"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "butterfly"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin-mainnet"
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
  preminer_volume_size        = 384
  bootstrapper_instance_type  = "m5a.large"
  scratch_instance_type       = "m5a.large"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[0]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[0]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[0]
}

module "calibrationnet" {
  source = "../../modules/devnet"
  providers = {
    aws = aws.us-west-2
  }
  name                        = "calibration"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin-mainnet"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  toolshed_count              = 2
  bootstrapper_count          = 4
  preminer_count              = 3
  scratch_count               = 2
  toolshed_instance_type      = "m5a.xlarge"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "p3.2xlarge"
  preminer_volume_size        = 1200
  bootstrapper_volume_size    = 1000
  scratch_volume_size         = 1000
  toolshed_volume_size        = 1000
  bootstrapper_instance_type  = "m5a.xlarge"
  scratch_instance_type       = "m5a.xlarge"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[0]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[0]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[0]
}
