output "adot_container_definition" {
  value = jsonencode({
    name      = var.container_name,
    image     = var.image,
    cpu       = var.adot_cpu,
    memory    = var.adot_memory,
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
  })
}