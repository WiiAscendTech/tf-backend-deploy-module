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

variable "create_cluster" {
  description = "Se true, cria o ECS Cluster. Se false, usa cluster_id existente."
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
  description = "ARN da Execution Role do ECS (opcional). Se null, o módulo cria automaticamente."
  default     = null
}

variable "task_role_arn" {
  type        = string
  description = "ARN do IAM role da Task."
  default     = null
}

variable "task_role_policy_json" {
  description = "Política IAM (JSON) adicional para a task role criada pelo módulo."
  type        = string
  default     = null
}

variable "task_role_managed_policy_arns" {
  description = "Lista de ARNs de políticas gerenciadas para anexar à task role criada."
  type        = list(string)
  default     = []
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

variable "log_group" {
  description = "CloudWatch Log Group (nome completo). Se null, será gerado automaticamente."
  type        = string
  default     = null
}

variable "cloudwatch_log_retention_days" {
  description = "Retenção em dias para o CloudWatch Log Group (7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653). Se null, logs não expiram."
  type        = number
  default     = 30
}

variable "region" {
  description = "AWS region"
  type        = string
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

variable "s3_logs_bucket_name" {
  description = "Nome do bucket S3 que armazenará os logs da aplicação"
  type        = string
  default     = null
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

variable "adot_container_definition_json" {
  description = "JSON do container definition do ADOT (vindo do módulo ADOT)"
  type        = string
  default     = null
}

variable "ecr_repository_url" {
  description = "URL do repositório ECR da aplicação."
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN do Target Group do ALB para o ECS Service."
  type        = string
}