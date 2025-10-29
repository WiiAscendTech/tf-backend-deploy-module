#################################
# LISTENER RULE
#################################
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

variable "target_group_arn" {
  description = "ARN do Target Group para onde o tráfego será direcionado"
  type        = string
}

#################################
# TARGET GROUP
#################################
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

variable "vpc_id" {
  description = "ID da VPC onde o ECS será criado"
  type        = string
}

#################################
# TAGS
#################################
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