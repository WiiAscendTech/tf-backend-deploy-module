resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = var.path_patterns
    }
  }

  dynamic "condition" {
    for_each = var.host_headers != [] ? [1] : []
    content {
      host_header {
        values = var.host_headers
      }
    }
  }
}