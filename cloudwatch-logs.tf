resource "aws_cloudwatch_log_group" "this" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = local.cloudwatch_log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${var.application}-${var.environment}"
  })
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = var.enable_cloudwatch_logs ? var.metric_filters : {}

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.this[0].name
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric_name
    namespace = each.value.metric_namespace
    value     = each.value.metric_value
  }
}

resource "aws_cloudwatch_log_subscription_filter" "this" {
  count = var.enable_cloudwatch_logs && var.destination_arn != null ? 1 : 0

  name            = "${var.application}-${var.environment}-subscription"
  log_group_name  = aws_cloudwatch_log_group.this[0].name
  destination_arn = var.destination_arn
  filter_pattern  = var.subscription_filter_pattern
  distribution    = "ByLogStream"
  role_arn        = var.subscription_role_arn
}
