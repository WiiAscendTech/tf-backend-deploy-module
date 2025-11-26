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



variable "create_alb" {
  description = "Se true, cria o Application Load Balancer completo. Se false, apenas cria listener rule em ALB existente"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Lista de subnet IDs onde o ALB será criado (obrigatório se create_alb=true)"
  type        = list(string)
  default     = []
}

variable "alb_internal" {
  description = "Se true, cria um ALB interno. Se false, cria um ALB público"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "Lista de blocos CIDR permitidos para acessar o ALB (usado apenas se alb_internal=true)"
  type        = list(string)
  default     = []
}

variable "enable_https" {
  description = "Se true, habilita o listener HTTPS no ALB"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN do certificado SSL/TLS para o listener HTTPS"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "Política SSL a ser usada no listener HTTPS"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "https_redirect" {
  description = "Se true, redireciona HTTP para HTTPS automaticamente"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Se true, protege o ALB contra exclusão acidental"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Se true, habilita HTTP/2 no ALB"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Se true, habilita cross-zone load balancing"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Tempo limite de inatividade (em segundos) antes de fechar a conexão"
  type        = number
  default     = 60
}

variable "ip_address_type" {
  description = "Tipo de endereço IP (ipv4 ou dualstack)"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "O ip_address_type deve ser ipv4 ou dualstack."
  }
}

variable "access_logs_bucket" {
  description = "Nome do bucket S3 para armazenar os access logs do ALB (opcional)"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "Prefixo para os access logs no bucket S3"
  type        = string
  default     = null
}

variable "listener_arn" {
  description = "ARN do listener (HTTP ou HTTPS) ao qual a regra será associada (usado apenas se create_alb=false)"
  type        = string
  default     = null
}

variable "priority" {
  description = "Prioridade da regra de listener. Deve ser única entre regras do mesmo listener"
  type        = number
  default     = null

  validation {
    condition     = var.priority == null || (var.priority >= 1 && var.priority <= 50000)
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
  description = "Porta do health check. Use 'traffic-port' para usar a mesma porta do target"
  type        = string
  default     = null
}

variable "deregistration_delay" {
  description = "Tempo de espera (em segundos) antes de desregistrar um target durante desativação"
  type        = number
  default     = 300
}

variable "slow_start" {
  description = "Tempo de slow start (em segundos) para novos targets"
  type        = number
  default     = 0
}

variable "enable_stickiness" {
  description = "Se true, habilita sticky sessions no target group"
  type        = bool
  default     = false
}

variable "stickiness_type" {
  description = "Tipo de stickiness (lb_cookie para application load balancer)"
  type        = string
  default     = "lb_cookie"
}

variable "cookie_duration" {
  description = "Duração do cookie de stickiness (em segundos)"
  type        = number
  default     = 86400
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
  description = "ID da VPC onde o Target Group será criado"
  type        = string
}