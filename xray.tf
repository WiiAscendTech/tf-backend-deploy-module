resource "aws_xray_sampling_rule" "default" {
  rule_name      = var.rule_name
  priority       = var.rule_priority
  reservoir_size = var.reservoir_size
  fixed_rate     = var.fixed_rate
  service_name   = var.service_name
  service_type   = var.service_type
  host           = var.host
  http_method    = var.http_method
  url_path       = var.url_path
  version        = 1
  resource_arn   = var.resource_arn
  attributes     = var.attributes
  depends_on     = [aws_iam_role.this]
}

resource "aws_iam_role" "xray_write" {
  name               = "${var.application}-xray-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.application}-xray-role-${var.environment}"
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = var.assume_role_services
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "xray_write" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}