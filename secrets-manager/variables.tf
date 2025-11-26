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

variable "kms_key_id" {
  description = "KMS Key para criptografar o segredo (opcional)"
  type        = string
  default     = null
}