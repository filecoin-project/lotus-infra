data "aws_subnet" "selected" {
  id = "${var.public_subnet_id}"
}

module "presealers" {
  source                     = "../presealer"
  name                       = "presealer"
  scale                      = var.presealer_count
  instance_type              = var.presealer_instance_type
  availability_zone          = data.aws_subnet.selected.availability_zone
  ami                        = var.ami
  iam_instance_profile       = var.presealer_iam_profile
  zone_id                    = aws_route53_zone.subdomain.id
  key_name                   = var.key_name
  environment                = var.environment
  group                      = var.name
  volume_size                = var.volume_size
  public_security_group_ids  = [aws_security_group.public.id]
  public_subnet_id           = var.public_subnet_id
}
