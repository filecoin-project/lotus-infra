data "aws_caller_identity" "current" {}

resource "aws_security_group" "lotus" {
  name        = "go-ipfs-${local.name}"
  description = "allow go-filecoin ingress"
  vpc_id      = module.vpc.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Swarm
  ingress {
    from_port   = 15432
    to_port     = 15432
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "external_dns" {
  template = "${file("../../resources/templates/external-dns.yml")}"

  vars = {
    name   = local.name
    domain = var.external_dns_fqdn
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "13.0.0"

  cluster_name    = local.name
  cluster_version = var.k8s_version
  vpc_id          = module.vpc.vpc_id
  subnets         = flatten([module.vpc.public_subnets])
  tags            = local.tags
  map_users       = local.map_users
  #map_users_count                            = length(local.map_users)
  kubeconfig_aws_authenticator_env_variables = var.kubeconfig_aws_authenticator_env_variables
  config_output_path                         = local.config_path
  worker_additional_security_group_ids       = [aws_security_group.lotus.id, aws_security_group.efs.id]

  workers_additional_policies = [
    aws_iam_policy.external_dns.arn,
    aws_iam_policy.ebs_cni.arn,
  ]

  node_groups = [
    {
      instance_type = "c5.4xlarge"
      key_name      = var.key_name
      # additional_userdata  = "aws s3 cp s3://filecoin-proof-parameters /opt/filecoin-proof-parameters --region us-east-1 --recursive --no-sign-request"
      desired_capacity = var.worker_count_open
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "open"
      }
    },
    {
      instance_type = "c5.4xlarge"
      key_name      = var.key_name
      # additional_userdata  = "aws s3 cp s3://filecoin-proof-parameters /opt/filecoin-proof-parameters --region us-east-1 --recursive --no-sign-request"
      desired_capacity = var.worker_count_restricted
      min_capacity     = "3"
      max_capacity     = "50"
      k8s_labels = {
        mode = "restricted"
      }
    },
  ]
}

/*
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "v2.11.0"

  domain_name = var.external_dns_fqdn
  zone_id     = var.external_dns_zone_id

  subject_alternative_names = [
    "*.${var.external_dns_fqdn}",
  ]

  tags = {
    Name = var.external_dns_fqdn
  }
}
*/

resource "aws_iam_policy" "external_dns" {
  name = "external-dns-${local.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/${var.external_dns_zone_id}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "ebs_cni" {
  name = "ebs-cni-${local.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications",
        "ec2:DetachVolume",
        "ec2:ModifyVolume"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "null_resource" "k8s_config" {
  triggers = {
    worker_asgs = join(",", module.eks.workers_asg_arns)
    script_sha1 = sha1(file("${path.module}/../extra/postinstall.sh"))
  }

  provisioner "local-exec" {
    command = <<-EOT
    echo '${data.template_file.external_dns.rendered}' > /tmp/external-dns.yml
    ../../extra/postinstall.sh "${var.aws_profile}" "${var.k8s_version}"
    EOT

    environment = {
      KUBECONFIG = "${local.kubeconfig_path}"
    }
  }
}
