# =============================================================================
# COMMON VARIABLES
# =============================================================================

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser dev, staging ou prod."
  }
}

variable "project_name" {
  description = "Nome do projeto para prefixar recursos"
  type        = string
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name deve ter entre 1 e 20 caracteres."
  }
}

variable "owner" {
  description = "Time responsável pelo recurso"
  type        = string
}

variable "application" {
  description = "Nome da aplicação que utiliza o recurso"
  type        = string
}

variable "region" {
  description = "AWS region onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags personalizadas aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

# =============================================================================
# ADOT CONFIGURATION VARIABLES
# =============================================================================

variable "enable_adot" {
  description = "Habilita o ADOT Collector como sidecar"
  type        = bool
  default     = true
}

variable "adot_container_name" {
  description = "Nome do container ADOT"
  type        = string
  default     = "adot-collector"
}

variable "adot_image" {
  description = "Imagem do ADOT Collector"
  type        = string
  default     = "amazon/aws-otel-collector:latest"
}

variable "adot_cpu" {
  description = "CPU para o container ADOT (em unidades de CPU)"
  type        = number
  default     = 128
  validation {
    condition     = var.adot_cpu >= 128 && var.adot_cpu <= 4096
    error_message = "ADOT CPU deve estar entre 128 e 4096 unidades."
  }
}

variable "adot_memory" {
  description = "Memória para o container ADOT (em MB)"
  type        = number
  default     = 256
  validation {
    condition     = var.adot_memory >= 256 && var.adot_memory <= 8192
    error_message = "ADOT Memory deve estar entre 256 e 8192 MB."
  }
}

variable "enable_traces" {
  description = "Habilita pipeline de traces com AWS X-Ray"
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Habilita pipeline de métricas com Amazon Managed Prometheus"
  type        = bool
  default     = true
}

variable "amp_remote_write_url" {
  description = "URL do endpoint de remote write do Amazon Managed Prometheus"
  type        = string
}

variable "assume_role_arn" {
  description = "ARN da IAM role que o ADOT Collector deve assumir para acessar AMP"
  type        = string
}

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

variable "log_group" {
  description = "Nome do CloudWatch Log Group para os logs do ADOT"
  type        = string
}

variable "log_stream_prefix" {
  description = "Prefixo dos streams de log no CloudWatch"
  type        = string
  default     = "adot"
}

# =============================================================================
# ADDITIONAL CONFIGURATION
# =============================================================================

variable "adot_environment_variables" {
  description = "Variáveis de ambiente adicionais para o container ADOT"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "volume_name" {
  description = "Nome do volume da task para montar configurações"
  type        = string
  default     = "adot-config"
}

# =============================================================================
# ALB ROUTING CONFIGURATION
# =============================================================================

variable "enable_alb_routing" {
  description = "Habilita o módulo de roteamento ALB"
  type        = bool
  default     = true
}

variable "listener_arn" {
  description = "ARN do Listener (443/80) no ALB compartilhado"
  type        = string
}

variable "vpc_id" {
  description = "VPC onde o Target Group será criado"
  type        = string
}

variable "priority" {
  description = "Prioridade única da regra no listener"
  type        = number
  validation {
    condition     = var.priority >= 1 && var.priority <= 50000
    error_message = "Priority deve estar entre 1 e 50000."
  }
}

variable "host_headers" {
  description = "Lista de hosts (Host header) para a regra. Deixe vazio se não usar"
  type        = list(string)
  default     = []
}

variable "path_patterns" {
  description = "Lista de caminhos para a regra (ex.: [/ , /api/*])"
  type        = list(string)
  default     = ["/*"]
}

variable "target_type" {
  description = "Tipo do alvo no Target Group: instance | ip | lambda"
  type        = string
  default     = "ip"
  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type deve ser instance, ip ou lambda."
  }
}

variable "protocol" {
  description = "Protocolo do Target Group (HTTP/HTTPS/TCP/UDP)"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "UDP", "TCP_UDP", "TLS"], var.protocol)
    error_message = "Protocol deve ser HTTP, HTTPS, TCP, UDP, TCP_UDP ou TLS."
  }
}

variable "port" {
  description = "Porta do Target Group (não usado se target_type = lambda)"
  type        = number
  default     = 80
  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port deve estar entre 1 e 65535."
  }
}

variable "protocol_version" {
  description = "HTTP1 | HTTP2 | GRPC (quando aplicável ao TG)"
  type        = string
  default     = "HTTP1"
  validation {
    condition     = contains(["HTTP1", "HTTP2", "GRPC"], var.protocol_version)
    error_message = "Protocol version deve ser HTTP1, HTTP2 ou GRPC."
  }
}

# =============================================================================
# HEALTH CHECK CONFIGURATION
# =============================================================================

variable "health_check_path" {
  description = "Caminho do health check (HTTP/HTTPS)"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Intervalo do health check em segundos"
  type        = number
  default     = 30
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval deve estar entre 5 e 300 segundos."
  }
}

variable "health_check_timeout" {
  description = "Timeout do health check em segundos"
  type        = number
  default     = 5
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout deve estar entre 2 e 120 segundos."
  }
}

variable "health_check_healthy_threshold" {
  description = "Número de health checks consecutivos para considerar healthy"
  type        = number
  default     = 3
  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Health check healthy threshold deve estar entre 2 e 10."
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Número de health checks consecutivos para considerar unhealthy"
  type        = number
  default     = 3
  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Health check unhealthy threshold deve estar entre 2 e 10."
  }
}

variable "health_check_matcher" {
  description = "Matcher de HTTP codes (ex.: 200-399)"
  type        = string
  default     = "200-399"
}

# =============================================================================
# TARGET GROUP ADVANCED CONFIGURATION
# =============================================================================

variable "tg_advanced" {
  description = "Configurações avançadas do Target Group"
  type = object({
    deregistration_delay              = optional(number)
    connection_termination            = optional(bool)
    slow_start                        = optional(number)
    proxy_protocol_v2                 = optional(bool)
    load_balancing_algorithm_type     = optional(string)
    load_balancing_cross_zone_enabled = optional(string)
    stickiness = optional(object({
      enabled         = bool
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))
    protocol_version   = optional(string)
    ip_address_type    = optional(string)
    preserve_client_ip = optional(string)
  })
  default = null
}

# =============================================================================
# LAMBDA CONFIGURATION (when target_type = lambda)
# =============================================================================

variable "lambda_function_arn" {
  description = "ARN da função Lambda quando target_type = lambda"
  type        = string
  default     = null
}

variable "lambda_attach_permission" {
  description = "Cria aws_lambda_permission para o ALB invocar a função"
  type        = bool
  default     = true
}

# =============================================================================
# ECR CONFIGURATION
# =============================================================================

variable "enable_ecr" {
  description = "Habilita o módulo ECR para criar repositório de containers"
  type        = bool
  default     = true
}

variable "ecr_repository_name" {
  description = "Nome do repositório ECR. Se não especificado, usa application-environment"
  type        = string
  default     = ""
}

variable "repository_type" {
  description = "Tipo do repositório ECR: private ou public"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["private", "public"], var.repository_type)
    error_message = "Repository type deve ser private ou public."
  }
}

variable "repository_image_tag_mutability" {
  description = "Configuração de mutabilidade das tags: MUTABLE, MUTABLE_WITH_EXCLUSION, IMMUTABLE ou IMMUTABLE_WITH_EXCLUSION"
  type        = string
  default     = "MUTABLE"
  validation {
    condition = contains([
      "MUTABLE", 
      "MUTABLE_WITH_EXCLUSION", 
      "IMMUTABLE", 
      "IMMUTABLE_WITH_EXCLUSION"
    ], var.repository_image_tag_mutability)
    error_message = "Image tag mutability deve ser MUTABLE, MUTABLE_WITH_EXCLUSION, IMMUTABLE ou IMMUTABLE_WITH_EXCLUSION."
  }
}

variable "repository_encryption_type" {
  description = "Tipo de criptografia para o repositório: KMS ou AES256"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["KMS", "AES256"], var.repository_encryption_type)
    error_message = "Encryption type deve ser KMS ou AES256."
  }
}

variable "repository_kms_key" {
  description = "ARN da chave KMS para criptografia (obrigatório se encryption_type = KMS)"
  type        = string
  default     = null
}

variable "repository_image_scan_on_push" {
  description = "Habilita scan de vulnerabilidades ao fazer push de imagens"
  type        = bool
  default     = true
}

variable "repository_force_delete" {
  description = "Permite deletar o repositório mesmo se contiver imagens"
  type        = bool
  default     = false
}

# =============================================================================
# ECR ACCESS CONTROL
# =============================================================================

variable "repository_read_access_arns" {
  description = "ARNs de usuários/roles com acesso de leitura ao repositório"
  type        = list(string)
  default     = []
}

variable "repository_read_write_access_arns" {
  description = "ARNs de usuários/roles com acesso de leitura/escrita ao repositório"
  type        = list(string)
  default     = []
}

variable "repository_lambda_read_access_arns" {
  description = "ARNs de funções Lambda com acesso de leitura ao repositório"
  type        = list(string)
  default     = []
}

# =============================================================================
# ECR LIFECYCLE POLICY
# =============================================================================

variable "create_lifecycle_policy" {
  description = "Cria política de lifecycle para limpeza automática de imagens"
  type        = bool
  default     = true
}

variable "repository_lifecycle_policy" {
  description = "Política de lifecycle em formato JSON para gerenciar retenção de imagens"
  type        = string
  default     = ""
}

variable "max_image_count" {
  description = "Número máximo de imagens a manter por tag prefix (usado se repository_lifecycle_policy estiver vazio)"
  type        = number
  default     = 10
}

# =============================================================================
# ECR PUBLIC REPOSITORY CONFIG
# =============================================================================

variable "public_repository_catalog_data" {
  description = "Dados do catálogo para repositório público"
  type = object({
    about_text        = optional(string)
    architectures     = optional(list(string))
    description       = optional(string)
    logo_image_blob   = optional(string)
    operating_systems = optional(list(string))
    usage_text        = optional(string)
  })
  default = null
}

# =============================================================================
# ECR ADVANCED FEATURES
# =============================================================================

variable "enable_registry_scanning" {
  description = "Habilita configuração de scanning a nível de registry"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Tipo de scan do registry: ENHANCED ou BASIC"
  type        = string
  default     = "ENHANCED"
  validation {
    condition     = contains(["ENHANCED", "BASIC"], var.registry_scan_type)
    error_message = "Registry scan type deve ser ENHANCED ou BASIC."
  }
}

variable "enable_cross_region_replication" {
  description = "Habilita replicação cross-region do registry"
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "Lista de regiões de destino para replicação"
  type = list(object({
    region      = string
    registry_id = optional(string)
  }))
  default = []
}

variable "pull_through_cache_rules" {
  description = "Regras de pull through cache para registries externos"
  type = map(object({
    ecr_repository_prefix      = string
    upstream_registry_url      = string
    credential_arn             = optional(string)
    upstream_repository_prefix = optional(string)
  }))
  default = {}
}

# =============================================================================
# ECS CONFIGURATION
# =============================================================================

variable "enable_ecs" {
  description = "Habilita o módulo ECS para criar cluster e serviços"
  type        = bool
  default     = true
}

variable "ecs_cluster_name" {
  description = "Nome do cluster ECS. Se não especificado, usa project_name-environment"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Habilita CloudWatch Container Insights no cluster"
  type        = bool
  default     = true
}

variable "cluster_execute_command_logging" {
  description = "Habilita logging para Execute Command no cluster"
  type        = bool
  default     = true
}

variable "cluster_kms_key_id" {
  description = "ARN da chave KMS para criptografia do cluster"
  type        = string
  default     = null
}

# =============================================================================
# ECS CAPACITY PROVIDERS
# =============================================================================

variable "enable_fargate" {
  description = "Habilita Fargate como capacity provider"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Habilita Fargate Spot como capacity provider"
  type        = bool
  default     = false
}

variable "fargate_capacity_provider_strategy" {
  description = "Estratégia de capacity provider para Fargate"
  type = object({
    base   = optional(number, 1)
    weight = optional(number, 100)
  })
  default = {
    base   = 1
    weight = 100
  }
}

variable "fargate_spot_capacity_provider_strategy" {
  description = "Estratégia de capacity provider para Fargate Spot"
  type = object({
    base   = optional(number, 0)
    weight = optional(number, 0)
  })
  default = {
    base   = 0
    weight = 0
  }
}

# =============================================================================
# ECS SERVICES CONFIGURATION
# =============================================================================

variable "ecs_services" {
  description = "Configuração dos serviços ECS a serem criados"
  type = map(object({
    # Service basic configuration
    create                      = optional(bool, true)
    desired_count              = optional(number, 1)
    launch_type                = optional(string, "FARGATE")
    platform_version           = optional(string, "LATEST")
    enable_execute_command     = optional(bool, false)
    force_new_deployment       = optional(bool, false)
    wait_for_steady_state      = optional(bool, false)
    
    # Deployment configuration
    deployment_maximum_percent         = optional(number, 200)
    deployment_minimum_healthy_percent = optional(number, 100)
    deployment_circuit_breaker = optional(object({
      enable   = bool
      rollback = bool
    }), {
      enable   = true
      rollback = true
    })
    
    # Network configuration
    assign_public_ip   = optional(bool, false)
    security_group_ids = optional(list(string), [])
    subnet_ids         = list(string)
    
    # Load balancer configuration
    load_balancer = optional(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    }))
    
    # Task definition configuration
    cpu    = optional(number, 256)
    memory = optional(number, 512)
    
    # Container definitions
    container_definitions = map(object({
      image         = string
      essential     = optional(bool, true)
      cpu           = optional(number, 0)
      memory        = optional(number)
      memory_reservation = optional(number)
      
      # Port mappings
      port_mappings = optional(list(object({
        container_port = number
        host_port      = optional(number)
        protocol       = optional(string, "tcp")
        name           = optional(string)
        app_protocol   = optional(string)
      })), [])
      
      # Environment variables
      environment = optional(list(object({
        name  = string
        value = string
      })), [])
      
      # Secrets from SSM/Secrets Manager
      secrets = optional(list(object({
        name       = string
        value_from = string
      })), [])
      
      # Health check
      health_check = optional(object({
        command     = list(string)
        interval    = optional(number, 30)
        timeout     = optional(number, 5)
        retries     = optional(number, 3)
        start_period = optional(number, 0)
      }))
      
      # Logging
      enable_cloudwatch_logging = optional(bool, true)
      log_group_retention_days  = optional(number, 7)
      
      # Working directory and user
      working_directory = optional(string)
      user              = optional(string)
      
      # Command and entrypoint
      command     = optional(list(string))
      entry_point = optional(list(string))
      
      # Linux parameters
      readonly_root_filesystem = optional(bool, false)
      privileged               = optional(bool, false)
      
      # Dependencies
      depends_on = optional(list(object({
        container_name = string
        condition      = string
      })), [])
    }))
    
    # Auto Scaling
    enable_autoscaling       = optional(bool, false)
    autoscaling_min_capacity = optional(number, 1)
    autoscaling_max_capacity = optional(number, 10)
    autoscaling_target_cpu   = optional(number, 70)
    autoscaling_target_memory = optional(number, 80)
    
    # Service tags
    service_tags = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# ECS TASK EXECUTION ROLE
# =============================================================================

variable "create_task_execution_role" {
  description = "Cria role de execução de tasks compartilhada no cluster"
  type        = bool
  default     = true
}

variable "task_execution_role_name" {
  description = "Nome da role de execução de tasks"
  type        = string
  default     = ""
}

variable "additional_task_execution_policies" {
  description = "Políticas IAM adicionais para anexar à role de execução"
  type        = list(string)
  default     = []
}

variable "ssm_parameters_arns" {
  description = "ARNs de parâmetros SSM que as tasks podem acessar"
  type        = list(string)
  default     = []
}

variable "secrets_manager_arns" {
  description = "ARNs de secrets do Secrets Manager que as tasks podem acessar"
  type        = list(string)
  default     = []
}

# =============================================================================
# ECS LOGGING
# =============================================================================

variable "ecs_log_group_retention" {
  description = "Dias de retenção para logs do cluster ECS"
  type        = number
  default     = 90
}

variable "ecs_log_group_kms_key" {
  description = "ARN da chave KMS para criptografia dos logs"
  type        = string
  default     = null
}

# =============================================================================
# SECRETS MANAGER CONFIGURATION
# =============================================================================

variable "enable_secrets_manager" {
  description = "Habilita o módulo Secrets Manager para gerenciar secrets da aplicação"
  type        = bool
  default     = true
}

variable "secrets" {
  description = "Map de secrets a serem criados no Secrets Manager"
  type = map(object({
    # Basic configuration
    description                    = optional(string)
    kms_key_id                    = optional(string)
    name                          = optional(string)
    name_prefix                   = optional(string)
    recovery_window_in_days       = optional(number, 30)
    force_overwrite_replica_secret = optional(bool, false)

    # Secret content
    secret_string                 = optional(string)
    secret_binary                = optional(string)
    secret_string_wo             = optional(string)
    secret_string_wo_version     = optional(string)
    ignore_secret_changes        = optional(bool, false)
    version_stages               = optional(list(string))

    # Random password generation
    create_random_password              = optional(bool, false)
    random_password_length             = optional(number, 32)
    random_password_override_special   = optional(string, "!@#$%&*()-_=+[]{}<>:?")

    # Cross-region replication
    replica = optional(map(object({
      kms_key_id = optional(string)
      region     = optional(string)
    })), {})

    # Policy configuration
    create_policy = optional(bool, false)
    block_public_policy = optional(bool, true)
    
    policy_statements = optional(map(object({
      sid           = optional(string)
      actions       = optional(list(string))
      not_actions   = optional(list(string))
      effect        = optional(string, "Allow")
      resources     = optional(list(string))
      not_resources = optional(list(string))
      principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      not_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      condition = optional(list(object({
        test     = string
        values   = list(string)
        variable = string
      })), [])
    })), {})

    source_policy_documents   = optional(list(string), [])
    override_policy_documents = optional(list(string), [])

    # Rotation configuration
    enable_rotation      = optional(bool, false)
    rotate_immediately   = optional(bool, false)
    rotation_lambda_arn  = optional(string, "")
    rotation_rules = optional(object({
      automatically_after_days = optional(number)
      duration                 = optional(string)
      schedule_expression      = optional(string)
    }))

    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# COMMON SECRETS CONFIGURATION
# =============================================================================

variable "secrets_kms_key_id" {
  description = "ARN da chave KMS padrão para criptografia de todos os secrets"
  type        = string
  default     = null
}

variable "secrets_recovery_window" {
  description = "Janela de recuperação padrão em dias para todos os secrets"
  type        = number
  default     = 30
  validation {
    condition     = var.secrets_recovery_window >= 0 && var.secrets_recovery_window <= 30
    error_message = "Recovery window deve estar entre 0 e 30 dias."
  }
}

variable "enable_cross_region_replication" {
  description = "Habilita replicação cross-region para todos os secrets"
  type        = bool
  default     = false
}

variable "replication_regions" {
  description = "Lista de regiões para replicação automática de secrets"
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

# =============================================================================
# APPLICATION SECRETS
# =============================================================================

variable "create_database_secret" {
  description = "Cria secret para credenciais do banco de dados"
  type        = bool
  default     = false
}

variable "database_secret_config" {
  description = "Configuração do secret do banco de dados"
  type = object({
    username               = string
    password              = optional(string)
    engine                = string
    host                  = string
    port                  = number
    dbname                = string
    enable_rotation       = optional(bool, false)
    rotation_lambda_arn   = optional(string)
    rotation_days         = optional(number, 30)
  })
  default = {
    username = ""
    engine   = ""
    host     = ""
    port     = 5432
    dbname   = ""
  }
}

variable "create_api_keys_secret" {
  description = "Cria secret para chaves de APIs externas"
  type        = bool
  default     = false
}

variable "api_keys_config" {
  description = "Configuração das chaves de API"
  type = map(string)
  default = {}
  sensitive = true
}

variable "create_app_secrets" {
  description = "Cria secrets específicos da aplicação"
  type        = bool
  default     = false
}

variable "app_secrets_config" {
  description = "Configuração dos secrets da aplicação"
  type = map(object({
    value                  = optional(string)
    create_random_password = optional(bool, false)
    password_length        = optional(number, 32)
    description           = optional(string)
  }))
  default = {}
  sensitive = true
}