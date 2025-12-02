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


resource "local_file" "adot_config" {
  content = templatefile("${path.module}/templates/adot-config.yaml.tpl", {
    region               = var.region
    assume_role_arn      = var.adot_sigv4_assume_role_arn != null ? var.adot_sigv4_assume_role_arn : aws_iam_role.remote_write.arn
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
