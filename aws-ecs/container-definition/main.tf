data "aws_region" "current" {}

locals {
  # Linux-only guard (mantém compat. com var.operating_system_family)
  is_linux = contains(["LINUX"], var.operating_system_family)

  service        = var.service != null ? "/${var.service}" : ""
  name           = var.name != null ? "/${var.name}" : ""
  log_group_name = try(coalesce(var.cloudwatch_log_group_name, "/aws/ecs${local.service}${local.name}"), "")

  default_log_cfg = var.enable_cloudwatch_logging ? {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = try(aws_cloudwatch_log_group.this[0].name, local.log_group_name)
      awslogs-stream-prefix = "ecs"
    }
  } : {}

  # tflint-ignore: terraform_naming_convention
  logConfiguration = merge(
    local.default_log_cfg,
    var.logConfiguration != null ? { for k, v in var.logConfiguration : k => v if v != null } : {}
  )

  # tflint-ignore: terraform_naming_convention
  trimmedLinuxParameters = { for k, v in var.linuxParameters : k => v if v != null }
  # tflint-ignore: terraform_naming_convention
  linuxParameters = var.enable_execute_command ? merge({ "initProcessEnabled" : true },  local.trimmedLinuxParameters) : merge({ "initProcessEnabled" : false }, local.trimmedLinuxParameters)

  definition = {
    command                = var.command
    cpu                    = var.cpu
    dependsOn              = var.dependsOn
    disableNetworking      = local.is_linux ? var.disableNetworking : null
    dnsSearchDomains       = local.is_linux ? var.dnsSearchDomains : null
    dnsServers             = local.is_linux ? var.dnsServers : null
    dockerLabels           = var.dockerLabels
    dockerSecurityOptions  = var.dockerSecurityOptions
    entrypoint             = var.entrypoint != null ? var.entrypoint : null
    environment            = var.environment != null ? var.environment : null
    environmentFiles       = var.environmentFiles != null ? var.environmentFiles : null
    essential              = var.essential
    extraHosts             = local.is_linux ? var.extraHosts : null
    firelensConfiguration  = var.firelensConfiguration != null ? { for k, v in var.firelensConfiguration : k => v if v != null } : null
    healthCheck            = var.healthCheck != null ? { for k, v in var.healthCheck : k => v if v != null } : null
    hostname               = var.hostname
    image                  = var.image
    interactive            = var.interactive
    links                  = local.is_linux ? var.links : null
    linuxParameters        = local.is_linux ? local.linuxParameters : null
    logConfiguration       = length(local.logConfiguration) > 0 ? local.logConfiguration : null
    memory                 = var.memory
    memoryReservation      = var.memoryReservation
    mountPoints            = var.mountPoints != null ? var.mountPoints : null
    name                   = var.name
    portMappings           = var.portMappings != null ? [for p in var.portMappings : { for k, v in p : k => v if v != null }] : null
    privileged             = local.is_linux ? var.privileged : null
    pseudoTerminal         = var.pseudoTerminal
    readonlyRootFilesystem = local.is_linux ? var.readonlyRootFilesystem : null
    repositoryCredentials  = var.repositoryCredentials
    resourceRequirements   = var.resourceRequirements
    secrets                = var.secrets
    startTimeout           = var.startTimeout
    stopTimeout            = var.stopTimeout
    systemControls         = var.systemControls != null ? var.systemControls : null
    ulimits                = local.is_linux ? var.ulimits : null
    user                   = local.is_linux ? var.user : null
    volumesFrom            = var.volumesFrom != null ? var.volumesFrom : null
    workingDirectory       = var.workingDirectory
  }

  container_definition = { for k, v in local.definition : k => v if v != null }
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_cloudwatch_log_group && var.enable_cloudwatch_logging ? 1 : 0

  name              = var.cloudwatch_log_group_use_name_prefix ? null : local.log_group_name
  name_prefix       = var.cloudwatch_log_group_use_name_prefix ? "${local.log_group_name}-" : null
  log_group_class   = var.cloudwatch_log_group_class
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = var.tags
}
