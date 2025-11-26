# ============================================
# EXEMPLO DE USO CORRIGIDO DO MÓDULO
# ============================================
# 
# Este exemplo mostra como usar o módulo quando:
# - O ALB já existe (criado externamente)
# - Você precisa apenas criar:
#   * Target Group (para conectar ECS ao ALB)
#   * Listener Rule (para rotear tráfego)
# 
# Variáveis relacionadas à criação do ALB foram removidas.
# ============================================

data "aws_alb" "this" {
  arn = data.terraform_remote_state.core_infra.outputs.alb_arn
}

locals {
  s3_logs_bucket_name = "backend-kyc-dev"
  s3_logs_kms_key_arn = null
}

module "backend_stack" {
  source = "git@github.com:WiiAscendTech/tf-backend-deploy-module"

  # Variáveis de ambiente
  environment  = "dev"
  project_name = "kyc"
  owner        = "Backend Team"
  application  = "backend-kyc"
  region       = "us-east-1"

  # ECS Service
  cluster_id         = data.terraform_remote_state.core_infra.outputs.cluster_id
  cluster_name       = data.terraform_remote_state.core_infra.outputs.cluster_name
  execution_role_arn = data.terraform_remote_state.core_infra.outputs.ecs_execution_role_arn
  # NOTA: ecs_execution_role_name não existe - removido

  task_cpu      = 512
  task_memory   = 1024
  container_cpu = 256
  container_memory = 512
  desired_count = 1
  subnet_ids     = data.terraform_remote_state.core_infra.outputs.private_subnet_ids
  assign_public_ip = false

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }
  ]

  container_port = 3001
  vpc_id         = data.terraform_remote_state.core_infra.outputs.vpc_id
  alb_sg_id      = data.terraform_remote_state.core_infra.outputs.alb_sg_id

  enable_autoscaling           = true
  autoscaling_min_capacity     = 1
  autoscaling_max_capacity     = 2
  autoscaling_cpu_target_value = 80
  load_balancer_arn_suffix     = data.aws_alb.this.arn_suffix

  ecs_secrets = [
    {
      name      = "AWS_SECRETS_JSON"
      valueFrom = module.backend_stack.secret_arn
    }
  ]

  ecs_environment_variables = [
    {
      name  = "NODE_ENV"
      value = "development"
    }
  ]

  # ECR Repository - CORRIGIDO: prefixo "ecr_" nas variáveis
  ecr_image_tag_mutability    = "MUTABLE"
  ecr_scan_on_push            = true
  ecr_encryption_type         = "AES256"
  ecr_enable_lifecycle_policy = true
  ecr_max_image_count         = 10

  # =========================
  # ALB: Listener Rule + Target Group
  # =========================
  # NOTA: O ALB já existe, este módulo cria apenas:
  # - Target Group (para conectar o ECS ao ALB)
  # - Listener Rule (para rotear tráfego para o Target Group)
  #
  # Variáveis NÃO necessárias quando create_alb = false:
  # - alb_subnet_ids, alb_internal, allowed_cidr_blocks
  # - alb_enable_https, alb_certificate_arn, alb_ssl_policy
  # - alb_https_redirect, alb_enable_deletion_protection
  # - alb_enable_http2, alb_enable_cross_zone_load_balancing
  # - alb_idle_timeout, alb_ip_address_type
  # - alb_access_logs_bucket, alb_access_logs_prefix
  
  create_alb = false  # ALB já existe, não criar

  # Target Group Configuration
  alb_protocol  = "HTTP"  # Protocolo do Target Group
  target_type   = "ip"    # Tipo de target (ip para Fargate)

  # Health Check Configuration
  health_check_path                = "/health/live"
  health_check_interval            = 30
  health_check_timeout             = 5
  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 3
  health_check_matcher             = "200-399"
  health_check_protocol            = "HTTP"  # Protocolo do health check

  # Listener Rule Configuration (para ALB existente)
  listener_arn  = data.terraform_remote_state.core_infra.outputs.alb_listener_arn_https
  alb_priority   = 13  # Prioridade da regra (deve ser única no listener)
  path_patterns = ["/*"]  # Padrões de path que ativam a regra
  host_headers = [  # Host headers que ativam a regra
    "api.kyc.dev.wiiascend.com",
    "www.api.kyc.dev.wiiascend.com"
  ]

  # ADOT Sidecar (métricas)
  # CORRIGIDO: adot_assume_role_principals é uma lista de ARNs
  adot_assume_role_principals = [
    "arn:aws:iam::409137744423:role/observability-core-terraform-backend-access-role-o11y"
  ]
  amp_remote_write_url = data.terraform_remote_state.observability.outputs.prometheus_remote_write_endpoint
  adot_cpu             = 128
  adot_memory          = 256
  log_group            = "/ecs/backend-kyc-dev"
  log_stream_prefix     = "adot"
  adot_container_name  = "adot-collector"  # CORRIGIDO: era "container_name"
  enable_metrics       = true
  # NOTA: enable_traces não existe no módulo - X-Ray precisa ser configurado via task_role_policy_json

  # IAM Role - CORRIGIDO: usar task_role_policy_json (JSON único)
  # O módulo cria a role automaticamente, você só precisa fornecer a política
  task_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "${module.backend_stack.secret_arn}"
        ]
      },
      {
        Sid      = "PrometheusRemoteWrite"
        Effect   = "Allow"
        Action   = ["aps:RemoteWrite"]
        Resource = data.terraform_remote_state.observability.outputs.prometheus_workspace_arn
      },
      {
        Sid    = "XrayTraces"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      },
      {
        Sid      = "AssumeRoleToObservability"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::409137744423:role/observability-core-terraform-backend-access-role-o11y"
      }
    ]
  })

  # NOTA: As seguintes variáveis não existem e foram removidas:
  # - role_name
  # - policy_name
  # - role_description
  # - assume_role_policy_json (o módulo cria a assume role policy automaticamente)
  # - policy_description
  # - rule_name (X-Ray não é configurado pelo módulo)

  # =========================
  # LOGS: FireLens → Loki + S3
  # =========================
  enable_cloudwatch_logs = true
  enable_firelens        = true

  # S3 (cold storage)
  s3_logs_bucket_name   = local.s3_logs_bucket_name
  s3_logs_prefix        = "backend-kyc/dev"
  s3_logs_storage_class = "STANDARD_IA"
  s3_logs_kms_key_arn   = local.s3_logs_kms_key_arn

  fluent_total_file_size = "5M"
  fluent_upload_timeout  = "60s"
  fluent_compression      = "gzip"

  # Loki
  enable_loki   = true
  loki_host     = data.terraform_remote_state.privatelink.outputs.loki_vpce_dns_name
  loki_port     = data.terraform_remote_state.observability.outputs.loki_port
  loki_tls      = false
  loki_tenant_id = ""

  # CloudWatch Logs
  aws_resource      = "ecs"
  retention_in_days = 14

  metric_filters = {
    error_count = {
      pattern          = "{ $.level = \"error\" }"
      metric_name      = "backend_error_count"
      metric_namespace = "KYC/Backend"
      metric_value     = "1"
    }
  }

  destination_arn             = null
  subscription_filter_pattern = ""
  subscription_role_arn       = null
}

