receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  filter/essential:
    metrics:
      include:
        match_type: regexp
        metric_names:
          - ^http\.server\..*$
          - ^nodejs\..*$
          - ^v8js\..*$

  resource/application:
    attributes:
      - key: service.name
        action: insert
        value: ${project_name}-${environment}
      - key: deployment.environment
        action: insert
        value: ${environment}

exporters:
  awsxray:
    region: ${region}
  prometheusremotewrite:
    endpoint: ${amp_remote_write_url}
    auth:
      authenticator: sigv4auth
    resource_to_telemetry_conversion:
      enabled: true

extensions:
  sigv4auth:
    region: ${region}
    service: aps
    assume_role:
      arn: ${assume_role_arn}
      sts_region: ${region}

service:
  telemetry:
    metrics:
      address: 0.0.0.0:8888

  extensions: [sigv4auth]
  pipelines:
%{ if enable_traces }
    traces:
      receivers: [otlp]
      exporters: [awsxray]
%{ endif }
%{ if enable_metrics }
    metrics:
      receivers: [otlp]
      processors: [filter/essential, resource/application]
      exporters: [prometheusremotewrite]
%{ endif }
