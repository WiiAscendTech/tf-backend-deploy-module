locals {
  adot_container_definition = {
    name      = var.container_name,
    image     = var.image,
    cpu       = var.cpu,
    memory    = var.memory,
    essential = false,

    command = ["--config=env:ADOT_CONFIG_CONTENT"],

    portMappings = [
      { containerPort = 4317, protocol = "tcp" },
      { containerPort = 4318, protocol = "tcp" }
    ],

    environment = local.environment_variables,

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = var.log_group,
        awslogs-region        = var.region,
        awslogs-stream-prefix = var.log_stream_prefix
      }
    },

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:13133/health/status || exit 1"],
      interval    = 30,
      timeout     = 5,
      retries     = 3,
      startPeriod = 10
    }
  }

  adot_config_env = {
    name  = "ADOT_CONFIG_CONTENT"
    value = data.local_file.adot_config_content.content
  }

  environment_variables = concat(var.environment_variables, [local.adot_config_env])

  final_name = var.name_override != null ? var.name_override : "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })
}
