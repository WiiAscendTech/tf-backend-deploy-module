locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    Application = var.application
  })

  cloudwatch_log_group_name = coalesce(var.log_group, "/ecs/${var.application}-${var.environment}")

  loki_base_options = var.loki_host != null && var.loki_host != "" ? {
    Name   = "loki"
    host   = var.loki_host
    port   = tostring(var.loki_port)
    tls    = var.loki_tls ? "on" : "off"
    labels = "job=${var.application},env=${var.environment},container_name=${var.application}"
  } : {}

  loki_options = (
    var.loki_tenant_id != null && var.loki_tenant_id != ""
    ) ? merge(
    local.loki_base_options,
    { tenant_id = var.loki_tenant_id }
  ) : local.loki_base_options

  app_log_configuration = var.enable_firelens && var.enable_loki && var.loki_host != null && var.loki_host != "" ? {
    logDriver = "awsfirelens"
    options   = local.loki_options
    } : var.enable_firelens ? {
    logDriver = "awsfirelens"
    options = {
      Name            = "s3"
      bucket          = var.s3_logs_bucket_name
      region          = var.region
      total_file_size = var.fluent_total_file_size
      upload_timeout  = var.fluent_upload_timeout
      use_put_object  = "On"
    }
    } : var.enable_cloudwatch_logs ? {
    logDriver = "awslogs"
    options = {
      awslogs-group         = local.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = var.application
    }
  } : null

  log_router_log_configuration = var.enable_firelens && var.firelens_send_own_logs_to_cw && var.enable_cloudwatch_logs ? {
    logDriver = "awslogs"
    options = {
      awslogs-group         = local.cloudwatch_log_group_name
      awslogs-region        = var.region
      awslogs-stream-prefix = "firelens"
    }
  } : null

  app_container_definition = merge({
    name      = var.application
    image     = "${var.ecr_repository_url}:latest"
    cpu       = var.container_cpu
    memory    = var.container_memory
    essential = true

    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }
    ]

    environment = var.ecs_environment_variables
    secrets     = var.ecs_secrets
    }, local.app_log_configuration != null ? {
    logConfiguration = local.app_log_configuration
  } : {})

  fluent_bit_config = <<-EOT
[SERVICE]
    Flush        5
    Daemon       Off
    Log_Level    info

[INPUT]
    Name              forward
    Listen            0.0.0.0
    Port              24224

[FILTER]
    Name                modify
    Match               *
    Remove              container_id
    Remove              source
    Remove              ecs_task_arn
    Remove              task_arn
    Remove              ecs_cluster
    Remove              ecs_task_definition

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Set                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 clean_message $${message}
    Remove              message

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists clean_message
    Add                 message $${clean_message}
    Remove              clean_message

[FILTER]
    Name                rewrite_tag
    Match               *
    Rule                message ^(.*)$ message false

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              message

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              message

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              message

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists log
    Add                 message $${log}
    Remove              log

[FILTER]
    Name                modify
    Match               *
    Condition           Key_exists message
    Add                 log $${message}
    Remove              message

[OUTPUT]
    Name              s3
    Match             *
    bucket            $${S3_BUCKET}
    region            $${AWS_REGION}
    total_file_size   $${TOTAL_FILE}
    upload_timeout    $${UPLOAD_TO}
    use_put_object    On
    store_dir         /tmp/fluent-bit-s3
    s3_key_format     /$${S3_PREFIX}/%Y/%m/%d/%H/%M/%S_$${container_name}_%i
    compression       $${COMPRESS}
    storage_class     $${S3_CLASS}
    log_key           log

${var.enable_cloudwatch_logs ? <<-CWOUTPUT
[OUTPUT]
    Name              cloudwatch_logs
    Match             *
    region            $${AWS_REGION}
    log_group_name    $${CW_LOG_GROUP}
    log_stream_prefix $${CW_LOG_STREAM_PREFIX}
    auto_create_group On
    log_key           log
CWOUTPUT
: ""}
EOT

  log_router_container_definition = var.enable_firelens ? merge({
    name      = "log-router"
    image     = var.firelens_image
    cpu       = var.firelens_cpu
    memory    = var.firelens_memory
    essential = true

    firelensConfiguration = {
      type = "fluentbit"
      options = {
        enable-ecs-log-metadata = "true"
      }
    }

    environment = concat([
      { name = "APP_NAME", value = var.application },
      { name = "ENVIRONMENT", value = var.environment },
      { name = "S3_BUCKET", value = var.s3_logs_bucket_name },
      { name = "S3_PREFIX", value = var.s3_logs_prefix },
      { name = "AWS_REGION", value = var.region },
      { name = "S3_CLASS", value = var.s3_logs_storage_class },
      { name = "TOTAL_FILE", value = var.fluent_total_file_size },
      { name = "UPLOAD_TO", value = var.fluent_upload_timeout },
      { name = "COMPRESS", value = var.fluent_compression },
      { name = "FLUENT_CONF", value = local.fluent_bit_config }
    ], var.enable_cloudwatch_logs ? [
      { name = "CW_LOG_GROUP", value = local.cloudwatch_log_group_name },
      { name = "CW_LOG_STREAM_PREFIX", value = var.application }
    ] : [])

    healthCheck = {
      command     = ["CMD-SHELL", "pgrep fluent-bit > /dev/null || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }
    }, local.log_router_log_configuration != null ? {
    logConfiguration = local.log_router_log_configuration
  } : {}) : null

  adot_container_definition = var.adot_container_definition_json != null ? jsondecode(var.adot_container_definition_json) : null

  ecs_task_containers = concat(
    [local.app_container_definition],
    var.enable_firelens ? [local.log_router_container_definition] : [],
    local.adot_container_definition != null ? [local.adot_container_definition] : []
  )

  service_name         = "${var.application}-ecs-service-${var.environment}"
  task_definition_name = "${var.application}-td-${var.environment}"
  security_group_name  = "${var.application}-ecs-sg-${var.environment}"
  cluster_name          = var.cluster_name != null ? var.cluster_name : "${var.application}-ecs-cluster-${var.environment}"
  cluster_id            = var.create_cluster ? aws_ecs_cluster.this[0].id : var.cluster_id
  task_role_name        = "${var.application}-ecs-task-role-${var.environment}"
  task_policy_name      = "${var.application}-ecs-task-policy-${var.environment}"
  execution_role_name   = "${var.application}-ecs-execution-role-${var.environment}"
}

