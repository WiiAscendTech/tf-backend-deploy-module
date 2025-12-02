
data "aws_iam_policy_document" "firelens_bucket_policy" {
  count = var.enable_firelens ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.firelens_logs[0].arn,
      "${aws_s3_bucket.firelens_logs[0].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_object" "fluent_bit_config" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id
  key    = var.s3_logs_config_key

  content = file("${path.module}/config/fluent-bit.conf")
  etag    = filemd5("${path.module}/config/fluent-bit.conf")
}

resource "aws_s3_bucket" "firelens_logs" {
  count         = var.enable_firelens ? 1 : 0
  bucket        = var.s3_logs_bucket_name
  force_destroy = var.s3_logs_force_destroy

  tags = merge(local.common_tags, {
    Name = var.s3_logs_bucket_name
  })
}

resource "aws_s3_bucket_versioning" "firelens_logs" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firelens_logs" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_logs_kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.s3_logs_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "firelens_logs" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "firelens_logs" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    filter {
      prefix = "${var.s3_logs_prefix}/"
    }

    dynamic "transition" {
      for_each = var.s3_logs_transition_to_ia_days != null ? [var.s3_logs_transition_to_ia_days] : []
      content {
        days          = transition.value
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "transition" {
      for_each = var.s3_logs_transition_to_glacier_days != null ? [var.s3_logs_transition_to_glacier_days] : []
      content {
        days          = transition.value
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.s3_logs_expiration_days != null ? [var.s3_logs_expiration_days] : []
      content {
        days = expiration.value
      }
    }
  }
}

resource "aws_s3_bucket_policy" "firelens_logs" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id
  policy = data.aws_iam_policy_document.firelens_bucket_policy[0].json
}

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
  name        = local.policy_name
  description = "Permite que a task ECS envie logs para o bucket S3 via FireLens"
  policy      = data.aws_iam_policy_document.firelens_task_role[0].json
}

resource "aws_iam_role_policy_attachment" "firelens_task_role" {
  count = var.enable_firelens ? 1 : 0

  role       = split("/", var.task_role_arn)[length(split("/", var.task_role_arn)) - 1]
  policy_arn = aws_iam_policy.firelens_task_role[0].arn
}
