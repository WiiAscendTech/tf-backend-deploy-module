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

variable "task_role_arn" {
  type        = string
  description = "Task role ARN usada pelo FireLens"

  validation {
    condition     = !var.enable_firelens || (var.enable_firelens && var.task_role_arn != "")
    error_message = "Quando enable_firelens = true, é obrigatório informar um task_role_arn válido."
  }
}
