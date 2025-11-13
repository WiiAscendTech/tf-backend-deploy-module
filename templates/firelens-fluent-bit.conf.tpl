[INPUT]
    Name              forward
    Listen            127.0.0.1
    Port              24224
    Tag               app.*

[FILTER]
    Name              aws
    Match             *
    imds_version      v2
    ecs_awslogs_format On

[FILTER]
    Name              parser
    Match             app.*
    Key_Name          log
    Parser            json
    Reserve_Data      On

%{ if enable_loki }
[OUTPUT]
    Name              loki
    Match             app.*
    Host              ${loki_host}
    Port              ${loki_port}
    tls               ${loki_tls}
    %{ if loki_tenant_id != "" }
    tenant_id         ${loki_tenant_id}
    %{ endif }
    labels            job=${application},env=${environment},service=${application},cluster=${cluster_name},account=${account_id}
    label_keys        ecs_task_arn,container_name
    line_format       json
%{ endif }

[OUTPUT]
    Name              s3
    Match             app.*
    bucket            ${bucket_name}
    region            ${region}
    total_file_size   ${total_file_size}
    upload_timeout    ${upload_timeout}
    use_put_object    On
    store_dir         /tmp/fluent-bit/s3
    storage.total_limit_size 512M
    compression       ${compression}
    s3_key_format     /${s3_prefix}/year=%Y/month=%m/day=%d/app=${application}/env=${environment}/task=$(ecs_task_arn)/container=$(container_name)/%H-%M-%S-%L.gz
    s3_key_format_tag_delimiters .-_
    storage_class     ${storage_class}
