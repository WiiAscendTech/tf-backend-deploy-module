resource "aws_ecs_service" "this" {
  name            = "${var.application}-ecs-service-${var.environment}"
  cluster         = var.cluster_id
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
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.application
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(local.common_tags, {
    Name = "${var.application}-ecs-service-${var.environment}"
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.application}-td-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = aws_iam_role.this.arn

  container_definitions = jsonencode([
    {
      name             = var.application,
      image            = "${aws_ecr_repository.this.repository_url}:latest",
      cpu              = var.container_cpu,
      memory           = var.container_memory,
      essential        = true,
      portMappings     = [
        {
          containerPort = var.container_port,
          hostPort      = var.container_port,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.log_group
          awslogs-region        = var.region
          awslogs-stream-prefix = var.application
        }
      },
      environment = var.ecs_environment_variables,
      secrets     = var.ecs_secrets,
    },
    local.adot_container_definition
  ])

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.application}-td-${var.environment}"
  })
}

resource "aws_appautoscaling_target" "this" {
  count = var.enable_autoscaling ? 1 : 0

  min_capacity = var.autoscaling_min_capacity
  max_capacity = var.autoscaling_max_capacity

  resource_id = "service/${var.cluster_name}/${aws_ecs_service.this.name}"


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
        value = split(":", aws_lb_target_group.this.arn)[5]
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

resource "aws_security_group" "ecs_sg" {
  name        = "${var.application}-ecs-sg-${var.environment}"
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
    Name = "${var.application}-ecs-sg-${var.environment}"
  })
}
