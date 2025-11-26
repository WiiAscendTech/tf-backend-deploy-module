output "firelens_s3_bucket_name" {
  description = "Nome do bucket S3 utilizado para armazenar os logs via FireLens"
  value       = var.enable_firelens ? aws_s3_bucket.firelens_logs[0].bucket : null
}

output "firelens_s3_bucket_arn" {
  description = "ARN do bucket S3 utilizado para logs"
  value       = var.enable_firelens ? aws_s3_bucket.firelens_logs[0].arn : null
}

output "firelens_task_role_policy_arn" {
  description = "ARN da policy IAM criada para a task role do FireLens"
  value       = var.enable_firelens ? aws_iam_policy.firelens_task_role[0].arn : null
}