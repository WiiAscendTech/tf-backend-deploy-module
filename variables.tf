// TAGS
variable "environment" {
  description = "Ambiente de implantação"
  type        = string
}

variable "project_name" {
  type        = string
  description = "Nome do projeto para prefixar recursos."
}

variable "owner" {
  description = "Time responsável pelo recurso"
  type        = string
}

variable "application" {
  description = "Aplicacão que utiliza o recurso"
  type        = string
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
  description = "Tags padrão aplicadas aos recursos"
}

// ADOT SIDECAR
variable "region" {
  description = "AWS region"
  type        = string
}

variable "amp_remote_write_url" {
  description = "AMP Remote Write endpoint"
  type        = string
}

variable "log_group" {
  description = "CloudWatch Log Group"
  type        = string
  default     = null
}

variable "log_stream_prefix" {
  description = "Prefixo dos logs no CloudWatch"
  type        = string
  default     = null
}

variable "volume_name" {
  description = "Nome do volume da task para montar o config"
  type        = string
  default     = "adot-config"
}

variable "image" {
  description = "Imagem do ADOT Collector"
  type        = string
  default     = "amazon/aws-otel-collector:latest"
}

variable "adot_cpu" {
  description = "CPU para o container ADOT"
  type        = number
  default     = 128
}

variable "adot_memory" {
  description = "Memória para o container ADOT"
  type        = number
  default     = 256
}

variable "enable_traces" {
  description = "Habilita pipeline de traces com AWS X-Ray"
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Habilita pipeline de métricas com AMP"
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Variáveis de ambiente adicionais para o container ADOT"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "assume_role_arn" {
  description = "ARN da role que o ADOT Collector deve assumir para enviar métricas para o AMP"
  type        = string
}

// ECR
variable "image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "Mutabilidade das tags (MUTABLE ou IMMUTABLE)"
  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "O valor de image_tag_mutability deve ser 'IMMUTABLE' ou 'MUTABLE'."
  }
}

variable "scan_on_push" {
  type        = bool
  default     = true
  description = "Se true, escaneia vulnerabilidades nas imagens ao serem enviadas"
}

variable "protected_tags" {
  type        = list(string)
  default     = ["latest"]
  description = "Lista de tags protegidas que não serão removidas pela política de lifecycle"
}


variable "encryption_type" {
  type        = string
  default     = "AES256"
  description = "Tipo de criptografia (AES256 ou KMS)"
}

variable "enable_lifecycle_policy" {
  type        = bool
  default     = true
  description = "Ativa regras de lifecycle nas imagens do repositório"
}

variable "max_image_count" {
  type        = number
  default     = 10
  description = "Número máximo de imagens mantidas no repositório"
}

// ECS SERVICE
variable "cluster_id" {
  type        = string
  description = "ID do ECS Cluster já existente onde o Service será criado."
}

variable "cluster_name" {
  description = "Nome do ECS Cluster onde o serviço será criado."
  type        = string
}

variable "task_cpu" {
  type        = number
  description = "CPU alocada para a Task ECS."
  default     = 512
  validation {
    condition     = contains([64, 128, 256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Valores válidos para task_cpu: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  type        = number
  description = "Memória disponível para a Task ECS."
  default     = 1024
  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192], var.task_memory)
    error_message = "Valores válidos para task_memory: 512, 1024, 2048, ..., 8192."
  }
}

variable "container_cpu" {
  description = "CPU (unidades ECS) para o container principal"
  type        = number
  default     = 256
}
variable "container_memory" {
  description = "Memória para o container principal"
  type        = number
  default     = 512
}

variable "execution_role_arn" {
  type        = string
  description = "ARN da Execution Role do ECS criada no módulo de Cluster."
}

variable "task_role_arn" {
  type        = string
  description = "ARN do IAM role da Task."
  default     = null
}

variable "desired_count" {
  type        = number
  description = "Número de instâncias desejadas."
  default     = 1
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs das subnets para o serviço ECS."
}

variable "assign_public_ip" {
  type        = bool
  description = "Determina se será atribuído IP público às tasks."
  default     = false
}

variable "container_name" {
  type        = string
  description = "Nome do container"
}

variable "container_port" {
  type        = number
  description = "Porta do container exposta ao Load Balancer."
  default     = 80
}

variable "vpc_id" {
  description = "ID da VPC onde o ECS será criado"
  type        = string
}

variable "alb_sg_id" {
  description = "ID do Security Group do ALB para permitir comunicação com o ECS"
  type        = string
}

variable "allowed_sg_ids" {
  type        = list(string)
  description = "Lista de security groups que podem acessar o ECS"
  default     = []
}

variable "ecs_execution_role_name" {
  description = "Nome do ECS Execution Role"
  type        = string
}

variable "capacity_provider_strategy" {
  description = "Estratégia de capacity provider (FARGATE ou FARGATE_SPOT)"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = null
}

variable "volumes" {
  description = "Volumes a serem adicionados na task definition (ex: para ADOT config)"
  type = list(object({
    name      = string
    host_path = optional(string)
  }))
  default = []
}

variable "ecs_environment_variables" {
  description = <<EOT
Lista de variáveis de ambiente para o container principal do ECS.
Exemplo:
[
  { name = "NODE_ENV", value = "production" },
  { name = "API_URL",  value = "https://api.exemplo.com" }
]
EOT
  type    = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "ecs_secrets" {
  description = <<EOT
Lista de secrets do AWS Secrets Manager para injetar no container principal do ECS.
Exemplo:
[
  { name = "AWS_SECRETS_JSON", valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:meu-segredo-abc123" }
]
EOT
  type    = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

# --------------- #
# AUTOSCALING     #
# --------------- #

variable "enable_autoscaling" {
  description = "Se true, habilita a configuração de Application Auto Scaling para o serviço."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Número mínimo de tarefas para o Auto Scaling."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Número máximo de tarefas para o Auto Scaling."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target_value" {
  description = "Valor alvo (em porcentagem) para o escalonamento por CPU. Ex: 75. Deixe como null para desabilitar."
  type        = number
  default     = null
}

variable "autoscaling_requests_target_value" {
  description = "Valor alvo para o número de requisições por minuto por tarefa. Deixe como null para desabilitar."
  type        = number
  default     = null
}

variable "load_balancer_arn_suffix" {
  description = "Sufixo do ARN do Load Balancer (ex: app/meu-alb/12345). Necessário para escalonamento por requisição."
  type        = string
  default     = null
}

variable "autoscaling_scale_in_cooldown" {
  description = "Tempo (em segundos) para esperar antes de uma nova atividade de scale-in (redução)."
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Tempo (em segundos) para esperar antes de uma nova atividade de scale-out (aumento)."
  type        = number
  default     = 60
}

// IAM ROLE
variable "role_name" {
  description = "Nome da IAM Role"
  type        = string
}

variable "policy_name" {
  description = "Nome da IAM Policy"
  type        = string
}

variable "role_description" {
  description = "Descrição da IAM Role"
  type        = string
  default     = null
}

variable "assume_role_policy_json" {
  description = "Política de confiança (JSON) para a IAM Role"
  type        = string
}

variable "policy_json" {
  description = "Política IAM (JSON) a ser anexada à role"
  type        = string
  default     = null
}

variable "policy_description" {
  description = "Descrição da política IAM"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefixo para compor o nome da role e policy"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Lista de ARNs de políticas gerenciadas para anexar à role"
  type        = list(string)
  default     = []
}

variable "prevent_destroy" {
  description = "Se true, protege a role/policy de destruição acidental"
  type        = bool
  default     = true
}

// LISTENER RULE
variable "listener_arn" {
  description = "ARN do listener (HTTP ou HTTPS) ao qual a regra será associada"
  type        = string
}

variable "priority" {
  description = "Prioridade da regra de listener. Deve ser única entre regras do mesmo listener"
  type        = number

  validation {
    condition     = var.priority >= 1 && var.priority <= 50000
    error_message = "Priority must be between 1 and 50000."
  }
}

variable "path_patterns" {
  description = "Lista de padrões de path que ativam a regra (ex: ['/api/*'])"
  type        = list(string)
}

variable "host_headers" {
  description = "Lista de domínios (host headers) que ativam a regra, ex: ['api.example.com']"
  type        = list(string)
  default     = []
}

// SECRETS MANAGER
variable "name_override" {
  type        = string
  default     = null
  description = "Nome customizado opcional para o segredo. Substitui o padrão project-environment."
}

variable "description" {
  type        = string
  default     = ""
  description = "Descrição opcional do segredo."
}

variable "secret_string" {
  type        = string
  sensitive   = true
  default     = null
  description = "Valor do segredo. Deixe nulo se for adicionar manualmente via Console ou CLI."
}

// TARGET GROUP
variable "health_check_path" {
  description = "Path do health check"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Tempo entre os health checks (em segundos)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Tempo limite do health check (em segundos)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Número de checks consecutivos para considerar saudável"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Número de checks consecutivos para considerar insalubre"
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "Códigos HTTP que indicam sucesso (ex: 200-399)"
  type        = string
  default     = "200-399"
}

variable "port" {
  description = "Porta do Load Balancer"
  type        = number
  default     = 80
}

variable "protocol" {
  description = "Protocolo do Load Balancer (HTTP ou HTTPS)"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.protocol)
    error_message = "O protocolo deve ser HTTP ou HTTPS."
  }
}

variable "target_type" {
  description = "Tipo de target (instance, ip, lambda)"
  type        = string
  default     = "ip"
  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "O target_type deve ser instance, ip ou lambda."
  }
}

// X-RAY
variable "rule_name" {
  description = "Nome da X-Ray sampling rule"
  type        = string
  default     = "default-sampling-rule"
}

variable "rule_priority" {
  description = "Prioridade da regra de sampling"
  type        = number
  default     = 100
}

variable "fixed_rate" {
  description = "Taxa de amostragem para a regra"
  type        = number
  default     = 0.05
}

variable "reservoir_size" {
  description = "Reservatório de requisições por segundo"
  type        = number
  default     = 1
}

variable "service_name" {
  description = "Nome do serviço alvo da regra"
  type        = string
  default     = "*"
}

variable "service_type" {
  description = "Tipo do serviço (ex: AWS::ECS::Service)"
  type        = string
  default     = "*"
}

variable "host" {
  description = "Host da requisição"
  type        = string
  default     = "*"
}

variable "http_method" {
  description = "Método HTTP para a regra"
  type        = string
  default     = "*"
}

variable "url_path" {
  description = "URL Path que será avaliado para amostragem"
  type        = string
  default     = "*"
}

variable "resource_arn" {
  description = "ARN do recurso que será amostrado"
  type        = string
  default     = "*"
}

variable "attributes" {
  description = "Atributos personalizados da regra"
  type        = map(string)
  default     = {}
}

variable "assume_role_services" {
  description = "Serviços que poderão assumir a role (ecs-tasks, lambda, etc.)"
  type        = list(string)
  default     = ["ecs-tasks.amazonaws.com"]
}

// CLOUDWATCH LOGS
variable "enable_cloudwatch_logs" {
  description = "Controla a criação e utilização do CloudWatch Logs"
  type        = bool
  default     = true
}

variable "enable_firelens" {
  description = "Habilita o sidecar FireLens/Fluent Bit para envio de logs ao S3"
  type        = bool
  default     = false
}

variable "s3_logs_bucket_name" {
  description = "Nome do bucket S3 que armazenará os logs da aplicação"
  type        = string
  default     = null
  validation {
    condition     = var.enable_firelens == false || (var.enable_firelens && var.s3_logs_bucket_name != null && trimspace(var.s3_logs_bucket_name) != "")
    error_message = "Quando enable_firelens=true é necessário informar um s3_logs_bucket_name válido."
  }
}

variable "s3_logs_force_destroy" {
  description = "Permite remover o bucket de logs mesmo com objetos dentro"
  type        = bool
  default     = false
}

variable "s3_logs_prefix" {
  description = "Prefixo/pasta onde os logs serão armazenados no bucket"
  type        = string
  default     = "apps"
}

variable "s3_logs_storage_class" {
  description = "Storage class utilizada ao gravar logs no S3"
  type        = string
  default     = "STANDARD_IA"
}

variable "s3_logs_transition_to_ia_days" {
  description = "Quantidade de dias para transicionar os objetos para STANDARD_IA"
  type        = number
  default     = 30
}

variable "s3_logs_transition_to_glacier_days" {
  description = "Quantidade de dias para transicionar os objetos para GLACIER"
  type        = number
  default     = 90
}

variable "s3_logs_expiration_days" {
  description = "Quantidade de dias para expirar os objetos de log"
  type        = number
  default     = 365
}

variable "s3_logs_kms_key_arn" {
  description = "ARN da KMS Key usada para criptografia do bucket de logs"
  type        = string
  default     = null
}

variable "firelens_image" {
  description = "Imagem utilizada pelo sidecar aws-for-fluent-bit"
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
}

variable "firelens_cpu" {
  description = "CPU alocada para o container FireLens"
  type        = number
  default     = 128
}

variable "firelens_memory" {
  description = "Memória alocada para o container FireLens"
  type        = number
  default     = 256
}

variable "firelens_send_own_logs_to_cw" {
  description = "Envia os logs do sidecar FireLens para o CloudWatch Logs"
  type        = bool
  default     = true
}

variable "fluent_total_file_size" {
  description = "Tamanho máximo do arquivo agregado pelo Fluent Bit antes do upload"
  type        = string
  default     = "50M"
}

variable "fluent_upload_timeout" {
  description = "Tempo máximo de espera para envio dos logs agregados"
  type        = string
  default     = "60s"
}

variable "fluent_compression" {
  description = "Compressão aplicada aos arquivos enviados para o S3"
  type        = string
  default     = "gzip"
}

variable "s3_logs_config_key" {
  description = "Caminho do arquivo de configuração do Fluent Bit armazenado no bucket"
  type        = string
  default     = "firelens/config/fluent-bit.conf"
}

variable "retention_in_days" {
  description = "Retenção em dias para os logs"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS Key para criptografar os logs (opcional)"
  type        = string
  default     = null
}

variable "metric_filters" {
  description = "Filtros de métricas opcionais"
  type = map(object({
    pattern          = string
    metric_name      = string
    metric_namespace = string
    metric_value     = string
  }))
  default = {}
}

variable "destination_arn" {
  description = "ARN da destination para logs (Lambda/Kinesis/etc.)"
  type        = string
  default     = null
}

variable "subscription_filter_pattern" {
  description = "Padrão de filtro para o Subscription Filter"
  type        = string
  default     = ""
}

variable "subscription_role_arn" {
  description = "IAM Role ARN para Subscription Filter (se necessário)"
  type        = string
  default     = null
}

variable "aws_resource" {
  description = "Nome do recurso AWS para prefixar os logs"
  type        = string
  default     = "cloudwatch"
}

variable "enable_loki" {
  description = "Se true, envia logs também para o Loki via Fluent Bit"
  type        = bool
  default     = false
}

variable "loki_host" {
  description = "Host/DNS do endpoint Loki (ex: loki-nlb-o11y.internal)"
  type        = string
  default     = ""
}

variable "loki_port" {
  description = "Porta do Loki (default 3100)"
  type        = number
  default     = 3100
}

variable "loki_tls" {
  description = "Se true, usa TLS na conexão com o Loki"
  type        = bool
  default     = false
}

variable "loki_tenant_id" {
  description = "Tenant ID para Loki (se multi-tenant; opcional)"
  type        = string
  default     = null
}
