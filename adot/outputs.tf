output "adot_container_definition" {
  value = jsonencode(local.adot_container_definition)
}

output "remote_write_role_arn" {
  description = "ARN da IAM Role criada para remote write"
  value       = aws_iam_role.remote_write.arn
}

output "remote_write_policy_arn" {
  description = "ARN da IAM Policy criada para remote write"
  value       = aws_iam_policy.remote_write.arn
}

output "terraform_backend_role_arn" {
  description = "ARN da role terraform-backend-access-role"
  value       = module.terraform_backend_role.role_arn
}