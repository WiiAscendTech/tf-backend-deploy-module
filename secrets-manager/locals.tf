locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  final_name = var.name_override != null ? var.name_override : "${var.application}-${var.environment}"
}

