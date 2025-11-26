resource "aws_secretsmanager_secret" "secret_manager" {
  name        = local.final_name
  description = var.description != "" ? var.description : "Secrets do backend do aplicação ${var.application} no ambiente ${var.environment}"
  kms_key_id  = var.kms_key_id
  tags        = merge(local.common_tags, { Name = local.final_name })
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  count         = var.secret_string != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret_manager.id
  secret_string = var.secret_string

  depends_on = [aws_secretsmanager_secret.secret_manager]
}
