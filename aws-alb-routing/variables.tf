##############################################
# Inputs
##############################################

variable "application" {
  description = "Nome lógico da aplicação (ex.: orders-api)"
  type        = string
}

variable "environment" {
  description = "Ambiente (ex.: dev, stg, prod)"
  type        = string
}

variable "listener_arn" {
  description = "ARN do Listener (443/80) no ALB compartilhado"
  type        = string
}

variable "priority" {
  description = "Prioridade única da regra no listener"
  type        = number
}

variable "host_headers" {
  description = "Lista de hosts (Host header) para a regra. Deixe vazio se não usar."
  type        = list(string)
  default     = []
}

variable "path_patterns" {
  description = "Lista de caminhos para a regra (ex.: [/ , /api/*])"
  type        = list(string)
  default     = ["/*"]
}

variable "vpc_id" {
  description = "VPC onde o Target Group será criado"
  type        = string
}

variable "target_type" {
  description = "Tipo do alvo no Target Group: instance | ip | lambda"
  type        = string
  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type deve ser instance, ip ou lambda."
  }
}

variable "protocol" {
  description = "Protocolo do Target Group (HTTP/HTTPS/TCP/GPU/...) - deixe null para lambda"
  type        = string
  default     = "HTTP"
}

variable "port" {
  description = "Porta do Target Group (não usado se target_type = lambda)"
  type        = number
  default     = 80
}

variable "protocol_version" {
  description = "HTTP1 | HTTP2 | GRPC (quando aplicável ao TG)"
  type        = string
  default     = null
}

# Health check simples (você pode trocar por objeto avançado se quiser)
variable "health_check_path" {
  description = "Caminho do health check (HTTP/HTTPS)"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Intervalo (s)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout (s)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Limiar de saudável"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Limiar de insalubre"
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "Matcher de HTTP codes (ex.: 200-399)"
  type        = string
  default     = "200,201,202"
}

# Avançados do TG (opt-ins)
variable "tg_advanced" {
  description = <<EOT
Parâmetros avançados opcionais do Target Group.
Exemplo:
tg_advanced = {
  deregistration_delay              = 60
  connection_termination            = true
  slow_start                        = 0
  proxy_protocol_v2                 = null
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  stickiness = {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 86400
    cookie_name     = null
  }
  protocol_version = "HTTP1"
  ip_address_type  = null
  preserve_client_ip = null
}
EOT
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

# Suporte a Lambda (só para target_type = "lambda")
variable "lambda_function_arn" {
  description = "ARN da função Lambda quando target_type = lambda"
  type        = string
  default     = null
}

variable "lambda_attach_permission" {
  description = "Cria aws_lambda_permission para o ALB invocar a função?"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags padrão"
  type        = map(string)
  default     = {}
}