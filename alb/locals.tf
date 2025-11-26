locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  alb_name          = "${var.application}-alb-${var.environment}"
  alb_sg_name       = "${var.application}-alb-sg-${var.environment}"
  target_group_name = "${var.application}-tg-${var.environment}"
}

