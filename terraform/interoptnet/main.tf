variable "zone_id" {}
variable "chainwatch_password" {}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

locals {
  vault_password_file = "${path.module}/.vault_password"
  devices = ["/dev/xvdca", "/dev/xvdcb", "/dev/xvdcc", "/dev/xvdcd"]
  workers = 2
  swap = 1
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name                 = "interopnet"
  azs                  = data.aws_availability_zones.available.names
  cidr                 = var.cidr
  public_subnets       = var.public_subnets
  enable_dns_hostnames = true
}

module "chainwatch" {
  source = "../modules/chainwatch"

  instance_class         = "db.m5.xlarge"
  port                   = 5432
  password               = var.chainwatch_password
  vpc_security_group_ids = [aws_security_group.chainwatch.id]
  db_subnet_group_name   = aws_db_subnet_group.chainwatch.name
}

resource "aws_db_subnet_group" "chainwatch" {
  name       = "chainwatch"
  subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
}

resource "aws_security_group" "chainwatch" {
  name   = "interopnet_db"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "this" {
  name   = "interopnet"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1347
    to_port     = 1347
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_instance" "miner" {
  ami                         = "ami-003634241a8fcdec0"
  instance_type               = "m5.2xlarge"
  #instance_type               = "p3.2xlarge"
  key_name                    = "filecoin"
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 128
  }

  tags = {
    Name = "interopnet.t01000"
  }
}

resource "aws_instance" "peer" {
  ami                         = "ami-003634241a8fcdec0"
  instance_type               = "m5.2xlarge"
  #instance_type               = "p3.2xlarge"
  key_name                    = "filecoin"
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 128
  }

  tags = {
    Name = "interopnet.peer"
  }
}

resource "null_resource" "miner" {
  depends_on = [aws_instance.miner, aws_volume_attachment.miner, aws_route53_record.miner]

  connection {
    host = aws_instance.miner.public_ip
    user = "ubuntu"
  }

  triggers = {
    script_sha1 = "${sha1(file("${path.module}/../../ansible/aws_seeder.yml"))}"
  }

  provisioner "ansible" {
    plays {
      hosts = [
        "${aws_route53_record.miner.fqdn}",
      ]

      playbook {
        file_path = "${path.module}/../../ansible/aws_seeder.yml"
      }

      extra_vars = {
        ansible_user = "ubuntu"
        hostname     = aws_route53_record.miner.fqdn
        devices_id   = join(";", aws_volume_attachment.miner.*.volume_id)
        devices_name = join(";", aws_volume_attachment.miner.*.device_name)
        swap_id      = local.swap > 0 ? join("", aws_volume_attachment.swap.*.volume_id): ""
        swap_name    = local.swap > 0 ? join("", aws_volume_attachment.swap.*.device_name): ""
      }

      # shared attributes
      become        = true
      become_method = "sudo"
      enabled       = true
      vault_id      = [local.vault_password_file]
      groups        = ["seeder"]
    }
  }

  provisioner "remote-exec" {
      inline     = ["sudo shutdown -h now"]
      when       = destroy
      on_failure = continue
  }
}

resource "aws_ebs_volume" "swap" {
  count             = local.swap
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 4 * length(aws_ebs_volume.miner) + 4
  iops              = (4 * length(aws_ebs_volume.miner) + 4) * 50
  type              = "io1"

  tags = {
    Name = "interopnet.t01000swap"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "swap" {
  count        = local.swap
  device_name  = "/dev/xvds"
  volume_id    = aws_ebs_volume.swap[count.index].id
  instance_id  = aws_instance.miner.id
  force_detach = false
}

resource "aws_ebs_volume" "miner" {
  count             = local.workers
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 32
  type              = "gp2"

  tags = {
    Name = "interopnet.t01000.disk${count.index}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "miner" {
  count        = length(aws_ebs_volume.miner)
  device_name  = local.devices[count.index]
  volume_id    = aws_ebs_volume.miner[count.index].id
  instance_id  = aws_instance.miner.id
  force_detach = false
}

resource "aws_route53_record" "miner" {
  name    = "t01000.miner.interopnet"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.miner.public_ip}"]
  ttl     = 30
}

resource "aws_route53_record" "peer" {
  name    = "peer.interopnet"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.peer.public_ip}"]
  ttl     = 30
}

output "dns" {
  value = aws_route53_record.miner.fqdn
}

output "peer" {
  value = aws_route53_record.peer.fqdn
}
