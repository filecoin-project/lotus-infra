prefix = "mainnet-us-east-1"
region = "us-east-1"
external_dns_zone_id = "Z01768682VOLIPME8TKJO"
external_dns_fqdn = "filops.net"
key_name = "filecoin-mainnet"
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

kubeconfig_aws_authenticator_env_variables = {
  AWS_PROFILE = "mainnet"
}
aws_profile = "mainnet"
