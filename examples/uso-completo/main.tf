data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  base_tags  = merge({
    CostCenter   = "CC-001",
    BusinessUnit = "Digital",
  }, var.tags)
}

module "backend_deploy" {
  source = "../.."

  # Informações básicas
  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  region       = var.region
  tags         = local.base_tags

  # Observabilidade com ADOT
  enable_adot          = true
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
  enable_alb_routing = true
  listener_arn       = var.listener_arn
  vpc_id             = var.vpc_id
  priority           = var.listener_rule_priority
  host_headers       = var.host_headers
  path_patterns      = var.path_patterns
  target_type        = "ip"
  protocol           = "HTTP"
  port               = 8080
  protocol_version   = "HTTP1"
  health_check_path  = "/healthz"
  tg_advanced = {
    deregistration_delay = 30
    slow_start           = 60
    stickiness = {
      enabled         = true
      type            = "lb_cookie"
      cookie_duration = 3600
    }
  }

  # Repositório ECR e configurações globais
  enable_ecr                      = true
  repository_image_tag_mutability = "IMMUTABLE"
  repository_encryption_type      = "KMS"
  repository_kms_key              = var.repository_kms_key_arn
  repository_read_access_arns     = var.repository_read_access_arns
  repository_read_write_access_arns = var.repository_read_write_access_arns
  enable_registry_scanning        = true
  registry_scan_type              = "ENHANCED"
  enable_cross_region_replication = length(var.replication_destinations) > 0
  replication_destinations        = var.replication_destinations
  max_image_count                 = 15

  # Cluster ECS e serviços
  enable_ecs                    = true
  enable_fargate_spot           = true
  fargate_capacity_provider_strategy = {
    base   = 1
    weight = 70
  }
  fargate_spot_capacity_provider_strategy = {
    base   = 0
    weight = 30
  }
  cluster_kms_key_id      = var.cluster_kms_key_arn
  ecs_log_group_kms_key   = var.ecs_log_group_kms_key_arn
  additional_task_execution_policies = var.additional_task_execution_policies
  ssm_parameters_arns     = var.ssm_parameter_arns
  secrets_manager_arns    = var.secrets_manager_arns
  create_ecs_alarms       = true
  ecs_alarm_actions       = var.ecs_alarm_topic_arn != null ? [var.ecs_alarm_topic_arn] : []
  ecs_alarm_ok_actions    = var.ecs_alarm_topic_arn != null ? [var.ecs_alarm_topic_arn] : []
  ecs_alarm_insufficient_data_actions = []
  ecs_alarm_treat_missing_data        = "notBreaching"
  ecs_cpu_alarm_threshold             = 75
  ecs_cpu_alarm_evaluation_periods    = 2
  ecs_cpu_alarm_period                = 300

  ecs_services = {
    api = {
      desired_count          = 2
      assign_public_ip       = false
      enable_execute_command = true
      subnet_ids             = var.private_subnet_ids
      security_group_ids     = var.security_group_ids
      load_balancer = {
        target_group_arn = var.existing_target_group_arn
        container_name   = "app"
        container_port   = 8080
      }
      container_definitions = {
        app = {
          image = var.api_image
          portMappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
          environment = [
            { name = "ENVIRONMENT", value = var.environment },
            { name = "LOG_LEVEL", value = "info" }
          ]
          health_check = {
            command      = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
            interval     = 30
            timeout      = 5
            retries      = 3
            start_period = 60
          }
        }
        adot = {
          image     = "amazon/aws-otel-collector:latest"
          essential = false
          environment = [
            { name = "AWS_REGION", value = var.region },
            { name = "AWS_ACCOUNT_ID", value = local.account_id }
          ]
        }
      }
      enable_autoscaling       = true
      autoscaling_min_capacity = 2
      autoscaling_max_capacity = 6
      autoscaling_target_cpu   = 60
      autoscaling_target_memory = 70
      autoscaling_request_count = {
        enabled        = true
        resource_label = "app/alb/${var.vpc_id}/${var.environment}"
        target_value   = 1000
      }
    }

    worker = {
      desired_count      = 1
      assign_public_ip   = false
      subnet_ids         = var.private_subnet_ids
      security_group_ids = var.security_group_ids
      container_definitions = {
        worker = {
          image = var.worker_image
          environment = [
            { name = "QUEUE_NAME", value = "default" },
            { name = "ENVIRONMENT", value = var.environment }
          ]
        }
      }
    }
  }

  # Secrets Manager
  enable_secrets_manager          = true
  secrets_kms_key_id              = var.secrets_kms_key_arn
  secrets_recovery_window         = 7
  enable_cross_region_replication = length(var.replica_regions) > 0
  replication_regions             = var.replica_regions
  additional_secret_reader_arns   = var.additional_secret_reader_arns

  create_database_secret = true
  database_secret_config = {
    username        = "app_user"
    engine          = "postgres"
    host            = "prod-db.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
    port            = 5432
    dbname          = "application"
    enable_rotation = var.database_secret_rotation_lambda_arn != null
    rotation_lambda_arn = var.database_secret_rotation_lambda_arn
    rotation_days   = 30
  }

  create_api_keys_secret        = true
  api_keys_rotation_lambda_arn  = var.api_keys_rotation_lambda_arn
  api_keys_rotation_days        = 30
  api_keys_config = {
    stripe = {
      secret_arn    = var.stripe_secret_arn
      version_stage = "AWSCURRENT"
    }
    sendgrid = {
      secret_arn = var.sendgrid_secret_arn
    }
  }

  create_app_secrets = true
  app_secrets_config = {
    jwt_secret = {
      create_random_password = true
      password_length        = 64
      description            = "JWT signing secret"
    }
    webhook_token = {
      value       = "change-me"
      description = "Webhook token used by partners"
    }
  }

  secrets = {
    github_pat = {
      name        = "${var.project_name}/${var.environment}/github/pat"
      description = "Token de acesso para deploy via GitHub Actions"
      secret_string = jsonencode({
        token = "ghp_example_token"
      })
    }
  }
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
