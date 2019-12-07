resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.default.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "public_route_assoc" {
  count  = length(data.aws_availability_zones.available.names)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "seed" {
  name        = "sg_seed"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

data "aws_route53_zone" "default" {
  zone_id = "${var.zone_id}"
}

module "seedm0" {
  source = "../modules/seeder"

  instance_count         = length(aws_ebs_volume.seedm0)
  instance_type          = "c5.24xlarge"
  lotus_seed_miner_addr  = "t0111"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file    = "${path.module}/.vault_password"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.seed.id]
  zone_id                = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size = var.lotus_seed_sector_size
  lotus_seed_num_sectors = var.lotus_seed_num_sectors
  lotus_seed_copy_binary = var.lotus_seed_copy_binary
  lotus_seed_reset_repo  = var.lotus_seed_reset_repo
  lotus_seed_binary_src  = var.lotus_seed_binary_src
  ebs_volume_id          = aws_ebs_volume.seedm0
}

resource "aws_ebs_volume" "seedm0" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}


module "seedm1" {
  source = "../modules/seeder"

  instance_count         = length(aws_ebs_volume.seedm0)
  instance_type          = "c5.24xlarge"
  lotus_seed_miner_addr  = "t0222"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file    = "${path.module}/.vault_password"
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.seed.id]
  zone_id                = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size = var.lotus_seed_sector_size
  lotus_seed_num_sectors = var.lotus_seed_num_sectors
  lotus_seed_copy_binary = var.lotus_seed_copy_binary
  lotus_seed_reset_repo  = var.lotus_seed_reset_repo
  lotus_seed_binary_src  = var.lotus_seed_binary_src
  ebs_volume_id          = aws_ebs_volume.seedm1
}

resource "aws_ebs_volume" "seedm1" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}


module "seedm2" {
  source = "../modules/seeder"

  instance_count         = length(aws_ebs_volume.seedm0)
  instance_type          = "c5.24xlarge"
  lotus_seed_miner_addr  = "t0333"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file    = "${path.module}/.vault_password"
  subnet_id              = aws_subnet.public[2].id
  vpc_security_group_ids = [aws_security_group.seed.id]
  zone_id                = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size = var.lotus_seed_sector_size
  lotus_seed_num_sectors = var.lotus_seed_num_sectors
  lotus_seed_copy_binary = var.lotus_seed_copy_binary
  lotus_seed_reset_repo  = var.lotus_seed_reset_repo
  lotus_seed_binary_src  = var.lotus_seed_binary_src
  ebs_volume_id          = aws_ebs_volume.seedm2
}

resource "aws_ebs_volume" "seedm2" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[2]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}

module "seedm3" {
  source = "../modules/seeder"

  instance_count         = length(aws_ebs_volume.seedm0)
  instance_type          = "c5.24xlarge"
  lotus_seed_miner_addr  = "t0444"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file    = "${path.module}/.vault_password"
  subnet_id              = aws_subnet.public[3].id
  vpc_security_group_ids = [aws_security_group.seed.id]
  zone_id                = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size = var.lotus_seed_sector_size
  lotus_seed_num_sectors = var.lotus_seed_num_sectors
  lotus_seed_copy_binary = var.lotus_seed_copy_binary
  lotus_seed_reset_repo  = var.lotus_seed_reset_repo
  lotus_seed_binary_src  = var.lotus_seed_binary_src
  ebs_volume_id          = aws_ebs_volume.seedm3
}

resource "aws_ebs_volume" "seedm3" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[3]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}

module "seedm4" {
  source = "../modules/seeder"

  instance_count         = length(aws_ebs_volume.seedm0)
  instance_type          = "c5.24xlarge"
  lotus_seed_miner_addr  = "t0555"
  lotus_seed_sector_offset = var.lotus_seed_sector_offset
  vault_password_file    = "${path.module}/.vault_password"
  subnet_id              = aws_subnet.public[4].id
  vpc_security_group_ids = [aws_security_group.seed.id]
  zone_id                = data.aws_route53_zone.default.zone_id
  lotus_seed_sector_size = var.lotus_seed_sector_size
  lotus_seed_num_sectors = var.lotus_seed_num_sectors
  lotus_seed_copy_binary = var.lotus_seed_copy_binary
  lotus_seed_reset_repo  = var.lotus_seed_reset_repo
  lotus_seed_binary_src  = var.lotus_seed_binary_src
  ebs_volume_id          = aws_ebs_volume.seedm4
}

resource "aws_ebs_volume" "seedm4" {
  count             = length(var.lotus_seed_sector_offset)
  availability_zone = data.aws_availability_zones.available.names[4]
  size              = 5000
  type              = "gp2"

  lifecycle {
    prevent_destroy = false
  }
}
