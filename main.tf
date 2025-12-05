data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  task_role_name = "${var.application}-ecs-task-role-${var.environment}"
}

module "adot" {
  source = "./adot"

  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  tags         = var.tags

  region                 = var.region
  amp_remote_write_url   = var.amp_remote_write_url
  adot_sigv4_assume_role_arn = var.adot_sigv4_assume_role_arn
  amp_workspace_arn      = var.amp_workspace_arn
  assume_role_principals = var.adot_assume_role_principals
  task_role_arn          = null
  log_group              = var.log_group
  log_stream_prefix      = var.log_stream_prefix
  volume_name            = var.volume_name
  image                  = var.adot_image
  adot_cpu               = var.adot_cpu
  adot_memory            = var.adot_memory
  enable_metrics         = var.enable_metrics
  environment_variables  = var.adot_environment_variables
  container_name         = var.adot_container_name
}

module "alb" {
  source = "./alb"

  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  tags         = var.tags

  create_alb                       = var.create_alb
  subnet_ids                       = var.create_alb ? var.alb_subnet_ids : []
  alb_internal                     = var.alb_internal
  allowed_cidr_blocks              = var.alb_allowed_cidr_blocks
  enable_https                     = var.alb_enable_https
  certificate_arn                  = var.alb_certificate_arn
  ssl_policy                       = var.alb_ssl_policy
  https_redirect                   = var.alb_https_redirect
  enable_deletion_protection       = var.alb_enable_deletion_protection
  enable_http2                     = var.alb_enable_http2
  enable_cross_zone_load_balancing = var.alb_enable_cross_zone_load_balancing
  idle_timeout                     = var.alb_idle_timeout
  ip_address_type                  = var.alb_ip_address_type
  access_logs_bucket               = var.alb_access_logs_bucket
  access_logs_prefix               = var.alb_access_logs_prefix

  listener_arn  = var.create_alb ? null : var.listener_arn
  priority      = var.create_alb ? null : var.alb_priority
  path_patterns = var.path_patterns
  host_headers  = var.host_headers

  port        = var.container_port
  protocol    = var.alb_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check_enabled             = var.health_check_enabled
  health_check_path                = var.health_check_path
  health_check_interval            = var.health_check_interval
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  health_check_matcher             = var.health_check_matcher
  health_check_protocol            = var.health_check_protocol
  health_check_port                = var.health_check_port

  deregistration_delay = var.target_group_deregistration_delay
  slow_start           = var.target_group_slow_start
  enable_stickiness    = var.target_group_enable_stickiness
  stickiness_type      = var.target_group_stickiness_type
  cookie_duration      = var.target_group_cookie_duration
}

module "ecr" {
  source = "./ecr"

  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  tags         = var.tags

  image_tag_mutability    = var.ecr_image_tag_mutability
  scan_on_push            = var.ecr_scan_on_push
  protected_tags          = var.ecr_protected_tags
  encryption_type         = var.ecr_encryption_type
  enable_lifecycle_policy = var.ecr_enable_lifecycle_policy
  max_image_count         = var.ecr_max_image_count
}

module "ecs" {
  source = "./ecs"

  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  tags         = var.tags

  create_cluster                = var.create_cluster
  cluster_id                    = var.cluster_id
  cluster_name                  = var.cluster_name
  task_cpu                      = var.task_cpu
  task_memory                   = var.task_memory
  container_cpu                 = var.container_cpu
  container_memory              = var.container_memory
  execution_role_arn            = var.execution_role_arn
  task_role_arn                 = var.task_role_arn
  task_role_policy_json         = var.task_role_policy_json
  task_role_managed_policy_arns = var.task_managed_policy_arns
  desired_count                 = var.desired_count
  subnet_ids                    = var.subnet_ids
  assign_public_ip              = var.assign_public_ip
  container_name                = var.application
  container_port                = var.container_port
  vpc_id                        = var.vpc_id
  alb_sg_id                     = var.create_alb ? module.alb.alb_security_group_id : var.alb_sg_id
  allowed_sg_ids                = var.allowed_sg_ids
  capacity_provider_strategy    = var.capacity_provider_strategy
  volumes                       = var.volumes
  ecs_environment_variables     = var.ecs_environment_variables
  ecs_secrets = concat(
    var.ecs_secrets,
    var.create_secret ? [
      {
        name      = "SECRET_MANAGER_ARN"
        valueFrom = module.secrets_manager[0].secret_arn
      }
    ] : []
  )
  enable_autoscaling                = var.enable_autoscaling
  autoscaling_min_capacity          = var.autoscaling_min_capacity
  autoscaling_max_capacity          = var.autoscaling_max_capacity
  autoscaling_cpu_target_value      = var.autoscaling_cpu_target_value
  autoscaling_requests_target_value = var.autoscaling_requests_target_value
  load_balancer_arn_suffix          = var.load_balancer_arn_suffix
  autoscaling_scale_in_cooldown     = var.autoscaling_scale_in_cooldown
  autoscaling_scale_out_cooldown    = var.autoscaling_scale_out_cooldown
  log_group                         = var.log_group
  cloudwatch_log_retention_days     = var.cloudwatch_log_retention_days
  region                            = var.region
  enable_firelens                   = var.enable_firelens
  enable_loki                       = var.enable_loki
  enable_cloudwatch_logs            = var.enable_cloudwatch_logs
  loki_host                         = var.loki_host
  loki_port                         = var.loki_port
  loki_tls                          = var.loki_tls
  loki_tenant_id                    = var.loki_tenant_id
  s3_logs_bucket_name               = var.enable_firelens && module.firelens.firelens_s3_bucket_name != null ? module.firelens.firelens_s3_bucket_name : var.s3_logs_bucket_name
  s3_logs_prefix                    = var.s3_logs_prefix
  s3_logs_storage_class             = var.s3_logs_storage_class
  fluent_total_file_size            = var.fluent_total_file_size
  fluent_upload_timeout             = var.fluent_upload_timeout
  fluent_compression                = var.fluent_compression
  firelens_image                    = var.firelens_image
  firelens_cpu                      = var.firelens_cpu
  firelens_memory                   = var.firelens_memory
  firelens_send_own_logs_to_cw      = var.firelens_send_own_logs_to_cw
  ecr_repository_url                = module.ecr.repository_url
  alb_target_group_arn              = module.alb.target_group_arn
  adot_container_definition_json    = module.adot.adot_container_definition

  depends_on = [
    module.ecr,
    module.alb,
    module.adot
  ]
}

module "firelens" {
  source = "./firelens"

  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  tags         = var.tags

  enable_cloudwatch_logs             = var.enable_cloudwatch_logs
  enable_firelens                    = var.enable_firelens
  log_group                          = var.log_group
  s3_logs_bucket_name                = var.s3_logs_bucket_name
  s3_logs_force_destroy              = var.s3_logs_force_destroy
  s3_logs_prefix                     = var.s3_logs_prefix
  s3_logs_storage_class              = var.s3_logs_storage_class
  s3_logs_transition_to_ia_days      = var.s3_logs_transition_to_ia_days
  s3_logs_transition_to_glacier_days = var.s3_logs_transition_to_glacier_days
  s3_logs_expiration_days            = var.s3_logs_expiration_days
  s3_logs_kms_key_arn                = var.s3_logs_kms_key_arn
  firelens_image                     = var.firelens_image
  firelens_cpu                       = var.firelens_cpu
  firelens_memory                    = var.firelens_memory
  firelens_send_own_logs_to_cw       = var.firelens_send_own_logs_to_cw
  fluent_total_file_size             = var.fluent_total_file_size
  fluent_upload_timeout              = var.fluent_upload_timeout
  fluent_compression                 = var.fluent_compression
  s3_logs_config_key                 = var.s3_logs_config_key
  retention_in_days                  = var.retention_in_days
  kms_key_id                         = var.kms_key_id
  metric_filters                     = var.metric_filters
  destination_arn                    = var.destination_arn
  subscription_filter_pattern        = var.subscription_filter_pattern
  subscription_role_arn              = var.subscription_role_arn
  aws_resource                       = var.aws_resource
  enable_loki                        = var.enable_loki
  loki_host                          = var.loki_host
  loki_port                          = var.loki_port
  loki_tls                           = var.loki_tls
  loki_tenant_id                     = var.loki_tenant_id
  task_role_arn                      = module.ecs.task_role_arn
}

# Policy que permite que a task ECS assuma a role de remote write do ADOT
data "aws_iam_policy_document" "adot_remote_write_assume_role" {
  count = var.enable_metrics ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      module.adot.remote_write_role_arn
    ]
  }
}

resource "aws_iam_policy" "adot_remote_write_assume_role" {
  count       = var.enable_metrics ? 1 : 0
  name        = "${var.application}-adot-remote-write-assume-${var.environment}"
  description = "Permite que a task ECS assuma a role de remote write do ADOT"

  policy = data.aws_iam_policy_document.adot_remote_write_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${var.application}-adot-remote-write-assume-${var.environment}"
  })

  depends_on = [
    module.ecs,
    module.adot
  ]
}

# Atualiza a trust policy da role de remote write para incluir o task_role_arn
data "aws_iam_policy_document" "adot_remote_write_trust_policy" {
  count = var.enable_metrics ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = distinct(concat(
        var.adot_assume_role_principals,
        [module.ecs.task_role_arn]
      ))
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "null_resource" "adot_remote_write_trust_policy_update" {
  count = var.enable_metrics ? 1 : 0

  triggers = {
    trust_policy = data.aws_iam_policy_document.adot_remote_write_trust_policy[0].json
    role_arn     = module.adot.remote_write_role_arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      ROLE_NAME=$(echo '${module.adot.remote_write_role_arn}' | awk -F'/' '{print $NF}')
      echo '${data.aws_iam_policy_document.adot_remote_write_trust_policy[0].json}' > /tmp/adot-trust-policy-$${ROLE_NAME}.json
      aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file:///tmp/adot-trust-policy-$${ROLE_NAME}.json
      rm -f /tmp/adot-trust-policy-$${ROLE_NAME}.json
    EOT
  }

  depends_on = [
    module.ecs,
    module.adot
  ]
}

resource "aws_iam_role_policy_attachment" "adot_remote_write_assume_role" {
  count = var.enable_metrics ? 1 : 0

  # 'role' espera o NOME da role, então extraímos do ARN
  role       = module.ecs.task_role_name
  policy_arn = aws_iam_policy.adot_remote_write_assume_role[0].arn

  depends_on = [
    module.ecs,
    module.adot,
    aws_iam_policy.adot_remote_write_assume_role,
    null_resource.adot_remote_write_trust_policy_update
  ]
}

module "secrets_manager" {
  count  = var.create_secret ? 1 : 0
  source = "./secrets-manager"

  environment  = var.environment
  project_name = var.project_name
  owner        = var.owner
  application  = var.application
  tags         = var.tags

  name_override = var.secret_name_override
  description   = var.secret_description
  secret_string = var.secret_string
  kms_key_id    = var.secret_kms_key_id
}

