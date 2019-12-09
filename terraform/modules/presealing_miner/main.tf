variable "instance_type" {}
variable "lotus_seed_miner_addr" {}
variable "ebs_volume_id" {}
variable "zone_id" {}
variable "vpc_security_group_ids" {}
variable "subnet_id" {}

resource "aws_instance" "miner" {
  ami                         = "ami-01caa26d7860f2195"
  instance_type               = var.instance_type
  key_name                    = "filecoin"
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = 512
  }

  tags = {
    Name = "LPM - ${var.lotus_seed_miner_addr}"
  }
}

variable "device_names" {
  default = ["/dev/sdf","/dev/sdg","/dev/sdh","/dev/sdi","/dev/sdj","/dev/sdk","/dev/sdl"]
}

resource "aws_ebs_volume" "merge" {
  availability_zone = var.ebs_volume_id[0].availability_zone
  size              = 5000
  type              = "gp2"

  tags = {
    Name = "${var.lotus_seed_miner_addr} merge"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "merge" {
  device_name  = "/dev/sde"
  volume_id    = aws_ebs_volume.merge.id
  instance_id  = aws_instance.miner.id
  force_detach = false
}


resource "aws_ebs_volume" "repos" {
  availability_zone = var.ebs_volume_id[0].availability_zone
  size              = 5000
  type              = "gp2"

  tags = {
    Name = "${var.lotus_seed_miner_addr} repos"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "repos" {
  device_name  = "/dev/sdd"
  volume_id    = aws_ebs_volume.repos.id
  instance_id  = aws_instance.miner.id
  force_detach = false
}

resource "aws_volume_attachment" "this" {
  count        = length(var.ebs_volume_id)
  device_name  = var.device_names[count.index]
  volume_id    = var.ebs_volume_id[count.index].id
  instance_id  = aws_instance.miner.id
  force_detach = false
}

resource "aws_route53_record" "dns" {
  name    = "${var.lotus_seed_miner_addr}.miner"
  zone_id = var.zone_id
  type    = "A"
  records = ["${aws_instance.miner.public_ip}"]
  ttl     = 30
}

output "dns_name" {
  value = aws_route53_record.dns.fqdn
}
