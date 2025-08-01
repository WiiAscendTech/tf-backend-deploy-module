resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-tg-${var.environment}"
  port        = var.port
  protocol    = var.protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-tg-${var.environment}"
  })
}