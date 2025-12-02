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

variable "container_name" {
  description = "Nome do container ADOT. Se não informado, será usado o padrão baseado no nome da aplicação com sufixo '-adot'"
  type        = string
  default     = null
}

variable "amp_workspace_arn" {
  description = "ARN do workspace AMP utilizado para limitar a política IAM de remote write"
  type        = string
  default     = null
}

variable "assume_role_principals" {
  description = "Lista de ARNs que podem assumir a role de remote write (ex: task role do ECS). Se vazio, usa a própria conta."
  type        = list(string)
  default     = []
}

variable "task_role_arn" {
  description = "ARN da task role do ECS que será adicionada aos princípios permitidos para assumir a role de remote write"
  type        = string
  default     = null
}

variable "adot_sigv4_assume_role_arn" {
  description = "Role que o ADOT deve assumir para assinar chamadas SigV4 (ex.: terraform-backend-access-role na observability)"
  type        = string
  default     = null
}