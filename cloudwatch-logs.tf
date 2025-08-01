resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = var.metric_filters

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric_name
    namespace = each.value.metric_namespace
    value     = each.value.metric_value
  }
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  count = var.destination_arn != null ? 1 : 0

  name            = "${var.project_name}-${var.environment}-subscription"
  log_group_name  = aws_cloudwatch_log_group.this.name
  destination_arn = var.destination_arn
  filter_pattern  = var.subscription_filter_pattern
  distribution    = "ByLogStream"
  role_arn        = var.subscription_role_arn
}
