variable "instance_type" {}
variable "availability_zone" {}
variable "ami" {}
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
variable "worker5_ebs_volume_ids" {}

module "worker0" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  instance_type               = var.instance_type
  ami                         = var.ami
  zone_id                     = var.zone_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker0_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  availability_zone           = var.availability_zone
  index                       = 0
  swap_enabled                = true
}

module "worker1" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  ami                         = var.ami
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker1_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  availability_zone           = var.availability_zone
  index                       = 1
  swap_enabled                = true
}

module "worker2" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  ami                         = var.ami
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker2_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  availability_zone           = var.availability_zone
  index                       = 2
  swap_enabled                = true
}

module "worker3" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  ami                         = var.ami
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker3_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  availability_zone           = var.availability_zone
  index                       = 3
  swap_enabled                = true
}

module "worker4" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  ami                         = var.ami
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker4_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  availability_zone           = var.availability_zone
  index                       = 4
  swap_enabled                = true
}

module "worker5" {
  source = "../seeder"

  miner_addr                  = var.miner_addr
  zone_id                     = var.zone_id
  instance_type               = var.instance_type
  ami                         = var.ami
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  ebs_volume_ids              = var.worker5_ebs_volume_ids
  vault_password_file         = var.vault_password_file
  availability_zone           = var.availability_zone
  index                       = 5
  swap_enabled                = true
}
