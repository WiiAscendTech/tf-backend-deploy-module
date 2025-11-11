resource "aws_s3_bucket" "firelens_logs" {
  count        = var.enable_firelens ? 1 : 0
  bucket       = var.s3_logs_bucket_name
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

resource "aws_s3_bucket_policy" "firelens_logs" {
  count  = var.enable_firelens ? 1 : 0
  bucket = aws_s3_bucket.firelens_logs[0].id
  policy = data.aws_iam_policy_document.firelens_bucket_policy[0].json
}

resource "local_file" "firelens_config" {
  count    = var.enable_firelens ? 1 : 0
  content  = templatefile("${path.module}/templates/firelens-fluent-bit.conf.tpl", {
    bucket_name     = var.s3_logs_bucket_name
    region          = var.region
    total_file_size = var.fluent_total_file_size
    upload_timeout  = var.fluent_upload_timeout
    compression     = var.fluent_compression
    s3_prefix       = var.s3_logs_prefix
    application     = var.application
    environment     = var.environment
    storage_class   = var.s3_logs_storage_class
  })
  filename = "${path.module}/firelens-fluent-bit.conf"
}

resource "aws_s3_object" "firelens_config" {
  count        = var.enable_firelens ? 1 : 0
  bucket       = aws_s3_bucket.firelens_logs[0].id
  key          = var.s3_logs_config_key
  content      = local_file.firelens_config[0].content
  content_type = "text/plain"
}
