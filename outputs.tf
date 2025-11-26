output "ecr_repository_url" {
  description = "URL do repositório ECR criado"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN do repositório ECR criado"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "ID do registro AWS associado ao repositório ECR"
  value       = module.ecr.registry_id
}

output "execution_role_name" {
  description = "Nome da IAM Execution Role do ECS (se criada)"
  value       = module.ecs.execution_role_name
}

output "execution_role_arn" {
  description = "ARN da IAM Execution Role do ECS (se criada)"
  value       = module.ecs.execution_role_arn
}

output "task_role_name" {
  description = "Nome da IAM Role da task criada"
  value       = module.ecs.task_role_name
}

output "task_role_arn" {
  description = "ARN da IAM Role da task criada"
  value       = module.ecs.task_role_arn
}

output "alb_arn" {
  description = "ARN do Application Load Balancer (se criado)"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "DNS name do Application Load Balancer (se criado)"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID do Application Load Balancer (se criado)"
  value       = module.alb.alb_zone_id
}

output "alb_security_group_id" {
  description = "ID do Security Group do ALB (se criado)"
  value       = module.alb.alb_security_group_id
}

output "http_listener_arn" {
  description = "ARN do listener HTTP (se criado)"
  value       = module.alb.http_listener_arn
}

output "https_listener_arn" {
  description = "ARN do listener HTTPS (se criado)"
  value       = module.alb.https_listener_arn
}

output "listener_rule_arn" {
  description = "ARN da regra de listener criada (se usar ALB existente)"
  value       = module.alb.listener_rule_arn
}

output "target_group_arn" {
  description = "ARN do Target Group"
  value       = module.alb.target_group_arn
}

output "target_group_name" {
  description = "Nome do Target Group"
  value       = module.alb.target_group_name
}

output "target_group_id" {
  description = "ID do Target Group"
  value       = module.alb.target_group_id
}

output "ecs_service_name" {
  description = "Nome do Serviço ECS"
  value       = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  description = "ARN da definição da task criada"
  value       = module.ecs.task_definition_arn
}

output "ecs_sg_id" {
  description = "ID do Security Group do ECS"
  value       = module.ecs.ecs_sg_id
}

output "ecs_container_port" {
  description = "Porta do container ECS"
  value       = module.ecs.container_port
}

output "ecs_cloudwatch_log_group_name" {
  description = "Nome do Log Group do ECS"
  value       = module.ecs.ecs_cloudwatch_log_group_name
}

output "ecs_cluster_id" {
  description = "ID do ECS Cluster (criado ou existente)"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "Nome do ECS Cluster (criado ou existente)"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN do ECS Cluster (criado ou existente)"
  value       = module.ecs.cluster_arn
}

output "adot_container_definition" {
  description = "JSON do container definition do ADOT"
  value       = module.adot.adot_container_definition
}

output "adot_remote_write_role_arn" {
  description = "ARN da role utilizada pelo ADOT para remote write"
  value       = module.adot.remote_write_role_arn
}

output "secret_arn" {
  description = "ARN do segredo criado (se aplicável)"
  value       = var.create_secret ? module.secrets_manager[0].secret_arn : null
}

output "secret_name" {
  description = "Nome do segredo criado (se aplicável)"
  value       = var.create_secret ? module.secrets_manager[0].secret_name : null
}

output "secret_id" {
  description = "ID do segredo criado (se aplicável)"
  value       = var.create_secret ? module.secrets_manager[0].secret_id : null
}

output "firelens_s3_bucket_name" {
  description = "Nome do bucket S3 utilizado para armazenar os logs via FireLens (se aplicável)"
  value       = module.firelens.firelens_s3_bucket_name
}

output "firelens_s3_bucket_arn" {
  description = "ARN do bucket S3 utilizado para logs (se aplicável)"
  value       = module.firelens.firelens_s3_bucket_arn
}

output "application_name" {
  description = "Nome da aplicação"
  value       = var.application
}

output "environment" {
  description = "Ambiente de implantação"
  value       = var.environment
}

