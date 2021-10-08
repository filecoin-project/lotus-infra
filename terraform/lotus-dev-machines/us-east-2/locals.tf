## Manage machines here
#
#  FIELDS
#  [string] github_username - REQUIRED this user's SSH keys on github will be fetched
#  [string] ec2_type - OPTIONAL ec2 type to use. DEFAULT "t3.micro"
#  [integer] volume_size - OPTIONAL root disk volume size in GiB - DEFAULT 2000

locals {
  machines = [
    {
      github_username = "ognots"
    },
    {
      github_username = "stongo"
    },
  ]
}
