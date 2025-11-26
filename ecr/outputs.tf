output "repository_url" {
  description = "URL do repositório ECR criado"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN do repositório ECR criado"
  value       = aws_ecr_repository.this.arn
}

output "registry_id" {
  description = "ID do registro AWS associado ao repositório ECR"
  value       = aws_ecr_repository.this.registry_id
}