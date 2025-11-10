data "aws_partition" "current" {}

resource "aws_lb_target_group" "this" {
  name        = "${var.application}-tg-${var.environment}"
  target_type = var.target_type
  vpc_id      = var.target_type == "lambda" ? null : var.vpc_id

  port     = var.target_type == "lambda" ? null : var.port
  protocol = var.target_type == "lambda" ? null : var.protocol

  connection_termination = try(var.tg_advanced.connection_termination, null)
  deregistration_delay   = try(var.tg_advanced.deregistration_delay, null)
  slow_start             = try(var.tg_advanced.slow_start, null)
  proxy_protocol_v2      = try(var.tg_advanced.proxy_protocol_v2, null)
  load_balancing_algorithm_type     = try(var.tg_advanced.load_balancing_algorithm_type, null)
  load_balancing_cross_zone_enabled = try(var.tg_advanced.load_balancing_cross_zone_enabled, null)
  protocol_version = try(var.tg_advanced.protocol_version, var.protocol_version, null)
  ip_address_type  = try(var.tg_advanced.ip_address_type, null)
  preserve_client_ip = try(var.tg_advanced.preserve_client_ip, null)

  dynamic "stickiness" {
    for_each = var.tg_advanced != null && var.tg_advanced.stickiness != null ? [var.tg_advanced.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = try(stickiness.value.cookie_duration, null)
      cookie_name     = try(stickiness.value.cookie_name, null)
    }
  }

  dynamic "health_check" {
    for_each = var.target_type == "lambda" ? [] : [1]
    content {
      path                = var.health_check_path
      interval            = var.health_check_interval
      timeout             = var.health_check_timeout
      healthy_threshold   = var.health_check_healthy_threshold
      unhealthy_threshold = var.health_check_unhealthy_threshold
      matcher             = var.health_check_matcher
      protocol            = var.protocol
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application}-tg-${var.environment}"
      "app" = var.application
      "env" = var.environment
    }
  )
}

resource "aws_lb_target_group_attachment" "lambda" {
  count = var.target_type == "lambda" && var.lambda_function_arn != null ? 1 : 0

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.lambda_function_arn
}

locals {
  _lambda_fn_name = var.lambda_function_arn != null ? element(split(":", var.lambda_function_arn), 6) : null
}

resource "aws_lambda_permission" "lb_invoke" {
  count = var.target_type == "lambda" && var.lambda_function_arn != null && var.lambda_attach_permission ? 1 : 0

  function_name = local._lambda_fn_name
  action        = "lambda:InvokeFunction"
  principal     = "elasticloadbalancing.${data.aws_partition.current.dns_suffix}"
  statement_id  = "AllowExecutionFromALB"
  source_arn    = aws_lb_target_group.this.arn
}

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
    for_each = length(var.host_headers) > 0 ? [1] : []
    content {
      host_header {
        values = var.host_headers
      }
    }
  }

  tags = merge(var.tags, {
    "app" = var.application
    "env" = var.environment
  })
}


