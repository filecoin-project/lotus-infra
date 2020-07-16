# To add a new lotus network:
# 1. Append a new network to public_ and private_ subnets
# 2. Copy a lotus_network configuration stanza and edit appropriately
# 3. terraform apply
#
# Note: there has to be at least two "private" subnets, even if unused.

locals {
  domain_name     = "fildev.network"
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.2.0/24", "10.0.3.0/24", "10.0.255.0/24"]
  private_subnets = ["10.0.128.0/24", "10.0.129.0/24"]
  # https://docs.timescale.com/latest/getting-started/installation/ami/installation-ubuntu-ami
  timescale_amis = {
    "us-east-1"    = "ami-0952246bc3c8d007c",
    "us-east-2"    = "ami-024ec0ff068daa3e2",
    "us-west-1"    = "ami-01971bba46b1c3c2e",
    "us-west-2"    = "ami-086173e369b9bde27",
    "eu-central-1" = "ami-01f2afc3887ce7ebd",
    "eu-north-1"   = "ami-07efd0f3f150d06cd",
    "eu-west-1"    = "ami-093e1bd4ca398346c",
    "eu-west-2"    = "ami-0fbf217a02a1cfb9a",
    "eu-west-3"    = "ami-043becf8d949ba2b0"
  }
}

module "nerpanet" {
  source                      = "../../modules/devnet"
  name                        = "nerpa"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  bootstrapper_count          = 4
  preminer_count              = 3
  scratch_count               = 2
  toolshed_instance_type      = "m5a.large"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "m5a.2xlarge"
  bootstrapper_instance_type  = "m5a.large"
  scratch_instance_type       = "m5a.large"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[0]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[0]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[0]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[0]
  timescale_ami               = local.timescale_amis[providers.aw.region]
  timescale_instance_type     = "db.m5.large"
}

module "butterflynet" {
  source                      = "../../modules/devnet"
  name                        = "butterfly"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  bootstrapper_count          = 2
  preminer_count              = 2
  scratch_count               = 2
  toolshed_instance_type      = "m5a.large"
  chainwatch_db_instance_type = "db.m5.large"
  chainwatch_password         = var.nerpanet_chainwatch_password
  preminer_instance_type      = "m5a.2xlarge"
  bootstrapper_instance_type  = "m5a.large"
  scratch_instance_type       = "m5a.large"
  preminer_iam_profile        = aws_iam_instance_profile.sectors.id
  database_subnet_group       = module.fildev_network_vpc.database_subnet_group
  public_subnet_id            = module.fildev_network_vpc.public_subnets[1]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[1]
  private_subnet_id           = module.fildev_network_vpc.database_subnets[1]
  private_subnet_cidr         = module.fildev_network_vpc.database_subnets_cidr_blocks[1]
  timescale_ami               = local.timescale_amis[providers.aw.region]
  timescale_instance_type     = "db.m5.large"
}

module "seeding" {
  source                      = "../../modules/seeding"
  name                        = "seeding"
  zone_id                     = aws_route53_zone.fildev_domain.id
  ami                         = "ami-053bc2e89490c5ab7"
  key_name                    = "filecoin"
  vpc_id                      = module.fildev_network_vpc.vpc_id
  environment                 = "prod"
  presealer_count             = 6
  presealer_instance_type     = "c5.24xlarge"
  presealer_iam_profile       = aws_iam_instance_profile.presealer.id
  public_subnet_id            = module.fildev_network_vpc.public_subnets[2]
  public_subnet_cidr          = module.fildev_network_vpc.public_subnets_cidr_blocks[2]
}
