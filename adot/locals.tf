locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  assume_role_principals = distinct(concat(
    length(var.assume_role_principals) > 0 ? var.assume_role_principals : [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
    ],
    var.task_role_arn != null ? [var.task_role_arn] : []
  ))

  remote_write_role_name   = "${var.application}-adot-remote-write-${var.environment}"
  remote_write_policy_name = "${var.application}-adot-remote-write-policy-${var.environment}"
  remote_write_resources   = var.amp_workspace_arn != null ? [var.amp_workspace_arn] : ["*"]

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

  container_name = coalesce(var.container_name, "${var.application}-adot")

  adot_container_definition = merge(
    {
      name      = local.container_name
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
}

