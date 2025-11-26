resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0
  name  = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })
}

resource "aws_iam_role" "execution" {
  count = var.execution_role_arn == null ? 1 : 0
  name  = local.execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.execution_role_name
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  count      = var.execution_role_arn == null ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = var.task_role_arn == null ? 1 : 0
  name  = local.task_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.task_role_name
  })
}

resource "aws_iam_policy" "task_custom" {
  count       = var.task_role_arn == null && var.task_role_policy_json != null ? 1 : 0
  name        = local.task_policy_name
  description = "Política customizada para a task ECS ${var.application}"
  policy      = var.task_role_policy_json

  tags = merge(local.common_tags, {
    Name = local.task_policy_name
  })
}

resource "aws_iam_role_policy_attachment" "task_custom" {
  count      = var.task_role_arn == null && var.task_role_policy_json != null ? 1 : 0
  role       = aws_iam_role.task[0].name
  policy_arn = aws_iam_policy.task_custom[0].arn
}

resource "aws_iam_role_policy_attachment" "task_managed" {
  for_each   = var.task_role_arn == null ? toset(var.task_role_managed_policy_arns) : []
  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_ecs_service" "this" {
  name            = local.service_name
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy != null ? var.capacity_provider_strategy : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = var.assign_public_ip
  }

  enable_execute_command = true

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.application
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(local.common_tags, {
    Name = local.service_name
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.task_definition_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn != null ? var.execution_role_arn : aws_iam_role.execution[0].arn
  task_role_arn            = var.task_role_arn != null ? var.task_role_arn : aws_iam_role.task[0].arn

  container_definitions = jsonencode(local.ecs_task_containers)

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

  tags = merge(local.common_tags, {
    Name = local.task_definition_name
  })
}

resource "aws_appautoscaling_target" "this" {
  count = var.enable_autoscaling ? 1 : 0

  min_capacity = var.autoscaling_min_capacity
  max_capacity = var.autoscaling_max_capacity

  resource_id = "service/${local.cluster_name}/${aws_ecs_service.this.name}"

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_scaling" {
  count = var.enable_autoscaling && var.autoscaling_cpu_target_value != null ? 1 : 0

  name               = "${aws_ecs_service.this.name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling_cpu_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "requests_scaling" {
  count = var.enable_autoscaling && var.autoscaling_requests_target_value != null ? 1 : 0

  name               = "${aws_ecs_service.this.name}-requests-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling_requests_target_value

    customized_metric_specification {
      metric_name = "RequestCountPerTarget"
      namespace   = "AWS/ApplicationELB"
      statistic   = "Sum"
      unit        = "Count"

      dimensions {
        name  = "TargetGroup"
        value = split(":", var.alb_target_group_arn)[5]
      }

      dimensions {
        name  = "LoadBalancer"
        value = var.load_balancer_arn_suffix
      }
    }

    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = local.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = local.cloudwatch_log_group_name
  })
}

resource "aws_security_group" "ecs_sg" {
  name        = local.security_group_name
  description = "Security Group para o ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = concat([var.alb_sg_id], var.allowed_sg_ids)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })
}
