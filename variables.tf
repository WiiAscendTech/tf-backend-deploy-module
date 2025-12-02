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
  description = "Aplicação que utiliza o recurso"
  type        = string
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
  description = "Tags padrão aplicadas aos recursos"
}

variable "ecr_image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "Mutabilidade das tags (MUTABLE ou IMMUTABLE)"
  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.ecr_image_tag_mutability)
    error_message = "O valor de ecr_image_tag_mutability deve ser 'IMMUTABLE' ou 'MUTABLE'."
  }
}

variable "ecr_scan_on_push" {
  type        = bool
  default     = true
  description = "Se true, escaneia vulnerabilidades nas imagens ao serem enviadas"
}

variable "ecr_protected_tags" {
  type        = list(string)
  default     = ["latest"]
  description = "Lista de tags protegidas que não serão removidas pela política de lifecycle"
}

variable "ecr_encryption_type" {
  type        = string
  default     = "AES256"
  description = "Tipo de criptografia (AES256 ou KMS)"
}

variable "ecr_enable_lifecycle_policy" {
  type        = bool
  default     = true
  description = "Ativa regras de lifecycle nas imagens do repositório"
}

variable "ecr_max_image_count" {
  type        = number
  default     = 10
  description = "Número máximo de imagens mantidas no repositório"
}

variable "task_role_policy_json" {
  description = "Política IAM (JSON) a ser anexada à task role"
  type        = string
  default     = null
}

variable "task_managed_policy_arns" {
  description = "Lista de ARNs de políticas gerenciadas para anexar à task role"
  type        = list(string)
  default     = []
}

variable "create_secret" {
  description = "Se true, cria um secret no AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "secret_name_override" {
  type        = string
  default     = null
  description = "Nome customizado opcional para o segredo. Substitui o padrão application-environment."
}

variable "secret_description" {
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

variable "secret_kms_key_id" {
  description = "KMS Key para criptografar o segredo (opcional)"
  type        = string
  default     = null
}

variable "create_cluster" {
  description = "Se true, cria o ECS Cluster internamente. Se false, é necessário informar cluster_id e cluster_name."
  type        = bool
  default     = true
}

variable "cluster_id" {
  type        = string
  description = "ID do ECS Cluster já existente onde o Service será criado. Obrigatório se create_cluster = false."
  default     = null
  validation {
    condition     = var.create_cluster || var.cluster_id != null
    error_message = "Se create_cluster é false, cluster_id deve ser fornecido."
  }
}

variable "cluster_name" {
  description = "Nome do ECS Cluster onde o serviço será criado. Se não informado e create_cluster = true, será gerado automaticamente."
  type        = string
  default     = null
}

variable "execution_role_arn" {
  type        = string
  description = "ARN da Execution Role do ECS (opcional). Se null, o módulo cria automaticamente."
  default     = null
}

variable "task_role_arn" {
  description = "ARN de uma task role existente (opcional). Se null, o módulo ECS criará uma nova role."
  type        = string
  default     = null
}

variable "task_cpu" {
  type        = number
  description = "CPU alocada para a Task ECS."
  default     = 512
  validation {
    condition     = contains([64, 128, 256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Valores válidos para task_cpu: 64, 128, 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  type        = number
  description = "Memória disponível para a Task ECS."
  default     = 1024
  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192], var.task_memory)
    error_message = "Valores válidos para task_memory: 128, 256, 512, 1024, 2048, ..., 8192."
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

variable "container_port" {
  type        = number
  description = "Porta do container exposta ao Load Balancer."
  default     = 80
}

variable "vpc_id" {
  description = "ID da VPC onde o ECS será criado"
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

variable "adot_sigv4_assume_role_arn" {
  description = "Role que o ADOT deve assumir para assinar as chamadas SigV4 (ex.: terraform-backend-access-role na conta de observabilidade)"
  type        = string
  default     = null
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
  type = list(object({
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
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

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

variable "create_alb" {
  description = "Se true, cria o Application Load Balancer completo. Se false, apenas cria listener rule em ALB existente"
  type        = bool
  default     = false
}

variable "alb_subnet_ids" {
  description = "Lista de subnet IDs onde o ALB será criado (obrigatório se create_alb=true)"
  type        = list(string)
  default     = []
}

variable "alb_internal" {
  description = "Se true, cria um ALB interno. Se false, cria um ALB público"
  type        = bool
  default     = false
}

variable "alb_allowed_cidr_blocks" {
  description = "Lista de blocos CIDR permitidos para acessar o ALB (usado apenas se alb_internal=true)"
  type        = list(string)
  default     = []
}

variable "alb_enable_https" {
  description = "Se true, habilita o listener HTTPS no ALB"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ARN do certificado SSL/TLS para o listener HTTPS"
  type        = string
  default     = null
}

variable "alb_ssl_policy" {
  description = "Política SSL a ser usada no listener HTTPS"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_https_redirect" {
  description = "Se true, redireciona HTTP para HTTPS automaticamente"
  type        = bool
  default     = true
}

variable "alb_enable_deletion_protection" {
  description = "Se true, protege o ALB contra exclusão acidental"
  type        = bool
  default     = false
}

variable "alb_enable_http2" {
  description = "Se true, habilita HTTP/2 no ALB"
  type        = bool
  default     = true
}

variable "alb_enable_cross_zone_load_balancing" {
  description = "Se true, habilita cross-zone load balancing"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "Tempo limite de inatividade (em segundos) antes de fechar a conexão"
  type        = number
  default     = 60
}

variable "alb_ip_address_type" {
  description = "Tipo de endereço IP (ipv4 ou dualstack)"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack"], var.alb_ip_address_type)
    error_message = "O alb_ip_address_type deve ser ipv4 ou dualstack."
  }
}

variable "alb_access_logs_bucket" {
  description = "Nome do bucket S3 para armazenar os access logs do ALB (opcional)"
  type        = string
  default     = null
}

variable "alb_access_logs_prefix" {
  description = "Prefixo para os access logs no bucket S3"
  type        = string
  default     = null
}

variable "listener_arn" {
  description = "ARN do listener (HTTP ou HTTPS) ao qual a regra será associada (usado apenas se create_alb=false)"
  type        = string
  default     = null
}

variable "alb_priority" {
  description = "Prioridade da regra de listener. Deve ser única entre regras do mesmo listener (usado apenas se create_alb=false)"
  type        = number
  default     = null

  validation {
    condition     = var.alb_priority == null || (var.alb_priority >= 1 && var.alb_priority <= 50000)
    error_message = "Priority must be between 1 and 50000."
  }
}

variable "path_patterns" {
  description = "Lista de padrões de path que ativam a regra (ex: ['/api/*'])"
  type        = list(string)
  default     = []
}

variable "host_headers" {
  description = "Lista de domínios (host headers) que ativam a regra, ex: ['api.example.com']"
  type        = list(string)
  default     = []
}

variable "health_check_enabled" {
  description = "Se true, habilita o health check"
  type        = bool
  default     = true
}

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

variable "health_check_protocol" {
  description = "Protocolo do health check (HTTP ou HTTPS)"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.health_check_protocol)
    error_message = "O protocolo do health check deve ser HTTP, HTTPS ou TCP."
  }
}

variable "health_check_port" {
  description = "Porta do health check. Use null para usar a mesma porta do target"
  type        = string
  default     = null
}

variable "alb_protocol" {
  description = "Protocolo do Load Balancer (HTTP ou HTTPS)"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.alb_protocol)
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

variable "target_group_deregistration_delay" {
  description = "Tempo de espera (em segundos) antes de desregistrar um target durante desativação"
  type        = number
  default     = 300
}

variable "target_group_slow_start" {
  description = "Tempo de slow start (em segundos) para novos targets"
  type        = number
  default     = 0
}

variable "target_group_enable_stickiness" {
  description = "Se true, habilita sticky sessions no target group"
  type        = bool
  default     = false
}

variable "target_group_stickiness_type" {
  description = "Tipo de stickiness (lb_cookie para application load balancer)"
  type        = string
  default     = "lb_cookie"
}

variable "target_group_cookie_duration" {
  description = "Duração do cookie de stickiness (em segundos)"
  type        = number
  default     = 86400
}

variable "alb_sg_id" {
  description = "ID do Security Group do ALB para permitir comunicação com o ECS (usado apenas se create_alb=false)"
  type        = string
  default     = null
}

variable "allowed_sg_ids" {
  type        = list(string)
  description = "Lista de security groups que podem acessar o ECS"
  default     = []
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "amp_workspace_arn" {
  description = "ARN do workspace AMP utilizado para limitar as permissões de remote write"
  type        = string
  default     = null
}

variable "adot_assume_role_principals" {
  description = "Principais (ARNs) autorizados a assumir a role de remote write criada pelo módulo ADOT"
  type        = list(string)
  default     = []
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

variable "cloudwatch_log_retention_days" {
  description = "Retenção (em dias) aplicada ao CloudWatch Log Group criado pelo módulo ECS."
  type        = number
  default     = 30
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

variable "adot_image" {
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

variable "enable_metrics" {
  description = "Habilita pipeline de métricas com AMP"
  type        = bool
  default     = true
}

variable "adot_environment_variables" {
  description = "Variáveis de ambiente adicionais para o container ADOT"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "adot_container_name" {
  description = "Nome do container ADOT. Se não informado, será usado o padrão baseado no nome da aplicação com sufixo '-adot'"
  type        = string
  default     = null
}

variable "enable_firelens" {
  description = "Habilita o sidecar FireLens/Fluent Bit para envio de logs ao S3"
  type        = bool
  default     = false
}

variable "enable_loki" {
  description = "Se true, envia logs também para o Loki via Fluent Bit"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Controla a criação e utilização do CloudWatch Logs"
  type        = bool
  default     = true
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

variable "loki_host" {
  description = "Host/DNS do endpoint Loki (ex: loki-nlb-dev.internal)"
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

variable "loki_security_group_id" {
  description = "ID do Security Group do Loki (usado para permitir tráfego do ECS)"
  type        = string
  default     = null
}

