variable "aws_profile" {
  description = "Perfil AWS a ser utilizado pelas credenciais locais"
  type        = string
  default     = null
}

variable "region" {
  description = "Região AWS para criação dos recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nome do ambiente (ex.: dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Identificador curto do projeto"
  type        = string
}

variable "owner" {
  description = "Time ou responsável pelo ambiente"
  type        = string
}

variable "application" {
  description = "Nome da aplicação principal"
  type        = string
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

variable "default_base_tags" {
  description = "Tags padrão aplicadas ao exemplo antes de mesclar com tags adicionais"
  type        = map(string)
}

variable "amp_remote_write_url" {
  description = "Endpoint de remote write do Amazon Managed Prometheus"
  type        = string
}

variable "adot_assume_role_arn" {
  description = "ARN da role assumida pelo ADOT Collector"
  type        = string
}

variable "adot_log_group_name" {
  description = "Nome do Log Group utilizado pelo ADOT Collector"
  type        = string
}

variable "enable_adot" {
  description = "Define se o ADOT Collector será habilitado no exemplo"
  type        = bool
}

variable "listener_arn" {
  description = "ARN do listener existente no ALB compartilhado"
  type        = string
}

variable "listener_rule_priority" {
  description = "Prioridade exclusiva da regra de listener para este serviço"
  type        = number
}

variable "vpc_id" {
  description = "ID da VPC onde os recursos serão provisionados"
  type        = string
}

variable "host_headers" {
  description = "Lista de host headers associados à regra do ALB"
  type        = list(string)
  default     = []
}

variable "path_patterns" {
  description = "Lista de caminhos a serem roteados para o serviço"
  type        = list(string)
  default     = ["/*"]
}

variable "existing_target_group_arn" {
  description = "ARN de um Target Group existente a ser associado ao serviço ECS"
  type        = string
}

variable "enable_alb_routing" {
  description = "Controla a criação de regras de roteamento no ALB compartilhado"
  type        = bool
}

variable "alb_target_type" {
  description = "Tipo de alvo associado ao Target Group do ALB"
  type        = string
}

variable "alb_protocol" {
  description = "Protocolo utilizado pelo listener do ALB"
  type        = string
}

variable "alb_target_group_port" {
  description = "Porta exposta pelo Target Group do ALB"
  type        = number
}

variable "alb_protocol_version" {
  description = "Versão do protocolo utilizada pelo Target Group"
  type        = string
}

variable "alb_health_check_path" {
  description = "Caminho utilizado para o health check do ALB"
  type        = string
}

variable "alb_target_group_advanced_configuration" {
  description = "Configurações avançadas aplicadas ao Target Group do ALB"
  type = object({
    deregistration_delay = number
    slow_start           = number
    stickiness = object({
      enabled         = bool
      type            = string
      cookie_duration = number
    })
  })
}

variable "private_subnet_ids" {
  description = "Lista de sub-redes privadas para rodar as tasks Fargate"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups adicionais anexados às tasks ECS"
  type        = list(string)
  default     = []
}

variable "ecs_alarm_topic_arn" {
  description = "ARN de um tópico SNS para receber alarmes do ECS"
  type        = string
  default     = null
}

variable "repository_kms_key_arn" {
  description = "ARN da chave KMS utilizada pelo repositório ECR"
  type        = string
}

variable "repository_read_access_arns" {
  description = "Identidades com acesso somente leitura ao repositório"
  type        = list(string)
  default     = []
}

variable "repository_read_write_access_arns" {
  description = "Identidades com acesso de leitura/escrita ao repositório"
  type        = list(string)
  default     = []
}

variable "enable_ecr" {
  description = "Controla a criação do repositório ECR"
  type        = bool
}

variable "repository_image_tag_mutability" {
  description = "Define a mutabilidade das tags de imagem do repositório"
  type        = string
}

variable "repository_encryption_type" {
  description = "Tipo de criptografia aplicada ao repositório ECR"
  type        = string
}

variable "enable_registry_scanning" {
  description = "Habilita a varredura automática de imagens no ECR"
  type        = bool
}

variable "registry_scan_type" {
  description = "Tipo de varredura de imagens configurada no ECR"
  type        = string
}

variable "max_image_count" {
  description = "Quantidade máxima de imagens mantidas no repositório"
  type        = number
}

variable "replication_destinations" {
  description = "Destinos adicionais para replicação de imagens do ECR"
  type = list(object({
    region      = string
    registry_id = optional(string)
  }))
  default = []
}

variable "cluster_kms_key_arn" {
  description = "ARN da chave KMS para criptografia do ECS Execute Command"
  type        = string
  default     = null
}

variable "ecs_log_group_kms_key_arn" {
  description = "ARN da chave KMS para criptografia dos logs do ECS"
  type        = string
  default     = null
}

variable "enable_ecs" {
  description = "Controla a criação do cluster e serviços ECS"
  type        = bool
}

variable "enable_fargate_spot" {
  description = "Habilita o uso de capacidade Fargate Spot"
  type        = bool
}

variable "fargate_capacity_provider_strategy" {
  description = "Estratégia de capacidade padrão para Fargate"
  type = object({
    base   = number
    weight = number
  })
}

variable "fargate_spot_capacity_provider_strategy" {
  description = "Estratégia de capacidade para Fargate Spot"
  type = object({
    base   = number
    weight = number
  })
}

variable "additional_task_execution_policies" {
  description = "Políticas IAM adicionais anexadas à task execution role"
  type        = list(string)
  default     = []
}

variable "ssm_parameter_arns" {
  description = "ARNs de parâmetros SSM acessados pelas tasks"
  type        = list(string)
  default     = []
}

variable "secrets_manager_arns" {
  description = "ARNs de secrets existentes consumidos pelas tasks"
  type        = list(string)
  default     = []
}

variable "create_ecs_alarms" {
  description = "Controla a criação de alarmes para o cluster ECS"
  type        = bool
}

variable "ecs_alarm_insufficient_data_actions" {
  description = "Lista de ações para o estado de dados insuficientes dos alarmes ECS"
  type        = list(string)
}

variable "ecs_alarm_treat_missing_data" {
  description = "Comportamento aplicado aos alarmes ECS quando não há dados"
  type        = string
}

variable "ecs_cpu_alarm_threshold" {
  description = "Limite de utilização de CPU que dispara o alarme do ECS"
  type        = number
}

variable "ecs_cpu_alarm_evaluation_periods" {
  description = "Quantidade de períodos avaliados pelo alarme de CPU do ECS"
  type        = number
}

variable "ecs_cpu_alarm_period" {
  description = "Duração, em segundos, de cada período avaliado pelo alarme de CPU"
  type        = number
}

variable "api_image" {
  description = "Imagem do container principal da API"
  type        = string
}

variable "worker_image" {
  description = "Imagem do container de worker"
  type        = string
}

variable "api_service_settings" {
  description = "Configurações detalhadas do serviço principal da API"
  type = object({
    service_name           = string
    desired_count          = number
    assign_public_ip       = bool
    enable_execute_command = bool
    app_container = object({
      name      = string
      port      = number
      protocol  = string
      log_level = string
      health_check = object({
        command      = list(string)
        interval     = number
        timeout      = number
        retries      = number
        start_period = number
      })
      additional_environment = optional(list(object({
        name  = string
        value = string
      })), [])
    })
    adot_container = object({
      name      = string
      image     = string
      essential = bool
      additional_environment = optional(list(object({
        name  = string
        value = string
      })), [])
    })
    enable_autoscaling        = bool
    autoscaling_min_capacity  = number
    autoscaling_max_capacity  = number
    autoscaling_target_cpu    = number
    autoscaling_target_memory = number
    autoscaling_request_count = object({
      enabled      = bool
      prefix       = string
      target_value = number
    })
  })
}

variable "worker_service_settings" {
  description = "Configurações aplicadas ao serviço de workers assíncronos"
  type = object({
    service_name     = string
    desired_count    = number
    assign_public_ip = bool
    container_name   = string
    environment_variables = list(object({
      name  = string
      value = string
    }))
  })
}

variable "database_secret_rotation_lambda_arn" {
  description = "ARN da função Lambda responsável por rotacionar o secret do banco"
  type        = string
  default     = null
}

variable "api_keys_rotation_lambda_arn" {
  description = "ARN da função Lambda responsável por rotacionar o agregador de API Keys"
  type        = string
}

variable "enable_secrets_manager" {
  description = "Controla a criação de recursos do AWS Secrets Manager"
  type        = bool
}

variable "secrets_recovery_window" {
  description = "Período de retenção de secrets antes da exclusão definitiva"
  type        = number
}

variable "create_database_secret" {
  description = "Determina se o secret de banco de dados será criado"
  type        = bool
}

variable "database_secret_config" {
  description = "Configurações do secret de banco de dados gerenciado"
  type = object({
    username      = string
    engine        = string
    host          = string
    port          = number
    dbname        = string
    rotation_days = number
  })
}

variable "create_api_keys_secret" {
  description = "Determina se o secret com chaves de API será criado"
  type        = bool
}

variable "api_keys_rotation_days" {
  description = "Intervalo de rotação das chaves de API"
  type        = number
}

variable "api_keys_config" {
  description = "Mapa de secrets externos que compõem o agregador de API Keys"
  type = map(object({
    secret_arn    = string
    version_stage = optional(string)
  }))
}

variable "create_app_secrets" {
  description = "Determina se os secrets da aplicação serão provisionados"
  type        = bool
}

variable "app_secrets_config" {
  description = "Configuração dos secrets internos da aplicação"
  type = map(object({
    create_random_password = optional(bool)
    password_length        = optional(number)
    description            = optional(string)
    value                  = optional(string)
  }))
}

variable "secrets_config" {
  description = "Mapa de secrets adicionais a serem criados"
  type = map(object({
    name          = string
    description   = string
    secret_string = string
  }))
}

variable "secrets_kms_key_arn" {
  description = "ARN da chave KMS padrão dos secrets"
  type        = string
  default     = null
}

variable "replica_regions" {
  description = "Regiões adicionais para replicação automática dos secrets"
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

variable "additional_secret_reader_arns" {
  description = "Identidades com permissão adicional de leitura aos secrets"
  type        = list(string)
  default     = []
}
