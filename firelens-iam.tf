data "aws_iam_policy_document" "firelens_task_role" {
  count = var.enable_firelens ? 1 : 0

  statement {
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.firelens_logs[0].arn]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${aws_s3_bucket.firelens_logs[0].arn}/${var.s3_logs_prefix}/*"]
  }

  dynamic "statement" {
    for_each = var.s3_logs_kms_key_arn != null ? [var.s3_logs_kms_key_arn] : []
    content {
      actions   = ["kms:Encrypt", "kms:GenerateDataKey", "kms:GenerateDataKeyWithoutPlaintext"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "firelens_task_role" {
  count       = var.enable_firelens ? 1 : 0
  name        = "${var.application}-${var.environment}-firelens-logs"
  description = "Permite que a task ECS envie logs para o bucket S3"
  policy      = data.aws_iam_policy_document.firelens_task_role[0].json
}

resource "aws_iam_role_policy_attachment" "firelens_task_role" {
  count      = var.enable_firelens ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.firelens_task_role[0].arn
}

data "aws_iam_policy_document" "firelens_execution_role" {
  count = var.enable_firelens && local.execution_role_name != null ? 1 : 0

  statement {
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.firelens_logs[0].arn]
  }

  statement {
    actions = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${aws_s3_bucket.firelens_logs[0].arn}/${var.s3_logs_config_key}"]
  }

  dynamic "statement" {
    for_each = var.s3_logs_kms_key_arn != null ? [var.s3_logs_kms_key_arn] : []
    content {
      actions   = ["kms:Decrypt"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "firelens_execution_role" {
  count       = var.enable_firelens && local.execution_role_name != null ? 1 : 0
  name        = "${var.application}-${var.environment}-firelens-config"
  description = "Permite que a execution role acesse a configuração do FireLens no S3"
  policy      = data.aws_iam_policy_document.firelens_execution_role[0].json
}

resource "aws_iam_role_policy_attachment" "firelens_execution_role" {
  count      = var.enable_firelens && local.execution_role_name != null ? 1 : 0
  role       = local.execution_role_name
  policy_arn = aws_iam_policy.firelens_execution_role[0].arn
}
