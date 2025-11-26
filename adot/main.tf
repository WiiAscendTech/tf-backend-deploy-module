data "aws_caller_identity" "current" {}

resource "aws_iam_role" "remote_write" {
  name = local.remote_write_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.assume_role_principals
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.remote_write_role_name
  })
}

resource "aws_iam_policy" "remote_write" {
  name        = local.remote_write_policy_name
  description = "Permite que o ADOT faça remote write no AMP"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = local.remote_write_resources
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.remote_write_policy_name
  })
}

resource "aws_iam_role_policy_attachment" "remote_write" {
  role       = aws_iam_role.remote_write.name
  policy_arn = aws_iam_policy.remote_write.arn
}

data "aws_iam_policy_document" "remote_write_assume_role" {
  count = var.task_role_arn != null ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      aws_iam_role.remote_write.arn
    ]
  }
}

resource "aws_iam_policy" "remote_write_assume_role" {
  count       = var.task_role_arn != null ? 1 : 0
  name        = "${local.remote_write_role_name}-assume"
  description = "Permite que a task ECS assuma a role de remote write do ADOT"

  policy = data.aws_iam_policy_document.remote_write_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${local.remote_write_role_name}-assume"
  })
}

resource "aws_iam_role_policy_attachment" "remote_write_assume_role" {
  count = var.task_role_arn != null ? 1 : 0

  # 'role' espera o NOME da role, então extraímos do ARN
  role       = split("/", var.task_role_arn)[length(split("/", var.task_role_arn)) - 1]
  policy_arn = aws_iam_policy.remote_write_assume_role[0].arn
}

resource "local_file" "adot_config" {
  content = templatefile("${path.module}/templates/adot-config.yaml.tpl", {
    region               = var.region
    assume_role_arn      = aws_iam_role.remote_write.arn
    amp_remote_write_url = var.amp_remote_write_url
    enable_metrics       = var.enable_metrics
    project_name         = var.application
    environment          = var.environment
  })
  filename = "${path.module}/collector.yaml"
}

data "local_file" "adot_config_content" {
  filename = local_file.adot_config.filename
}
