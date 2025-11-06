# =============================================================================
# ADOT MODULE OUTPUTS
# =============================================================================

output "adot_container_definition" {
  description = "Definição JSON do container ADOT para uso em task definitions do ECS"
  value       = var.enable_adot ? module.adot[0].adot_container_definition : null
}

output "adot_enabled" {
  description = "Indica se o módulo ADOT está habilitado"
  value       = var.enable_adot
}

# =============================================================================
# CONFIGURATION OUTPUTS
# =============================================================================

output "adot_configuration" {
  description = "Configuração completa do módulo ADOT"
  value = var.enable_adot ? {
    container_name        = var.adot_container_name
    image                = var.adot_image
    cpu                  = var.adot_cpu
    memory               = var.adot_memory
    enable_traces        = var.enable_traces
    enable_metrics       = var.enable_metrics
    log_group           = var.log_group
    log_stream_prefix   = var.log_stream_prefix
    amp_remote_write_url = var.amp_remote_write_url
  } : null
  sensitive = true
}

# =============================================================================
# COMMON OUTPUTS
# =============================================================================

output "common_tags" {
  description = "Tags comuns aplicadas aos recursos"
  value       = local.common_tags
}

output "resource_prefix" {
  description = "Prefixo usado para nomear recursos"
  value       = local.resource_prefix
}

output "environment_info" {
  description = "Informações sobre o ambiente de deployment"
  value = {
    environment  = var.environment
    project_name = var.project_name
    owner        = var.owner
    application  = var.application
    region       = var.region
  }
}

# =============================================================================
# ALB ROUTING MODULE OUTPUTS
# =============================================================================

output "target_group_arn" {
  description = "ARN do Target Group criado pelo módulo ALB routing"
  value       = var.enable_alb_routing ? module.alb_routing[0].target_group_arn : null
}

output "target_group_name" {
  description = "Nome do Target Group criado pelo módulo ALB routing"
  value       = var.enable_alb_routing ? module.alb_routing[0].target_group_name : null
}

output "listener_rule_arn" {
  description = "ARN da Listener Rule criada pelo módulo ALB routing"
  value       = var.enable_alb_routing ? module.alb_routing[0].listener_rule_arn : null
}

output "alb_routing_enabled" {
  description = "Indica se o módulo ALB routing está habilitado"
  value       = var.enable_alb_routing
}

output "alb_routing_configuration" {
  description = "Configuração completa do módulo ALB routing"
  value = var.enable_alb_routing ? {
    target_type       = var.target_type
    protocol          = var.protocol
    port              = var.port
    protocol_version  = var.protocol_version
    priority          = var.priority
    path_patterns     = var.path_patterns
    host_headers      = var.host_headers
    health_check_path = var.health_check_path
    vpc_id           = var.vpc_id
  } : null
  sensitive = true
}

# =============================================================================
# ECR MODULE OUTPUTS
# =============================================================================

output "ecr_repository_name" {
  description = "Nome do repositório ECR criado"
  value       = var.enable_ecr ? module.ecr[0].repository_name : null
}

output "ecr_repository_arn" {
  description = "ARN do repositório ECR criado"
  value       = var.enable_ecr ? module.ecr[0].repository_arn : null
}

output "ecr_repository_url" {
  description = "URL do repositório ECR para push/pull de imagens"
  value       = var.enable_ecr ? module.ecr[0].repository_url : null
}

output "ecr_registry_id" {
  description = "Registry ID onde o repositório foi criado"
  value       = var.enable_ecr ? module.ecr[0].repository_registry_id : null
}

output "ecr_enabled" {
  description = "Indica se o módulo ECR está habilitado"
  value       = var.enable_ecr
}

output "ecr_configuration" {
  description = "Configuração completa do módulo ECR"
  value = var.enable_ecr ? {
    repository_name             = local.ecr_repository_name
    repository_type             = var.repository_type
    image_tag_mutability        = var.repository_image_tag_mutability
    encryption_type             = var.repository_encryption_type
    scan_on_push               = var.repository_image_scan_on_push
    lifecycle_policy_enabled    = var.create_lifecycle_policy
    registry_scanning_enabled   = var.enable_registry_scanning
    cross_region_replication   = var.enable_cross_region_replication
    replication_destinations   = var.replication_destinations
  } : null
  sensitive = true
}

# =============================================================================
# ECS MODULE OUTPUTS
# =============================================================================

output "ecs_cluster_arn" {
  description = "ARN do cluster ECS criado"
  value       = var.enable_ecs ? module.ecs[0].cluster_arn : null
}

output "ecs_cluster_id" {
  description = "ID do cluster ECS criado"
  value       = var.enable_ecs ? module.ecs[0].cluster_id : null
}

output "ecs_cluster_name" {
  description = "Nome do cluster ECS criado"
  value       = var.enable_ecs ? module.ecs[0].cluster_name : null
}

output "ecs_cloudwatch_log_group_name" {
  description = "Nome do CloudWatch Log Group do cluster ECS"
  value       = var.enable_ecs ? module.ecs[0].cloudwatch_log_group_name : null
}

output "ecs_cloudwatch_log_group_arn" {
  description = "ARN do CloudWatch Log Group do cluster ECS"
  value       = var.enable_ecs ? module.ecs[0].cloudwatch_log_group_arn : null
}

output "ecs_task_execution_role_arn" {
  description = "ARN da role de execução de tasks compartilhada"
  value       = var.enable_ecs ? module.ecs[0].task_exec_iam_role_arn : null
}

output "ecs_task_execution_role_name" {
  description = "Nome da role de execução de tasks compartilhada"
  value       = var.enable_ecs ? module.ecs[0].task_exec_iam_role_name : null
}

output "ecs_services" {
  description = "Informações dos serviços ECS criados"
  value       = var.enable_ecs ? {
    for service_name, service in module.ecs[0].services : service_name => {
      id                           = service.id
      name                         = service.name
      arn                          = service.arn
      cluster                      = service.cluster
      desired_count                = service.desired_count
      launch_type                  = service.launch_type
      platform_version             = service.platform_version
      task_definition              = service.task_definition
      task_definition_family       = try(service.task_definition_family, null)
      last_deployment_status       = try(service.deployment_status, null)
      running_count                = try(service.running_count, null)
      pending_count                = try(service.pending_count, null)
      security_group_id            = try(service.security_group_id, null)
      cloudwatch_log_group         = try(service.cloudwatch_log_group_name, null)
      service_connect_configuration = try(service.service_connect_configuration, null)
      autoscaling_enabled          = service.autoscaling_enabled
    }
  } : {}
}

output "ecs_enabled" {
  description = "Indica se o módulo ECS está habilitado"
  value       = var.enable_ecs
}

output "ecs_configuration" {
  description = "Configuração completa do módulo ECS"
  value = var.enable_ecs ? {
    cluster_name                    = local.ecs_cluster_name
    container_insights_enabled     = var.enable_container_insights
    execute_command_logging_enabled = var.cluster_execute_command_logging
    fargate_enabled                 = var.enable_fargate
    fargate_spot_enabled           = var.enable_fargate_spot
    task_execution_role_name       = local.task_execution_role_name
    log_retention_days             = var.ecs_log_group_retention
    services_count                 = length(var.ecs_services)
    capacity_providers = {
      fargate      = var.enable_fargate
      fargate_spot = var.enable_fargate_spot
    }
  } : null
  sensitive = true
}

# =============================================================================
# SECRETS MANAGER MODULE OUTPUTS
# =============================================================================

output "secrets_manager_secrets" {
  description = "Informações dos secrets criados no Secrets Manager"
  value = var.enable_secrets_manager ? {
    for secret_name, secret in module.secrets_manager : secret_name => {
      arn         = secret.secret_arn
      id          = secret.secret_id
      name        = secret.secret_name
      version_id  = secret.secret_version_id
      replica     = secret.secret_replica
    }
  } : {}
}

output "secrets_manager_arns" {
  description = "ARNs de todos os secrets criados para uso em policies IAM"
  value = var.enable_secrets_manager ? {
    for secret_name, secret in module.secrets_manager : secret_name => secret.secret_arn
  } : {}
}

output "database_secret_arn" {
  description = "ARN do secret do banco de dados (se criado)"
  value       = var.enable_secrets_manager && var.create_database_secret ? try(module.secrets_manager["database"].secret_arn, null) : null
}

output "api_keys_secret_arn" {
  description = "ARN do secret das chaves de API (se criado)"
  value       = var.enable_secrets_manager && var.create_api_keys_secret ? try(module.secrets_manager["api-keys"].secret_arn, null) : null
}

output "app_secrets_arns" {
  description = "ARNs dos secrets específicos da aplicação"
  value = var.enable_secrets_manager && var.create_app_secrets ? {
    for secret_name, config in var.app_secrets_config : secret_name => try(module.secrets_manager["app-${secret_name}"].secret_arn, null)
  } : {}
}

output "secrets_manager_enabled" {
  description = "Indica se o módulo Secrets Manager está habilitado"
  value       = var.enable_secrets_manager
}

output "secrets_manager_configuration" {
  description = "Configuração completa do módulo Secrets Manager"
  value = var.enable_secrets_manager ? {
    kms_key_id                      = var.secrets_kms_key_id
    recovery_window_days           = var.secrets_recovery_window
    cross_region_replication_enabled = var.enable_cross_region_replication
    replication_regions            = var.replication_regions
    database_secret_enabled        = var.create_database_secret
    api_keys_secret_enabled        = var.create_api_keys_secret
    app_secrets_enabled            = var.create_app_secrets
    total_secrets_count            = length(local.all_secrets)
    secrets_by_type = {
      custom      = length(var.secrets)
      database    = var.create_database_secret ? 1 : 0
      api_keys    = var.create_api_keys_secret ? 1 : 0
      application = length(var.app_secrets_config)
    }
  } : null
  sensitive = true
}