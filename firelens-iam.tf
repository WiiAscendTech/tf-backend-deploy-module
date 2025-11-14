data "aws_iam_policy_document" "firelens_task_role" {
  count = var.enable_firelens ? 1 : 0

  # Permissão pra router listar o bucket
  statement {
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.firelens_logs[0].arn]
  }

  # Permissão pra escrever objetos de log no prefixo
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${aws_s3_bucket.firelens_logs[0].arn}/*"]
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
  description = "Permite que a task ECS envie logs para o bucket S3 via FireLens"
  policy      = data.aws_iam_policy_document.firelens_task_role[0].json
}

resource "aws_iam_role_policy_attachment" "firelens_task_role" {
  count      = var.enable_firelens ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.firelens_task_role[0].arn
}
