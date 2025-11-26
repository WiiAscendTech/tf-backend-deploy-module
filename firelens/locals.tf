locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  policy_name = "${var.application}-${var.environment}-firelens-logs"
}

