output "service_name" {
  value       = aws_ecs_service.this.name
  description = "Nome do Serviço ECS."
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "ARN da definição da task criada."
}

output "ecs_sg_id" {
  description = "ID do Security Group do ECS"
  value       = aws_security_group.ecs_sg.id
}

output "container_port" {
  description = "Porta do container ECS"
  value       = var.container_port
}

output "ecs_cloudwatch_log_group_name" {
  description = "Nome do Log Group do ECS"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.this[0].name : null
}

output "cluster_id" {
  description = "ID do ECS Cluster (criado ou existente)"
  value       = local.cluster_id
}

output "cluster_name" {
  description = "Nome do ECS Cluster (criado ou existente)"
  value       = local.cluster_name
}

output "cluster_arn" {
  description = "ARN do ECS Cluster (criado ou existente)"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].arn : null
}

output "execution_role_name" {
  description = "Nome da IAM Execution Role do ECS"
  value       = var.execution_role_arn == null ? aws_iam_role.execution[0].name : replace(var.execution_role_arn, "arn:aws:iam::[0-9]+:role/", "")
}

output "execution_role_arn" {
  description = "ARN da IAM Execution Role do ECS"
  value       = var.execution_role_arn != null ? var.execution_role_arn : aws_iam_role.execution[0].arn
}

output "task_role_name" {
  description = "Nome da IAM Role associada às tasks ECS"
  value       = var.task_role_arn == null ? aws_iam_role.task[0].name : replace(var.task_role_arn, "arn:aws:iam::[0-9]+:role/", "")
}

output "task_role_arn" {
  description = "ARN da IAM Role associada às tasks ECS"
  value       = var.task_role_arn != null ? var.task_role_arn : aws_iam_role.task[0].arn
}