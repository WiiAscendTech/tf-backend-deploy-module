resource "aws_security_group" "alb" {
  count       = var.create_alb ? 1 : 0
  name        = local.alb_sg_name
  description = "Security group for ${local.alb_name} Application Load Balancer"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      vpc_id
    ]
  }

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_internal ? var.allowed_cidr_blocks : ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.alb_internal ? var.allowed_cidr_blocks : ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.alb_sg_name
  })
}

data "aws_lb" "existing" {
  count = var.create_alb ? 0 : 1
  name  = local.alb_name
}

resource "aws_lb" "this" {
  count              = var.create_alb ? 1 : 0
  name               = local.alb_name
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      security_groups,
      subnets
    ]
  }

  tags = merge(local.common_tags, {
    Name = local.alb_name
  })
}

resource "aws_lb_listener" "http" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https && var.https_redirect ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https && var.https_redirect ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.create_alb && var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener_rule" "this" {
  count        = var.create_alb || var.listener_arn == null ? 0 : 1
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  dynamic "condition" {
    for_each = var.path_patterns != [] ? [1] : []
    content {
      path_pattern {
        values = var.path_patterns
      }
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

locals {
  target_group_vpc_id = var.create_alb ? var.vpc_id : (length(data.aws_lb.existing) > 0 ? data.aws_lb.existing[0].vpc_id : var.vpc_id)
}

resource "aws_lb_target_group" "this" {
  name        = local.target_group_name
  port        = var.port
  protocol    = var.protocol
  vpc_id      = local.target_group_vpc_id
  target_type = var.target_type

  health_check {
    enabled             = var.health_check_enabled
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
    protocol            = var.health_check_protocol
    port                = var.health_check_port != null ? var.health_check_port : "traffic-port"
  }

  deregistration_delay = var.deregistration_delay
  slow_start           = var.slow_start

  stickiness {
    enabled         = var.enable_stickiness
    type            = var.stickiness_type
    cookie_duration = var.cookie_duration
  }

  tags = merge(local.common_tags, {
    Name = local.target_group_name
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name
    ]
  }
}