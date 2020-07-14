data "aws_subnet" "selected" {
  id = "${var.private_subnet_id}"
}

# an instance to run chainwatch, status, and faucet.
module "toolshed" {
  source                     = "../lotus_node"
  name                       = "toolshed"
  scale                      = 1
  instance_type              = var.toolshed_instance_type
  availability_zone          = data.aws_subnet.selected.availability_zone
  ami                        = var.ami
  zone_id                    = aws_route53_zone.subdomain.id
  key_name                   = var.key_name
  environment                = var.environment
  network_name               = var.name
  public_security_group_ids  = [aws_security_group.devnet_public.id]
  private_security_group_ids = [aws_security_group.devnet_private.id]
  private_subnet_id          = var.private_subnet_id
  public_subnet_id           = var.public_subnet_id
}

module "timescale" {
  source                     = "../lotus_node"
  name                       = "toolshed"
  scale                      = 1
  instance_type              = var.toolshed_instance_type
  availability_zone          = data.aws_subnet.selected.availability_zone
  ami                        = var.ami
  zone_id                    = aws_route53_zone.subdomain.id
  key_name                   = var.key_name
  environment                = var.environment
  network_name               = var.name
  public_security_group_ids  = [aws_security_group.devnet_public.id]
  private_security_group_ids = [aws_security_group.devnet_private.id]
  private_subnet_id          = var.private_subnet_id
  public_subnet_id           = var.public_subnet_id
}

# Nodes running in bootstrapper mode
module "bootstrappers" {
  source                     = "../lotus_node"
  name                       = "bootstrap"
  scale                      = var.bootstrapper_count
  instance_type              = var.bootstrapper_instance_type
  availability_zone          = data.aws_subnet.selected.availability_zone
  ami                        = var.ami
  zone_id                    = aws_route53_zone.subdomain.id
  key_name                   = var.key_name
  environment                = var.environment
  network_name               = var.name
  public_security_group_ids  = [aws_security_group.devnet_public.id]
  private_security_group_ids = [aws_security_group.devnet_private.id]
  private_subnet_id          = var.private_subnet_id
  public_subnet_id           = var.public_subnet_id
}

# Nodes running as pre-sealed miners
module "preminers" {
  source                     = "../lotus_node"
  name                       = "preminer"
  scale                      = var.preminer_count
  instance_type              = var.preminer_instance_type
  availability_zone          = data.aws_subnet.selected.availability_zone
  ami                        = var.ami
  iam_instance_profile       = var.preminer_iam_profile
  zone_id                    = aws_route53_zone.subdomain.id
  key_name                   = var.key_name
  environment                = var.environment
  network_name               = var.name
  public_security_group_ids  = [aws_security_group.devnet_public.id]
  private_security_group_ids = [aws_security_group.devnet_private.id]
  private_subnet_id          = var.private_subnet_id
  public_subnet_id           = var.public_subnet_id
}

# Nodes to mess around with
module "scratch" {
  source                     = "../lotus_node"
  name                       = "scratch"
  scale                      = var.scratch_count
  instance_type              = var.scratch_instance_type
  availability_zone          = data.aws_subnet.selected.availability_zone
  ami                        = var.ami
  zone_id                    = aws_route53_zone.subdomain.id
  key_name                   = var.key_name
  environment                = var.environment
  network_name               = var.name
  public_security_group_ids  = [aws_security_group.devnet_public.id]
  private_security_group_ids = [aws_security_group.devnet_private.id]
  private_subnet_id          = var.private_subnet_id
  public_subnet_id           = var.public_subnet_id
}
