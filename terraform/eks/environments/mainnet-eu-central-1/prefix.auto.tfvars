prefix = "mainnet-eu-central-1"
region = "eu-central-1"
external_dns_zone_id = "Z01768682VOLIPME8TKJO"
external_dns_fqdn = "filops.net"
key_name = "filecoin-mainnet"
# azs = ["eu-central-1c", "eu-central-1a", "eu-central-1a"]
azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

kubeconfig_aws_authenticator_env_variables = {
  AWS_PROFILE = "mainnet"
}
aws_profile = "mainnet"
