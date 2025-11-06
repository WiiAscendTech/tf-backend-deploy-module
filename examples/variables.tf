variable "aws_profile" {
  description = "Perfil AWS a ser utilizado pelas credenciais locais"
  type        = string
  default     = null
}

variable "region" {
  description = "Região AWS para criação dos recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nome do ambiente (ex.: dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Identificador curto do projeto"
  type        = string
}

variable "owner" {
  description = "Time ou responsável pelo ambiente"
  type        = string
}

variable "application" {
  description = "Nome da aplicação principal"
  type        = string
}

variable "tags" {
  description = "Tags adicionais aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}

variable "amp_remote_write_url" {
  description = "Endpoint de remote write do Amazon Managed Prometheus"
  type        = string
}

variable "adot_assume_role_arn" {
  description = "ARN da role assumida pelo ADOT Collector"
  type        = string
}

variable "adot_log_group_name" {
  description = "Nome do Log Group utilizado pelo ADOT Collector"
  type        = string
}

variable "listener_arn" {
  description = "ARN do listener existente no ALB compartilhado"
  type        = string
}

variable "listener_rule_priority" {
  description = "Prioridade exclusiva da regra de listener para este serviço"
  type        = number
}

variable "vpc_id" {
  description = "ID da VPC onde os recursos serão provisionados"
  type        = string
}

variable "host_headers" {
  description = "Lista de host headers associados à regra do ALB"
  type        = list(string)
  default     = []
}

variable "path_patterns" {
  description = "Lista de caminhos a serem roteados para o serviço"
  type        = list(string)
  default     = ["/*"]
}

variable "existing_target_group_arn" {
  description = "ARN de um Target Group existente a ser associado ao serviço ECS"
  type        = string
}

variable "private_subnet_ids" {
  description = "Lista de sub-redes privadas para rodar as tasks Fargate"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups adicionais anexados às tasks ECS"
  type        = list(string)
  default     = []
}

variable "ecs_alarm_topic_arn" {
  description = "ARN de um tópico SNS para receber alarmes do ECS"
  type        = string
  default     = null
}

variable "repository_kms_key_arn" {
  description = "ARN da chave KMS utilizada pelo repositório ECR"
  type        = string
}

variable "repository_read_access_arns" {
  description = "Identidades com acesso somente leitura ao repositório"
  type        = list(string)
  default     = []
}

variable "repository_read_write_access_arns" {
  description = "Identidades com acesso de leitura/escrita ao repositório"
  type        = list(string)
  default     = []
}

variable "replication_destinations" {
  description = "Destinos adicionais para replicação de imagens do ECR"
  type = list(object({
    region      = string
    registry_id = optional(string)
  }))
  default = []
}

variable "cluster_kms_key_arn" {
  description = "ARN da chave KMS para criptografia do ECS Execute Command"
  type        = string
  default     = null
}

variable "ecs_log_group_kms_key_arn" {
  description = "ARN da chave KMS para criptografia dos logs do ECS"
  type        = string
  default     = null
}

variable "additional_task_execution_policies" {
  description = "Políticas IAM adicionais anexadas à task execution role"
  type        = list(string)
  default     = []
}

variable "ssm_parameter_arns" {
  description = "ARNs de parâmetros SSM acessados pelas tasks"
  type        = list(string)
  default     = []
}

variable "secrets_manager_arns" {
  description = "ARNs de secrets existentes consumidos pelas tasks"
  type        = list(string)
  default     = []
}

variable "api_image" {
  description = "Imagem do container principal da API"
  type        = string
}

variable "worker_image" {
  description = "Imagem do container de worker"
  type        = string
}

variable "database_secret_rotation_lambda_arn" {
  description = "ARN da função Lambda responsável por rotacionar o secret do banco"
  type        = string
  default     = null
}

variable "api_keys_rotation_lambda_arn" {
  description = "ARN da função Lambda responsável por rotacionar o agregador de API Keys"
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "ARN da chave KMS padrão dos secrets"
  type        = string
  default     = null
}

variable "replica_regions" {
  description = "Regiões adicionais para replicação automática dos secrets"
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

variable "additional_secret_reader_arns" {
  description = "Identidades com permissão adicional de leitura aos secrets"
  type        = list(string)
  default     = []
}

variable "stripe_secret_arn" {
  description = "ARN do secret existente contendo credenciais Stripe"
  type        = string
}

variable "sendgrid_secret_arn" {
  description = "ARN do secret existente contendo credenciais SendGrid"
  type        = string
}
