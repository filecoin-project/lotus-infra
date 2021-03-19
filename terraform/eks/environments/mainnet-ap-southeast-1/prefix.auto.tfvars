prefix = "mainnet-ap-southeast-1"
region = "ap-southeast-1"
external_dns_zone_id = "Z01768682VOLIPME8TKJO"
external_dns_fqdn = "filops.net"
key_name = "filecoin-mainnet"
azs = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

kubeconfig_aws_authenticator_env_variables = {
  AWS_PROFILE = "mainnet"
}
aws_profile = "mainnet"
