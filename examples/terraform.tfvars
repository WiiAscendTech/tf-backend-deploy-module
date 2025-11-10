aws_profile = "default"
region      = "us-east-1"

environment  = "prod"
project_name = "backend"
owner        = "platform-team"
application  = "orders-api"

tags = {
  Squad = "payments"
}

default_base_tags = {
  CostCenter   = "CC-001"
  BusinessUnit = "Digital"
}

enable_adot = true

amp_remote_write_url = "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-abc123/api/v1/remote_write"
adot_assume_role_arn  = "arn:aws:iam::123456789012:role/ObservabilityAdotRole"
adot_log_group_name   = "/aws/ecs/orders-api-prod/adot"

enable_alb_routing         = true
alb_target_type            = "ip"
alb_protocol               = "HTTP"
alb_target_group_port      = 8080
alb_protocol_version       = "HTTP1"
alb_health_check_path      = "/healthz"
alb_target_group_advanced_configuration = {
  deregistration_delay = 30
  slow_start           = 60
  stickiness = {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }
}

listener_arn            = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/shared-alb/1234567890abcdef/1234567890abcdef"
listener_rule_priority  = 50
vpc_id                  = "vpc-0abc123456789def0"
host_headers            = ["api.example.com"]
path_patterns           = ["/", "/api/*"]
existing_target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/shared-ecs-tg/1234567890abcdef"

private_subnet_ids = [
  "subnet-0aaa1111bbb2222cc",
  "subnet-0ddd3333eee4444ff"
]

security_group_ids = [
  "sg-0123456789abcdef0"
]

ecs_alarm_topic_arn = "arn:aws:sns:us-east-1:123456789012:platform-alerts"

enable_ecr                      = true
repository_kms_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
repository_image_tag_mutability = "IMMUTABLE"
repository_encryption_type      = "KMS"
repository_read_access_arns = [
  "arn:aws:iam::123456789012:role/ReadOnlyDeploy"
]
repository_read_write_access_arns = [
  "arn:aws:iam::123456789012:role/CICDPipeline"
]
replication_destinations = [
  {
    region      = "us-west-2"
    registry_id = "123456789012"
  }
]

enable_registry_scanning = true
registry_scan_type       = "ENHANCED"
max_image_count          = 15

enable_ecs                    = true
enable_fargate_spot           = true
fargate_capacity_provider_strategy = {
  base   = 1
  weight = 70
}
fargate_spot_capacity_provider_strategy = {
  base   = 0
  weight = 30
}

cluster_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/66666666-7777-8888-9999-000000000000"
ecs_log_group_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
additional_task_execution_policies = [
  "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
]
ssm_parameter_arns = [
  "arn:aws:ssm:us-east-1:123456789012:parameter/shared/database/url"
]
secrets_manager_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:shared/api/external-ABC123"
]

create_ecs_alarms                   = true
ecs_alarm_insufficient_data_actions = []
ecs_alarm_treat_missing_data        = "notBreaching"
ecs_cpu_alarm_threshold             = 75
ecs_cpu_alarm_evaluation_periods    = 2
ecs_cpu_alarm_period                = 300

api_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-api:v1.2.3"
worker_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-worker:v1.2.3"

api_service_settings = {
  service_name          = "api"
  desired_count         = 2
  assign_public_ip      = false
  enable_execute_command = true
  app_container = {
    name      = "app"
    port      = 8080
    protocol  = "tcp"
    log_level = "info"
    health_check = {
      command      = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
      interval     = 30
      timeout      = 5
      retries      = 3
      start_period = 60
    }
    additional_environment = []
  }
  adot_container = {
    name                   = "adot"
    image                  = "amazon/aws-otel-collector:latest"
    essential              = false
    additional_environment = []
  }
  enable_autoscaling        = true
  autoscaling_min_capacity  = 2
  autoscaling_max_capacity  = 6
  autoscaling_target_cpu    = 60
  autoscaling_target_memory = 70
  autoscaling_request_count = {
    enabled      = true
    prefix       = "app/alb"
    target_value = 1000
  }
}

worker_service_settings = {
  service_name          = "worker"
  desired_count         = 1
  assign_public_ip      = false
  container_name        = "worker"
  environment_variables = [
    {
      name  = "QUEUE_NAME"
      value = "default"
    }
  ]
}

database_secret_rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-orders-database"
api_keys_rotation_lambda_arn        = "arn:aws:lambda:us-east-1:123456789012:function:rotate-external-apis"

enable_secrets_manager  = true
secrets_recovery_window = 7

create_database_secret = true
database_secret_config = {
  username      = "app_user"
  engine        = "postgres"
  host          = "prod-db.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
  port          = 5432
  dbname        = "application"
  rotation_days = 30
}

create_api_keys_secret = true
api_keys_rotation_days = 30
api_keys_config = {
  stripe = {
    secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:external/stripe/prod-AbCdE"
    version_stage = "AWSCURRENT"
  }
  sendgrid = {
    secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:external/sendgrid/prod-ZyXwV"
  }
}

create_app_secrets = true
app_secrets_config = {
  jwt_secret = {
    create_random_password = true
    password_length        = 64
    description            = "JWT signing secret"
  }
  webhook_token = {
    value       = "change-me"
    description = "Webhook token used by partners"
  }
}

secrets_config = {
  github_pat = {
    name          = "backend/prod/github/pat"
    description   = "Token de acesso para deploy via GitHub Actions"
    secret_string = jsonencode({
      token = "ghp_example_token"
    })
  }
}

secrets_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/ffffffff-1111-2222-3333-444444444444"
replica_regions = [
  {
    region     = "us-west-2"
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/55555555-6666-7777-8888-999999999999"
  }
]
additional_secret_reader_arns = [
  "arn:aws:iam::123456789012:role/DataScienceReadOnly"
]
