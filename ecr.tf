resource "aws_ecr_repository" "this" {
  name                 = "wiiascend/${var.project_name}-${var.environment}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = merge(local.common_tags, {
    Name = "wiiascend/${var.project_name}-${var.environment}"
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.enable_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantém apenas as últimas ${var.max_image_count} imagens, exceto as tags protegidas."
        selection = {
          tagStatus     = "tagged"
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
          tagPrefixList = var.protected_tags
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
