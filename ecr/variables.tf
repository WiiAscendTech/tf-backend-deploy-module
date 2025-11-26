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
