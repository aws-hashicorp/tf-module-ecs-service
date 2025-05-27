data "aws_iam_policy" "role_permissions_data" {
  count = length(var.permissions_name)
  name  = var.permissions_name[count.index]
}
