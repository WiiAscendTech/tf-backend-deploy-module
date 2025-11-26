output "alb_arn" {
  description = "ARN do Application Load Balancer (se criado)"
  value       = var.create_alb ? aws_lb.this[0].arn : null
}

output "alb_dns_name" {
  description = "DNS name do Application Load Balancer (se criado)"
  value       = var.create_alb ? aws_lb.this[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID do Application Load Balancer (se criado)"
  value       = var.create_alb ? aws_lb.this[0].zone_id : null
}

output "alb_security_group_id" {
  description = "ID do Security Group do ALB (se criado)"
  value       = var.create_alb ? aws_security_group.alb[0].id : null
}

output "http_listener_arn" {
  description = "ARN do listener HTTP (se criado)"
  value       = var.create_alb ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN do listener HTTPS (se criado)"
  value       = var.create_alb && var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "listener_rule_arn" {
  description = "ARN da regra de listener criada (se usar ALB existente)"
  value       = var.create_alb || var.listener_arn == null ? null : aws_lb_listener_rule.this[0].arn
}

output "target_group_arn" {
  description = "ARN do Target Group"
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Nome do Target Group"
  value       = aws_lb_target_group.this.name
}

output "target_group_id" {
  description = "ID do Target Group"
  value       = aws_lb_target_group.this.id
}