variable "instance_type" {}
variable "vault_password_file" {}
variable "vpc_security_group_ids" {}
variable "subnet_id" {}
variable "miner_addr" {}
variable "zone_id" {}
variable "worker0_ebs_volume_ids" {}
variable "worker1_ebs_volume_ids" {}
variable "worker2_ebs_volume_ids" {}
variable "worker3_ebs_volume_ids" {}
variable "worker4_ebs_volume_ids" {}

module "worker0" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  instance_type               = var.instance_type
  zone_id                     = var.zone_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker0_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  index                       = 0
}

module "worker1" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker1_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  index                       = 1
}

module "worker2" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker2_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  index                       = 2
}

module "worker3" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker3_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  index                       = 3
}

module "worker4" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker4_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  index                       = 4
}
