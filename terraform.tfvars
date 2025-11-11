environment  = "prod"
project_name = "payments"
owner        = "platform-team"
application  = "payments-api"
region       = "us-east-1"

tags = {
  CostCenter = "FIN-001"
  Team       = "Payments"
}

enable_adot          = true
amp_remote_write_url = "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-1234567890/api/v1/remote_write"
assume_role_arn      = "arn:aws:iam::123456789012:role/AdotRemoteWrite"
log_group            = "/aws/ecs/payments-api/adot"
log_stream_prefix    = "collector"

enable_ecs        = true
create_ecs_alarms = true
ecs_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:platform-alerts"]

enable_alb_routing = false

ecr_repository_name     = "payments-api"
repository_type         = "private"
max_image_count         = 3
create_lifecycle_policy = true

enable_secrets_manager = true
secrets_kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"
create_database_secret = true
database_secret_config = {
  username            = "dbadmin"
  engine              = "postgres"
  host                = "payments.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
  port                = 5432
  dbname              = "payments"
  enable_rotation     = true
  rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-db-secret"
  rotation_days       = 30
}
api_keys_rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-api-keys"
api_keys_rotation_days       = 30
create_api_keys_secret       = true
api_keys_config = {
  stripe = {
    secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:stripe/prod"
  }
  sendgrid = {
    secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:sendgrid/prod"
    version_stage = "AWSPREVIOUS"
  }
}
additional_secret_reader_arns = [
  "arn:aws:iam::123456789012:role/analytics-reader"
]

ecs_services = {
  payments = {
    desired_count      = 2
    subnet_ids         = ["subnet-abc123", "subnet-def456"]
    security_group_ids = ["sg-0123456789abcdef0"]

    load_balancer = {
      target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/payments/1234567890abcdef"
      container_name   = "payments"
      container_port   = 8080
    }

    container_definitions = {
      payments = {
        image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/payments-api:latest"
        portMappings = [{
          containerPort = 8080
        }]
      }
    }

    enable_autoscaling             = true
    autoscaling_min_capacity       = 2
    autoscaling_max_capacity       = 6
    autoscaling_target_cpu         = 60
    autoscaling_target_memory      = 70
    autoscaling_scale_in_cooldown  = 300
    autoscaling_scale_out_cooldown = 90
    autoscaling_request_count = {
      enabled        = true
      resource_label = "app/application/1234567890abcdef/targetgroup/payments/abcdef1234567890"
      target_value   = 1000
    }
  }
}
