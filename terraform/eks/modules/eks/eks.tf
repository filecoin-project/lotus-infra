data "aws_caller_identity" "current" {}

resource "aws_key_pair" "filecoin-mainnet" {
  key_name   = "filecoin-mainnet"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMMuR4/FOOyVg/WaFO7h1vAAcjhO61ypTND4Y363Nyho32FeEiIcp70u7JpkWBqdyZ9vs38CSmFUC2uqTfphdD9fY+GNQfwPhAvOJodPGg3eH+5rjUd9BAiCPvRmqSR9GoCndfp/8+dAMCMnLImFKGASk34eHBr/NYtPZD50a/3DYArXdso2XR77O3y9xKLzroqcM9yOWbw6QkgoE/jxxDByFI0ZV/dJCgGFmtKFR1SXP0LCkAsmvrcli5gpLlk8MXOgQstFolzlgqbEp6O3Aywq5gEf1sJcmul2yY5WsKeWjSQT1jd/K3C5Qlfl5zBj6J7XeI08FGDhtUbhDqnDS6QwsUjDL3qRoWsgGrIZ0vRiVUDiDkC7pMIRb0ZJIvMeduVJIMRmyaF/+L9wdg+GCA9Occb36ZJe0v+9nCGQeRS6F1PVUN8VnjcqVjLeN/9w9RH1DuaenPwd+M3hTIbA5o9G3imU8wjakVOn17ahrUu/k+if/6v/anaKvMfwIQPQa8do7Y7g9u8TF3xDqWGB/6dNA/sUafqzVDPDdVPFmsw9ZxKhgKpxnF8FTFaE9IOXU7Abh40iuejQkgSSq+XEnckFmr7VTcxWkvw/tr9S8W25OUISlh3hwtCru27SBJh9tnu1+WakXjHBIR2I6MPbIXv1Eg2hCB1bbYuy+mWuMy3Q== infra-accounts+filecoin-mainnet@protocol.ai"
}


resource "aws_security_group" "lotus" {
  name        = "go-ipfs-${local.name}"
  description = "allow go-filecoin ingress"
  vpc_id      = var.vpc_id

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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "13.0.0"

  cluster_name                               = local.name
  cluster_version                            = var.k8s_version
  vpc_id                                     = var.vpc_id
  subnets                                    = flatten([var.public_subnets])
  tags                                       = local.tags
  map_users                                  = local.map_users
  map_roles                                  = local.map_roles
  kubeconfig_aws_authenticator_env_variables = var.kubeconfig_aws_authenticator_env_variables
  #kubeconfig_aws_authenticator_command       = "/usr/local/bin/aws eks --region ${var.region} update-kubeconfig --name ${local.name}"
  config_output_path                   = local.config_path
  worker_additional_security_group_ids = concat(var.security_group_ids, [aws_security_group.lotus.id])

  cluster_enabled_log_types = ["audit"]

  workers_additional_policies = [
    aws_iam_policy.external_dns.arn,
    aws_iam_policy.ebs_cni.arn,
    aws_iam_policy.elb_controller.arn,
  ]

  node_groups = var.node_groups
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "v2.11.0"

  domain_name = "${var.prefix}.${var.external_dns_fqdn}"
  zone_id     = var.external_dns_zone_id

  subject_alternative_names = [
    "*.${var.prefix}.${var.external_dns_fqdn}",
  ]

  tags = {
    Name = "${var.prefix}.${var.external_dns_fqdn}"
  }
}

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

resource "aws_iam_policy" "elb_controller" {
  name = "elb-controller-${local.name}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
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
    script_sha1 = sha1(file("${path.module}/files/postinstall.sh"))
  }

  provisioner "local-exec" {
    command = <<-EOT
    ${path.module}/files/postinstall.sh "${var.aws_profile}" "${var.k8s_version}" "${local.name}" "${var.region}" "${var.external_dns_fqdn}"
    EOT
    environment = {
      KUBECONFIG = "${local.kubeconfig_path}"
    }
  }
}
