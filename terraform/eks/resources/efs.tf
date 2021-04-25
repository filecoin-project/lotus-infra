resource "aws_security_group" "efs" {
  name        = "efs-${local.name}"
  description = "allow efs ingress"
  vpc_id      = module.vpc.vpc_id

  # NFS / EFS
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "TCP"
    cidr_blocks = [var.cidr]
  }
}

resource "aws_efs_file_system" "efs_filesystems" {
  for_each = var.efs_volumes
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, {
    Name = each
  })
}

resource "aws_efs_mount_target" "efs_mounts" {
  for_each        = var.efs_volumes
  count           = length(flatten([module.vpc.public_subnets]))
  file_system_id  = aws_efs_file_system.efs_filesystems[each].id
  subnet_id       = flatten([module.vpc.public_subnets])[count.index]
  security_groups = [aws_security_group.efs.id]
}
