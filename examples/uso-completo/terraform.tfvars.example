aws_profile = "default"
region      = "us-east-1"

environment  = "prod"
project_name = "backend"
owner        = "platform-team"
application  = "orders-api"

tags = {
  Squad = "payments"
}

amp_remote_write_url = "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-abc123/api/v1/remote_write"
adot_assume_role_arn  = "arn:aws:iam::123456789012:role/ObservabilityAdotRole"
adot_log_group_name   = "/aws/ecs/orders-api-prod/adot"

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

repository_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
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

cluster_kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/66666666-7777-8888-9999-000000000000"
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

api_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-api:v1.2.3"
worker_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/orders-worker:v1.2.3"

database_secret_rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-orders-database"
api_keys_rotation_lambda_arn        = "arn:aws:lambda:us-east-1:123456789012:function:rotate-external-apis"

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

stripe_secret_arn   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:external/stripe/prod-AbCdE"
sendgrid_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:external/sendgrid/prod-ZyXwV"
