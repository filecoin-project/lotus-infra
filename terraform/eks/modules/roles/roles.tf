data "aws_caller_identity" "current" {}

resource "aws_iam_role" "r" {
  for_each = var.aws_iam_roles
  name = each.key
  assume_role_policy = local.assume_role_policies["${each.key}"].json
}
