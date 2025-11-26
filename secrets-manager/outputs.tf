output "secret_arn" {
  description = "ARN do segredo"
  value       = aws_secretsmanager_secret.secret_manager.arn
}

output "secret_name" {
  description = "Nome do segredo"
  value       = aws_secretsmanager_secret.secret_manager.name
}

output "secret_id" {
  description = "ID do segredo (necessário para data sources)"
  value       = aws_secretsmanager_secret.secret_manager.id
}

output "secret_version_id" {
  description = "ID da versão do segredo (se criada)"
  value       = try(aws_secretsmanager_secret_version.secret_version[0].version_id, null)
}