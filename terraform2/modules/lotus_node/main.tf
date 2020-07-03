locals {
  devices = ["xvdca", "xvdcb", "xvdcc", "xvdcd", "xvdce",
    "xvdcf", "xvdcg", "xvdch", "xvdci", "xvdcj",
    "xvdck", "xvdcl", "xvdcm", "xvdcn", "xvdco",
    "xvdcp", "xvdcq", "xvdcr", "xvdcs", "xvdct",
    "xvdcu", "xvdcv", "xvdcw", "xvdcx", "xvdcy",
  "xvdcz"]
}

resource "aws_instance" "node" {
  count             = var.scale
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  ami               = var.ami
  key_name          = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  associate_public_ip_address = true
  tags = {
    Name        = "${var.name}-${count.index}"
    Environment = var.environment
    Network     = var.lotus_network
  }
  network_interface {
    network_interface_id = aws_network_interface.ethprivate.id
    device_index = 0
  }
}

resource "aws_network_interface" "ethprivate" {
  subnet_id = var.private_subnet_id
}

resource "aws_route53_record" "node" {
  count   = var.scale
  name    = "${var.name}-${count.index}"
  zone_id = var.zone_id
  type    = "A"
  records = [aws_instance.node[count.index].public_ip]
  ttl     = 30
}

resource "aws_ebs_volume" "volumes" {
  count             = var.volumes * var.scale
  availability_zone = var.availability_zone
  size              = 32
  type              = "gp2"
  tags = {
    Name        = "${var.lotus_network}.disk-${count.index}"
    Environment = var.environment
    Network     = var.lotus_network
  }
}

resource "aws_volume_attachment" "attachments" {
  count       = var.volumes * var.scale
  device_name = "/dev/${local.devices[floor(count.index / var.scale)]}"
  instance_id = aws_instance.node[count.index % var.scale].id
  volume_id   = aws_ebs_volume.volumes[count.index].id
}
