// ADOT SIDECAR
output "adot_container_definition" {
  value = jsonencode({
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
  })
}

// ECR
output "repository_url" {
  description = "URL do repositório ECR criado"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN do repositório ECR criado"
  value       = aws_ecr_repository.this.arn
}

output "registry_id" {
  description = "ID do registro AWS associado ao repositório ECR"
  value       = aws_ecr_repository.this.registry_id
}

// ECS SERVICE
output "service_name" {
  value       = aws_ecs_service.this.name
  description = "Nome do Serviço ECS."
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "ARN da definição da task criada."
}

output "ecs_sg_id" {
  description = "ID do Security Group do ECS"
  value       = aws_security_group.ecs_sg.id
}

output "container_port" {
  description = "Porta do container ECS"
  value       = var.container_port
}

output "ecs_cloudwatch_log_group_name" {
  description = "Nome do Log Group do ECS"
  value       = aws_cloudwatch_log_group.this.name
}

// IAM ROLE
output "role_name" {
  description = "Nome da IAM Role criada"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN da IAM Role criada"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "ARN da política IAM criada (se aplicável)"
  value       = var.policy_json != null ? aws_iam_policy.this[0].arn : null
}

output "attached_managed_policies" {
  description = "Lista de ARNs de políticas gerenciadas anexadas"
  value       = var.managed_policy_arns
}

// LISTENER RULE
output "listener_rule_arn" {
  description = "ARN da regra de listener criada"
  value       = aws_lb_listener_rule.this.arn
}

// SECRETS MANAGER
output "secret_arn" {
  description = "ARN do segredo"
  value       = aws_secretsmanager_secret.secret_manager.arn
}

output "secret_name" {
  description = "Nome do segredo"
  value       = aws_secretsmanager_secret.secret_manager.name
}

output "secret_id" {
  description = "ID do segredo (necessário para data sources)"
  value       = aws_secretsmanager_secret.secret_manager.id
}

output "secret_version_id" {
  description = "ID da versão do segredo (se criada)"
  value       = try(aws_secretsmanager_secret_version.secret_version[0].version_id, null)
}

// TARGET GROUP
output "target_group_arn" {
  description = "ARN do Target Group"
  value       = aws_lb_target_group.this.arn

}
output "target_group_name" {
  description = "Nome do Target Group"
  value       = aws_lb_target_group.this.name
}

// X-RAY
output "xray_role_name" {
  value       = aws_iam_role.this.name
  description = "Nome da IAM Role atribuída ao X-Ray"
}

output "xray_role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN da IAM Role atribuída ao X-Ray"
}

// CLOUDWATCH LOGS
output "log_group_name" {
  description = "Nome do Log Group criado"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN do Log Group criado"
  value       = aws_cloudwatch_log_group.this.arn
}

output "log_group_kms_key_id" {
  description = "KMS Key ID utilizada para criptografia"
  value       = aws_cloudwatch_log_group.this.kms_key_id
}

output "subscription_filter_name" {
  description = "Nome do Subscription Filter criado (se existir)"
  value       = length(aws_cloudwatch_log_subscription_filter.this) > 0 ? aws_cloudwatch_log_subscription_filter.this[0].name : null
}

output "metric_filter_names" {
  description = "Nomes dos Metric Filters criados"
  value       = [for filter in aws_cloudwatch_log_metric_filter.this : filter.name]
}