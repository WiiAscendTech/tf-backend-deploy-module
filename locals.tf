locals {
  cloudwatch_log_group_name = coalesce(var.log_group, "/ecs/${var.application}-${var.environment}")

  adot_log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = local.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = coalesce(var.log_stream_prefix, "${var.application}-adot")
    }
  }

  adot_config_env = {
    name  = "ADOT_CONFIG_CONTENT"
    value = data.local_file.adot_config_content.content
  }

  environment_variables = concat(var.environment_variables, [local.adot_config_env])

  adot_container_definition = merge(
    {
      name      = var.container_name
      image     = var.image
      cpu       = var.adot_cpu
      memory    = var.adot_memory
      essential = false

      command = ["--config=env:ADOT_CONFIG_CONTENT"]

      portMappings = [
        { containerPort = 4317, hostPort = 4317, protocol = "tcp" },
        { containerPort = 4318, hostPort = 4318, protocol = "tcp" }
      ]

      environment = local.environment_variables

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:13133/health/status || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    },
    {
      logConfiguration = local.adot_log_configuration
    }
  )

  final_name = var.name_override != null ? var.name_override : "${var.application}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  execution_role_name = try(element(reverse(split("/", var.execution_role_arn)), 0), null)
}
