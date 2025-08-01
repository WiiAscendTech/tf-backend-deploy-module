resource "aws_iam_role" "this" {
  name               = "${var.project_name}-${var.role_name}-${var.environment}"
  description        = var.role_description
  assume_role_policy = var.assume_role_policy_json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.role_name}-${var.environment}"
  })
}

resource "aws_iam_policy" "this" {
  count       = var.policy_json != null ? 1 : 0
  name        = "${var.project_name}-${var.policy_name}-${var.environment}"
  description = var.policy_description
  policy      = var.policy_json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.policy_name}-${var.environment}"
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.policy_json != null ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}