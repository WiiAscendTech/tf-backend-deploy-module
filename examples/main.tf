data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  base_tags  = merge(var.default_base_tags, var.tags)
}

module "backend_deploy" {
  source = ".."

  # Informações básicas
  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  region       = var.region
  tags         = local.base_tags

  # Observabilidade com ADOT
  enable_adot          = var.enable_adot
  amp_remote_write_url = var.amp_remote_write_url
  assume_role_arn      = var.adot_assume_role_arn
  log_group            = var.adot_log_group_name
  adot_environment_variables = [
    {
      name  = "AWS_REGION"
      value = var.region
    },
    {
      name  = "APP_NAME"
      value = var.application
    }
  ]

  # Roteamento com ALB compartilhado
  enable_alb_routing = var.enable_alb_routing
  listener_arn       = var.listener_arn
  vpc_id             = var.vpc_id
  priority           = var.listener_rule_priority
  host_headers       = var.host_headers
  path_patterns      = var.path_patterns
  target_type        = var.alb_target_type
  protocol           = var.alb_protocol
  port               = var.alb_target_group_port
  protocol_version   = var.alb_protocol_version
  health_check_path  = var.alb_health_check_path
  tg_advanced        = var.alb_target_group_advanced_configuration

  # Repositório ECR e configurações globais
  enable_ecr                      = var.enable_ecr
  repository_image_tag_mutability = var.repository_image_tag_mutability
  repository_encryption_type      = var.repository_encryption_type
  repository_kms_key              = var.repository_kms_key_arn
  repository_read_access_arns     = var.repository_read_access_arns
  repository_read_write_access_arns = var.repository_read_write_access_arns
  enable_registry_scanning        = var.enable_registry_scanning
  registry_scan_type              = var.registry_scan_type
  replication_destinations        = var.replication_destinations
  max_image_count                 = var.max_image_count

  # Cluster ECS e serviços
  enable_ecs                    = var.enable_ecs
  enable_fargate_spot           = var.enable_fargate_spot
  fargate_capacity_provider_strategy      = var.fargate_capacity_provider_strategy
  fargate_spot_capacity_provider_strategy = var.fargate_spot_capacity_provider_strategy
  cluster_kms_key_id      = var.cluster_kms_key_arn
  ecs_log_group_kms_key   = var.ecs_log_group_kms_key_arn
  additional_task_execution_policies = var.additional_task_execution_policies
  ssm_parameters_arns     = var.ssm_parameter_arns
  secrets_manager_arns    = var.secrets_manager_arns
  create_ecs_alarms       = var.create_ecs_alarms
  ecs_alarm_actions       = var.ecs_alarm_topic_arn != null ? [var.ecs_alarm_topic_arn] : []
  ecs_alarm_ok_actions    = var.ecs_alarm_topic_arn != null ? [var.ecs_alarm_topic_arn] : []
  ecs_alarm_insufficient_data_actions = var.ecs_alarm_insufficient_data_actions
  ecs_alarm_treat_missing_data        = var.ecs_alarm_treat_missing_data
  ecs_cpu_alarm_threshold             = var.ecs_cpu_alarm_threshold
  ecs_cpu_alarm_evaluation_periods    = var.ecs_cpu_alarm_evaluation_periods
  ecs_cpu_alarm_period                = var.ecs_cpu_alarm_period

  ecs_services = {
    (var.api_service_settings.service_name) = {
      desired_count          = var.api_service_settings.desired_count
      assign_public_ip       = var.api_service_settings.assign_public_ip
      enable_execute_command = var.api_service_settings.enable_execute_command
      subnet_ids             = var.private_subnet_ids
      security_group_ids     = var.security_group_ids
      load_balancer = {
        target_group_arn = var.existing_target_group_arn
        container_name   = var.api_service_settings.app_container.name
        container_port   = var.api_service_settings.app_container.port
      }
      container_definitions = merge(
        {
          (var.api_service_settings.app_container.name) = {
            image = var.api_image
            portMappings = [
              {
                containerPort = var.api_service_settings.app_container.port
                protocol      = var.api_service_settings.app_container.protocol
              }
          ]
          environment = concat(
            [
              { name = "ENVIRONMENT", value = var.environment },
              { name = "LOG_LEVEL", value = var.api_service_settings.app_container.log_level }
            ],
            var.api_service_settings.app_container.additional_environment
          )
          health_check = {
            command      = var.api_service_settings.app_container.health_check.command
            interval     = var.api_service_settings.app_container.health_check.interval
            timeout      = var.api_service_settings.app_container.health_check.timeout
            retries      = var.api_service_settings.app_container.health_check.retries
            start_period = var.api_service_settings.app_container.health_check.start_period
          }
        }
        },
        var.enable_adot ? {
          (var.api_service_settings.adot_container.name) = {
            image     = var.api_service_settings.adot_container.image
            essential = var.api_service_settings.adot_container.essential
            environment = concat(
              [
                { name = "AWS_REGION", value = var.region },
                { name = "AWS_ACCOUNT_ID", value = local.account_id }
              ],
              var.api_service_settings.adot_container.additional_environment
            )
          }
        } : {}
      )
      enable_autoscaling        = var.api_service_settings.enable_autoscaling
      autoscaling_min_capacity  = var.api_service_settings.autoscaling_min_capacity
      autoscaling_max_capacity  = var.api_service_settings.autoscaling_max_capacity
      autoscaling_target_cpu    = var.api_service_settings.autoscaling_target_cpu
      autoscaling_target_memory = var.api_service_settings.autoscaling_target_memory
      autoscaling_request_count = {
        enabled        = var.api_service_settings.autoscaling_request_count.enabled
        resource_label = "${var.api_service_settings.autoscaling_request_count.prefix}/${var.vpc_id}/${var.environment}"
        target_value   = var.api_service_settings.autoscaling_request_count.target_value
      }
    }

    (var.worker_service_settings.service_name) = {
      desired_count      = var.worker_service_settings.desired_count
      assign_public_ip   = var.worker_service_settings.assign_public_ip
      subnet_ids         = var.private_subnet_ids
      security_group_ids = var.security_group_ids
      container_definitions = {
        (var.worker_service_settings.container_name) = {
          image = var.worker_image
          environment = concat(
            var.worker_service_settings.environment_variables,
            [
              { name = "ENVIRONMENT", value = var.environment }
            ]
          )
        }
      }
    }
  }

  # Secrets Manager
  enable_secrets_manager          = var.enable_secrets_manager
  secrets_kms_key_id              = var.secrets_kms_key_arn
  secrets_recovery_window         = var.secrets_recovery_window
  enable_cross_region_replication = length(var.replica_regions) > 0
  replication_regions             = var.replica_regions
  additional_secret_reader_arns   = var.additional_secret_reader_arns

  create_database_secret = var.create_database_secret
  database_secret_config = {
    username        = var.database_secret_config.username
    engine          = var.database_secret_config.engine
    host            = var.database_secret_config.host
    port            = var.database_secret_config.port
    dbname          = var.database_secret_config.dbname
    enable_rotation = var.database_secret_rotation_lambda_arn != null
    rotation_lambda_arn = var.database_secret_rotation_lambda_arn
    rotation_days   = var.database_secret_config.rotation_days
  }

  create_api_keys_secret        = var.create_api_keys_secret
  api_keys_rotation_lambda_arn  = var.api_keys_rotation_lambda_arn
  api_keys_rotation_days        = var.api_keys_rotation_days
  api_keys_config               = var.api_keys_config

  create_app_secrets = var.create_app_secrets
  app_secrets_config = var.app_secrets_config

  secrets = var.secrets_config
}

output "ecs_cluster_name" {
  description = "Nome do cluster ECS criado pelo módulo"
  value       = module.backend_deploy.ecs_cluster_name
}

output "api_service_arn" {
  description = "ARN do serviço ECS principal"
  value       = module.backend_deploy.ecs_services["api"].arn
}

output "target_group_arn" {
  description = "ARN do Target Group configurado via módulo"
  value       = module.backend_deploy.target_group_arn
}

output "database_secret_arn" {
  description = "ARN do secret de banco de dados gerenciado"
  value       = module.backend_deploy.database_secret_arn
}
