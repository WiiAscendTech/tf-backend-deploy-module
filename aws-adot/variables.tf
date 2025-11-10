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
}

variable "log_stream_prefix" {
  description = "Prefixo dos logs no CloudWatch"
  type        = string
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

variable "container_name" {
  type        = string
  description = "Nome do container"
}