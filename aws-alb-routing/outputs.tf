output "target_group_arn" {
  description = "ARN do Target Group criado"
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Nome do Target Group"
  value       = aws_lb_target_group.this.name
}

output "listener_rule_arn" {
  description = "ARN da Listener Rule criada"
  value       = aws_lb_listener_rule.this.arn
}