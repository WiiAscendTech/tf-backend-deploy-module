resource "local_file" "adot_config" {
  content = templatefile("${path.module}/templates/adot-config.yaml.tpl", {
    region               = var.region
    assume_role_arn      = var.assume_role_arn
    amp_remote_write_url = var.amp_remote_write_url
    enable_traces        = var.enable_traces
    enable_metrics       = var.enable_metrics
    project_name         = var.application
    environment          = var.environment
  })
  filename = "${path.module}/collector.yaml"
}

data "local_file" "adot_config_content" {
  filename = local_file.adot_config.filename
}