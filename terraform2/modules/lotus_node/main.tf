resource "aws_instance" "node" {
  count                       = var.scale
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  ami                         = var.ami
  key_name                    = var.key_name
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = var.iam_instance_profile
  vpc_security_group_ids      = var.public_security_group_ids
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 128
  }

  tags = {
    Name        = "${var.name}-${count.index}"
    Environment = var.environment
    Network     = var.network_name
  }
}

resource "aws_route53_record" "node" {
  count   = var.scale
  name    = "${var.name}-${count.index}"
  zone_id = var.zone_id
  type    = "A"
  records = [aws_instance.node[count.index].public_ip]
  ttl     = 30
}

resource "aws_network_interface" "private" {
  count           = var.scale
  subnet_id       = var.private_subnet_id
  security_groups = var.private_security_group_ids

  attachment {
    instance     = aws_instance.node[count.index].id
    device_index = 1
  }
}
