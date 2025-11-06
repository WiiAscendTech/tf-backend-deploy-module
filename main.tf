# =============================================================================
# LOCALS
# =============================================================================

locals {
  # Tags comuns aplicadas a todos os recursos
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  })

  # Nome padrão para recursos
  resource_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# AWS DISTRO FOR OPENTELEMETRY (ADOT) MODULE
# =============================================================================

module "adot" {
  count  = var.enable_adot ? 1 : 0
  source = "./aws-adot"

  # Common configuration
  environment    = var.environment
  project_name   = var.project_name
  owner          = var.owner
  application    = var.application
  region         = var.region
  tags           = local.common_tags

  # ADOT specific configuration
  container_name = var.adot_container_name
  image          = var.adot_image
  adot_cpu       = var.adot_cpu
  adot_memory    = var.adot_memory

  # Observability configuration
  enable_traces  = var.enable_traces
  enable_metrics = var.enable_metrics

  # AWS services integration
  amp_remote_write_url = var.amp_remote_write_url
  assume_role_arn      = var.assume_role_arn

  # Logging configuration
  log_group          = var.log_group
  log_stream_prefix  = var.log_stream_prefix

  # Additional configuration
  environment_variables = var.adot_environment_variables
  volume_name          = var.volume_name
}

# =============================================================================
# AWS APPLICATION LOAD BALANCER ROUTING MODULE
# =============================================================================

module "alb_routing" {
  count  = var.enable_alb_routing ? 1 : 0
  source = "./aws-alb-routing"

  # Common configuration
  application = var.application
  environment = var.environment
  tags        = local.common_tags

  # ALB configuration
  listener_arn   = var.listener_arn
  vpc_id         = var.vpc_id
  priority       = var.priority

  # Routing configuration
  host_headers   = var.host_headers
  path_patterns  = var.path_patterns

  # Target Group configuration
  target_type      = var.target_type
  protocol         = var.protocol
  port             = var.port
  protocol_version = var.protocol_version

  # Health check configuration
  health_check_path               = var.health_check_path
  health_check_interval           = var.health_check_interval
  health_check_timeout            = var.health_check_timeout
  health_check_healthy_threshold  = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  health_check_matcher            = var.health_check_matcher

  # Advanced configuration
  tg_advanced = var.tg_advanced

  # Lambda configuration (when applicable)
  lambda_function_arn      = var.lambda_function_arn
  lambda_attach_permission = var.lambda_attach_permission
}

# =============================================================================
# AMAZON ELASTIC CONTAINER REGISTRY (ECR) MODULE
# =============================================================================

locals {
  # Nome do repositório ECR baseado na aplicação e ambiente
  ecr_repository_name = var.ecr_repository_name != "" ? var.ecr_repository_name : "${var.application}-${var.environment}"
  
  # Política de lifecycle padrão se não especificada
  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod", "production", "release"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.max_image_count} staging images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["stg", "staging", "stage"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep last ${var.max_image_count * 2} development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "development", "feature"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count * 2
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  # Regras de scan padrão
  default_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "*"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]
  
  # Regras de replicação se habilitadas
  replication_rules = var.enable_cross_region_replication && length(var.replication_destinations) > 0 ? [
    {
      destinations = var.replication_destinations
      repository_filters = [
        {
          filter      = local.ecr_repository_name
          filter_type = "PREFIX_MATCH"
        }
      ]
    }
  ] : []
}

module "ecr" {
  count  = var.enable_ecr ? 1 : 0
  source = "./aws-ecr"

  # Basic configuration
  create            = true
  repository_name   = local.ecr_repository_name
  repository_type   = var.repository_type
  region           = var.region
  tags             = local.common_tags

  # Repository configuration
  repository_image_tag_mutability = var.repository_image_tag_mutability
  repository_encryption_type      = var.repository_encryption_type
  repository_kms_key             = var.repository_kms_key
  repository_image_scan_on_push  = var.repository_image_scan_on_push
  repository_force_delete        = var.repository_force_delete

  # Access control
  repository_read_access_arns       = var.repository_read_access_arns
  repository_read_write_access_arns = var.repository_read_write_access_arns
  repository_lambda_read_access_arns = var.repository_lambda_read_access_arns

  # Lifecycle policy
  create_lifecycle_policy     = var.create_lifecycle_policy
  repository_lifecycle_policy = var.repository_lifecycle_policy != "" ? var.repository_lifecycle_policy : local.default_lifecycle_policy

  # Public repository configuration (if applicable)
  public_repository_catalog_data = var.repository_type == "public" ? var.public_repository_catalog_data : null

  # Registry-level configurations
  manage_registry_scanning_configuration = var.enable_registry_scanning
  registry_scan_type                     = var.registry_scan_type
  registry_scan_rules                    = var.enable_registry_scanning ? local.default_scan_rules : null

  # Cross-region replication
  create_registry_replication_configuration = var.enable_cross_region_replication
  registry_replication_rules                = local.replication_rules

  # Pull through cache rules
  registry_pull_through_cache_rules = var.pull_through_cache_rules
}

# =============================================================================
# AMAZON ELASTIC CONTAINER SERVICE (ECS) MODULE
# =============================================================================

locals {
  # Nome do cluster ECS baseado no projeto e ambiente
  ecs_cluster_name = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${var.project_name}-${var.environment}"
  
  # Nome da role de execução de tasks
  task_execution_role_name = var.task_execution_role_name != "" ? var.task_execution_role_name : "${local.ecs_cluster_name}-task-execution"
  
  # Capacity provider strategy baseada nas configurações
  capacity_provider_strategy = merge(
    var.enable_fargate ? {
      fargate = {
        capacity_provider = "FARGATE"
        base              = var.fargate_capacity_provider_strategy.base
        weight            = var.fargate_capacity_provider_strategy.weight
      }
    } : {},
    var.enable_fargate_spot ? {
      fargate_spot = {
        capacity_provider = "FARGATE_SPOT"
        base              = var.fargate_spot_capacity_provider_strategy.base
        weight            = var.fargate_spot_capacity_provider_strategy.weight
      }
    } : {}
  )
  
  # Configuração do cluster com execute command
  cluster_configuration = {
    execute_command_configuration = var.cluster_execute_command_logging ? {
      kms_key_id = var.cluster_kms_key_id
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.ecs_cluster_name}/execute-command"
      }
      logging = "OVERRIDE"
    } : null
    managed_storage_configuration = var.cluster_kms_key_id != null ? {
      fargate_ephemeral_storage_kms_key_id = var.cluster_kms_key_id
      kms_key_id                           = var.cluster_kms_key_id
    } : null
  }
  
  # Processamento dos serviços ECS
  processed_services = { for service_name, service_config in var.ecs_services : service_name => merge(service_config, {
    # Configuração automática de nomes
    name   = service_name
    family = "${service_name}-${var.environment}"
    
    # Network configuration
    vpc_id = var.vpc_id
    
    # Security group automático se não especificado
    create_security_group = length(service_config.security_group_ids) == 0 ? true : false
    security_group_name   = "${service_name}-${var.environment}"
    security_group_ingress_rules = {
      app_port = {
        from_port = try(
          flatten([
            for container_definition in values(service_config.container_definitions) : [
              for mapping in try(container_definition.portMappings, []) : mapping.containerPort
            ]
            if try(container_definition.create, true)
          ])[0],
          80
        )
        to_port     = try(
          flatten([
            for container_definition in values(service_config.container_definitions) : [
              for mapping in try(container_definition.portMappings, []) : mapping.containerPort
            ]
            if try(container_definition.create, true)
          ])[0],
          80
        )
        ip_protocol = "tcp"
        cidr_ipv4   = "10.0.0.0/8"
        description = "Application traffic"
      }
    }
    security_group_egress_rules = {
      all_outbound = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
        description = "All outbound traffic"
      }
    }
    
    # Task execution role configuration
    create_task_exec_iam_role = false  # Usa a role compartilhada do cluster
    
    # Container definitions processadas
    container_definitions = {
      for container_name, container_config in service_config.container_definitions :
      container_name => merge(container_config, {
        name = container_name

        # Port mappings formatação correta
        portMappings = [
          for pm in try(container_config.portMappings, []) : {
            containerPort = pm.containerPort
            hostPort      = pm.hostPort
            protocol      = pm.protocol
            name          = pm.name != null ? pm.name : "${container_name}-${pm.containerPort}"
            appProtocol   = pm.appProtocol
          }
        ]

        # Environment variables formatação correta
        environment = container_config.environment
        secrets     = container_config.secrets

        # Health check formatação correta
        healthCheck = container_config.health_check != null ? {
          command     = container_config.health_check.command
          interval    = container_config.health_check.interval
          timeout     = container_config.health_check.timeout
          retries     = container_config.health_check.retries
          startPeriod = container_config.health_check.start_period
        } : null

        # Logging configuration
        enable_cloudwatch_logging              = container_config.enable_cloudwatch_logging
        create_cloudwatch_log_group            = container_config.enable_cloudwatch_logging
        cloudwatch_log_group_retention_in_days = container_config.log_group_retention_days
        cloudwatch_log_group_kms_key_id        = var.ecs_log_group_kms_key
        service                                = service_name

        # Linux parameters
        readonlyRootFilesystem = container_config.readonly_root_filesystem
        privileged             = container_config.privileged

        # Working directory and user
        workingDirectory = container_config.working_directory
        user             = container_config.user

        # Command and entrypoint
        command    = container_config.command
        entrypoint = container_config.entry_point

        # Dependencies
        dependsOn = [
          for dep in try(container_config.depends_on, []) : {
            containerName = dep.container_name
            condition     = dep.condition
          }
        ]
      })
      if try(container_config.create, true)
    }
    
    # Auto scaling configuration
    autoscaling_policies = service_config.enable_autoscaling ? {
      cpu_scaling = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
          }
          target_value = service_config.autoscaling_target_cpu
        }
      }
      memory_scaling = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageMemoryUtilization"
          }
          target_value = service_config.autoscaling_target_memory
        }
      }
    } : {}
    
    # Capacity provider strategy
    capacity_provider_strategy = local.capacity_provider_strategy
    
    # Load balancer configuration
    load_balancer = service_config.load_balancer != null ? {
      main = {
        target_group_arn = service_config.load_balancer.target_group_arn
        container_name   = service_config.load_balancer.container_name
        container_port   = service_config.load_balancer.container_port
      }
    } : {}
  })}
}

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "./aws-ecs"

  # Basic configuration
  create = true
  region = var.region
  tags   = local.common_tags

  # Cluster configuration
  cluster_name          = local.ecs_cluster_name
  cluster_configuration = local.cluster_configuration
  cluster_setting = var.enable_container_insights ? [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ] : []

  # CloudWatch Log Group
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.ecs_log_group_retention
  cloudwatch_log_group_kms_key_id        = var.ecs_log_group_kms_key

  # Capacity providers
  default_capacity_provider_strategy = local.capacity_provider_strategy

  # Task execution IAM role (shared)
  create_task_exec_iam_role = var.create_task_execution_role
  task_exec_iam_role_name   = local.task_execution_role_name
  task_exec_iam_role_policies = {
    for idx, policy_arn in var.additional_task_execution_policies : 
    "additional_${idx}" => policy_arn
  }
  
  # Task execution permissions
  create_task_exec_policy  = var.create_task_execution_role
  task_exec_ssm_param_arns = var.ssm_parameters_arns
  task_exec_secret_arns    = var.secrets_manager_arns

  # Services configuration
  services = var.enable_ecs ? local.processed_services : {}
}

# =============================================================================
# AWS SECRETS MANAGER MODULE
# =============================================================================

locals {
  # Configuração de replicação padrão
  default_replica_config = var.enable_cross_region_replication ? {
    for region_config in var.replication_regions : region_config.region => {
      region     = region_config.region
      kms_key_id = region_config.kms_key_id
    }
  } : {}

  # Secret do banco de dados
  database_secret = var.create_database_secret ? {
    "database" = {
      name        = "${local.resource_prefix}-database"
      description = "Database credentials for ${var.application}"
      
      secret_string = jsonencode({
        username = var.database_secret_config.username
        password = var.database_secret_config.password != null ? var.database_secret_config.password : null
        engine   = var.database_secret_config.engine
        host     = var.database_secret_config.host
        port     = var.database_secret_config.port
        dbname   = var.database_secret_config.dbname
      })
      
      create_random_password = var.database_secret_config.password == null ? true : false
      random_password_length = 32
      
      kms_key_id              = var.secrets_kms_key_id
      recovery_window_in_days = var.secrets_recovery_window
      replica                 = local.default_replica_config
      
      # Rotation configuration
      enable_rotation     = var.database_secret_config.enable_rotation
      rotation_lambda_arn = var.database_secret_config.rotation_lambda_arn
      rotation_rules = var.database_secret_config.enable_rotation ? {
        automatically_after_days = var.database_secret_config.rotation_days
      } : null
      
      tags = merge(local.common_tags, {
        SecretType = "database"
        Rotation   = var.database_secret_config.enable_rotation ? "enabled" : "disabled"
      })
    }
  } : {}

  # Secret das chaves de API
  api_keys_secret = var.create_api_keys_secret && length(var.api_keys_config) > 0 ? {
    "api-keys" = {
      name        = "${local.resource_prefix}-api-keys"
      description = "External API keys for ${var.application}"
      
      secret_string = jsonencode(var.api_keys_config)
      
      kms_key_id              = var.secrets_kms_key_id
      recovery_window_in_days = var.secrets_recovery_window
      replica                 = local.default_replica_config
      
      # Policy para acesso controlado
      create_policy = true
      policy_statements = {
        application_access = {
          sid    = "ApplicationAccess"
          effect = "Allow"
          principals = [{
            type        = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*ECS*"]
          }]
          actions = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ]
          condition = [{
            test     = "StringEquals"
            variable = "secretsmanager:ResourceTag/Environment"
            values   = [var.environment]
          }]
        }
      }
      
      tags = merge(local.common_tags, {
        SecretType = "api-keys"
        Sensitive  = "high"
      })
    }
  } : {}

  # Secrets da aplicação
  app_secrets = var.create_app_secrets ? {
    for secret_name, config in var.app_secrets_config : "app-${secret_name}" => {
      name        = "${local.resource_prefix}-${secret_name}"
      description = config.description != null ? config.description : "Application secret: ${secret_name}"
      
      secret_string = config.create_random_password == false ? config.value : null
      
      create_random_password    = config.create_random_password
      random_password_length   = config.password_length
      
      kms_key_id              = var.secrets_kms_key_id
      recovery_window_in_days = var.secrets_recovery_window
      replica                 = local.default_replica_config
      
      tags = merge(local.common_tags, {
        SecretType = "application"
        Component  = secret_name
      })
    }
  } : {}

  # Merge de todos os secrets
  all_secrets = merge(
    var.secrets,
    local.database_secret,
    local.api_keys_secret,
    local.app_secrets
  )
}

# Data sources úteis
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Validações de configuração condicional
resource "null_resource" "validate_adot" {
  count = var.enable_adot ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(trimspace(coalesce(var.amp_remote_write_url, ""))) > 0
      error_message = "Quando enable_adot for verdadeiro, amp_remote_write_url deve ser informado."
    }

    precondition {
      condition     = length(trimspace(coalesce(var.assume_role_arn, ""))) > 0
      error_message = "Quando enable_adot for verdadeiro, assume_role_arn deve ser informado."
    }

    precondition {
      condition     = length(trimspace(coalesce(var.log_group, ""))) > 0
      error_message = "Quando enable_adot for verdadeiro, log_group deve ser informado."
    }
  }
}

resource "null_resource" "validate_alb_routing" {
  count = var.enable_alb_routing ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(trimspace(coalesce(var.listener_arn, ""))) > 0
      error_message = "Quando enable_alb_routing for verdadeiro, listener_arn deve ser informado."
    }

    precondition {
      condition     = length(trimspace(coalesce(var.vpc_id, ""))) > 0
      error_message = "Quando enable_alb_routing for verdadeiro, vpc_id deve ser informado."
    }

    precondition {
      condition     = var.priority > 0 && var.priority <= 50000
      error_message = "Quando enable_alb_routing for verdadeiro, priority deve estar entre 1 e 50000."
    }
  }
}

module "secrets_manager" {
  for_each = var.enable_secrets_manager ? local.all_secrets : {}
  source   = "./aws-secrets-manager"

  # Basic configuration
  create                         = true
  region                        = var.region
  name                          = each.value.name
  name_prefix                   = each.value.name_prefix
  description                   = each.value.description
  kms_key_id                    = each.value.kms_key_id
  recovery_window_in_days       = each.value.recovery_window_in_days
  force_overwrite_replica_secret = each.value.force_overwrite_replica_secret

  # Secret content
  secret_string            = each.value.secret_string
  secret_binary           = each.value.secret_binary
  secret_string_wo        = each.value.secret_string_wo
  secret_string_wo_version = each.value.secret_string_wo_version
  ignore_secret_changes   = each.value.ignore_secret_changes
  version_stages          = each.value.version_stages

  # Random password generation
  create_random_password            = each.value.create_random_password
  random_password_length           = each.value.random_password_length
  random_password_override_special = each.value.random_password_override_special

  # Cross-region replication
  replica = each.value.replica

  # Policy configuration
  create_policy             = each.value.create_policy
  block_public_policy      = each.value.block_public_policy
  policy_statements        = each.value.policy_statements
  source_policy_documents  = each.value.source_policy_documents
  override_policy_documents = each.value.override_policy_documents

  # Rotation configuration
  enable_rotation     = each.value.enable_rotation
  rotate_immediately  = each.value.rotate_immediately
  rotation_lambda_arn = each.value.rotation_lambda_arn
  rotation_rules      = each.value.rotation_rules

  # Tags
  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      SecretName = each.key
      ManagedBy  = "terraform"
    }
  )
}