# Terraform Backend Deploy Module

Este módulo Terraform fornece uma implementação genérica para deploy de backend com observabilidade usando AWS Distro for OpenTelemetry (ADOT), roteamento de tráfego via Application Load Balancer (ALB), gerenciamento de containers via Amazon Elastic Container Registry (ECR), orquestração completa via Amazon Elastic Container Service (ECS) e gerenciamento seguro de credenciais via AWS Secrets Manager.

## Características

- **Secrets Manager**: Gerenciamento seguro de credenciais, senhas e chaves de API
- **Auto Rotation**: Rotação automática de credenciais com Lambda functions
- **Cross-Region Replication**: Replicação de secrets entre regiões para DR
- **KMS Encryption**: Criptografia avançada com chaves KMS customizadas
- **ECS Cluster**: Orquestração de containers com Fargate e EC2 support
- **ECS Services**: Gerenciamento multi-serviço com auto-scaling
- **Container Insights**: Monitoramento avançado de containers
- **ECR Repository**: Repositório de containers com lifecycle e scanning
- **ADOT Collector**: Sidecar container para coleta de telemetria
- **ALB Routing**: Target Groups e Listener Rules para roteamento
- **Security Features**: Criptografia, scanning, controle de acesso granular
- **Multi-Environment**: Suporte completo para múltiplos ambientes

## Uso

```hcl
module "backend_deploy" {
  source = "path/to/this/module"

  # Configuração básica
  environment    = "prod"
  project_name   = "my-app"
  owner          = "platform-team"
  application    = "backend-api"
  region         = "us-east-1"

  # Configuração Secrets Manager
  enable_secrets_manager = true
  secrets_kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  secrets_recovery_window = 7

  # Cross-region replication para DR
  enable_cross_region_replication = true
  replication_regions = [
    {
      region     = "us-west-2"
      kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/..."
    }
  ]

  # Database credentials com rotação automática
  create_database_secret = true
  database_secret_config = {
    username        = "admin"
    # password será gerado automaticamente
    engine          = "postgres"
    host            = "prod-db.cluster-xyz.us-east-1.rds.amazonaws.com"
    port            = 5432
    dbname          = "production"
    enable_rotation = true
    rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-db-secret"
    rotation_days   = 30
  }

  # API Keys para serviços externos
  create_api_keys_secret       = true
  api_keys_rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-api-keys"
  api_keys_rotation_days       = 30
  api_keys_config = {
    stripe = {
      secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:stripe/prod"
      version_stage = "AWSCURRENT"
    }
    sendgrid = {
      secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:sendgrid/prod"
    }
  }

  # Application secrets
  create_app_secrets = true
  app_secrets_config = {
    jwt_secret = {
      create_random_password = true
      password_length        = 64
      description           = "JWT signing secret"
    }
    session_key = {
      create_random_password = true
      password_length        = 32
      description           = "Session encryption key"
    }
    webhook_secret = {
      value       = "webhook_secret_from_provider"
      description = "Webhook validation secret"
    }
  }

  # Secrets customizados
  secrets = {
    ssl_certificate = {
      name          = "prod/ssl/certificate"
      description   = "SSL certificate for HTTPS"
      secret_binary = base64encode(file("production.p12"))
      
      create_policy = true
      policy_statements = {
        deployment_access = {
          principals = [{
            type        = "AWS"
            identifiers = ["arn:aws:iam::deploy-account:role/DeploymentRole"]
          }]
          actions = ["secretsmanager:GetSecretValue"]
        }
      }
    }
    
    oauth_config = {
      name        = "prod/oauth/config"
      description = "OAuth provider configuration"
      secret_string = jsonencode({
        client_id     = "oauth_client_id"
        client_secret = "oauth_client_secret"
        redirect_uri  = "https://api.example.com/oauth/callback"
        scope         = "read write"
      })
      
      enable_rotation = true
      rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-oauth"
      rotation_rules = {
        automatically_after_days = 90
      }
    }
  }

  # Configuração ECS
  enable_ecs = true
  ecs_services = {
    api = {
      desired_count = 2
      subnet_ids   = ["subnet-12345", "subnet-67890"]
      
      container_definitions = {
        app = {
          image = "${module.backend_deploy.ecr_repository_url}:latest"
          portMappings = [{ containerPort = 8080 }]
          
          # Usar secrets do Secrets Manager
          secrets = [
            {
              name       = "DATABASE_URL"
              value_from = module.backend_deploy.database_secret_arn
            },
            {
              name       = "JWT_SECRET"
              value_from = module.backend_deploy.app_secrets_arns["jwt_secret"]
            },
            {
              name       = "STRIPE_SECRET_KEY"
              value_from = module.backend_deploy.api_keys_secret_arn
            }
          ]
        }
      }
    }
  }

  # Permissões para ECS acessar secrets
  secrets_manager_arns = [
    "${module.backend_deploy.database_secret_arn}",
    "${module.backend_deploy.api_keys_secret_arn}",
    values(module.backend_deploy.app_secrets_arns)...
  ]

  # Outras configurações...
  enable_ecr = true
  enable_alb_routing = true
  enable_adot = true

  tags = {
    CostCenter = "engineering"
    Team       = "backend"
  }
}
```

## Outputs

### Secrets Manager Outputs
- `secrets_manager_secrets`: Informações completas de todos os secrets
- `secrets_manager_arns`: ARNs de todos os secrets para uso em policies
- `database_secret_arn`: ARN do secret do banco de dados
- `api_keys_secret_arn`: ARN do secret das chaves de API
- `app_secrets_arns`: ARNs dos secrets da aplicação
- `secrets_manager_enabled`: Status do Secrets Manager
- `secrets_manager_configuration`: Configuração completa (sensível)

### ECS Outputs
- `ecs_cluster_arn`: ARN do cluster ECS
- `ecs_services`: Informações dos serviços criados
- `ecs_task_execution_role_arn`: ARN da role de execução

### ECR Outputs
- `ecr_repository_url`: URL para push/pull de imagens
- `ecr_repository_arn`: ARN do repositório ECR

### ALB Routing & ADOT Outputs
- `target_group_arn`: ARN do Target Group
- `adot_container_definition`: Definição do container ADOT

## Configurações Avançadas

### Secrets Manager - Database com Rotação
```hcl
create_database_secret = true
database_secret_config = {
  username        = "admin"
  engine          = "postgres"
  host            = "prod-db.cluster-xyz.us-east-1.rds.amazonaws.com"
  port            = 5432
  dbname          = "production"
  enable_rotation = true
  rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-db-secret"
  rotation_days   = 30
}
```

### Secrets Manager - Cross-Region Replication
```hcl
enable_cross_region_replication = true
replication_regions = [
  {
    region     = "us-west-2"
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/..."
  },
  {
    region     = "eu-west-1"
    kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/..."
  }
]
```

### Secrets Manager - Custom Secret com Policy
```hcl
secrets = {
  cross_account_secret = {
    name        = "shared/service-key"
    description = "Shared service key for cross-account access"
    
    create_random_password = true
    random_password_length = 64
    
    create_policy = true
    policy_statements = {
      cross_account_access = {
        sid    = "CrossAccountAccess"
        effect = "Allow"
        principals = [{
          type        = "AWS"
          identifiers = [
            "arn:aws:iam::111122223333:root",
            "arn:aws:iam::444455556666:role/ServiceRole"
          ]
        }]
        actions = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        condition = [{
          test     = "StringEquals"
          variable = "secretsmanager:ResourceTag/Environment"
          values   = ["production"]
        }]
      }
    }
  }
}
```

### ECS com Secrets Manager Integration
```hcl
ecs_services = {
  api = {
    container_definitions = {
      app = {
        image = "my-app:latest"
        
        # Environment variables normais
        environment = [
          { name = "ENV", value = "production" },
          { name = "LOG_LEVEL", value = "info" }
        ]
        
        # Secrets do Secrets Manager
        secrets = [
          {
            name       = "DATABASE_URL"
            value_from = module.backend_deploy.database_secret_arn
          },
          {
            name       = "REDIS_URL"
            value_from = "${module.backend_deploy.secrets_manager_arns["redis-config"]}"
          },
          {
            name       = "JWT_SECRET"
            value_from = module.backend_deploy.app_secrets_arns["jwt_secret"]
          }
        ]
      }
    }
  }
}

# Configurar permissões automaticamente
secrets_manager_arns = values(module.backend_deploy.secrets_manager_arns)
```

### Secrets Manager - Rotation com Schedule
```hcl
secrets = {
  api_token = {
    name = "prod/external-api/token"
    
    enable_rotation = true
    rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-api-token"
    rotation_rules = {
      # Rotacionar todo primeiro domingo do mês às 3:00 AM
      schedule_expression = "cron(0 3 ? * SUN#1 *)"
      duration           = "PT2H"  # Janela de 2 horas
    }
  }
}
```

## Pré-requisitos

### Para Secrets Manager
1. **KMS Key**: Para criptografia avançada (opcional, usa default se não especificado)
2. **Lambda Functions**: Para rotação automática (se habilitada)
3. **IAM Permissions**: Para ECS, Lambda e outros serviços acessarem secrets

### Para ECS
1. **VPC e Subnets**: Para deploy dos containers
2. **Security Groups**: Criados automaticamente ou fornecidos

### Para Rotação de Secrets
1. **Lambda Function**: Implementada para o tipo específico de secret
2. **VPC Access**: Lambda deve conseguir acessar recursos (RDS, APIs externas)
3. **IAM Permissions**: Lambda precisa de permissões para atualizar secrets

## Versões

- Terraform: >= 1.5.7
- AWS Provider: >= 6.14

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CI/CD Pipeline                           │
└─────────┬───────────────────────────────────────────────────────────┘
          │ Build & Deploy
          ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Amazon ECR    │───▶│   ECS Cluster    │───▶│ Application     │
│  (Container     │    │                  │    │ Load Balancer   │
│   Registry)     │    │ ┌──────────────┐ │    └─────────┬───────┘
└─────────────────┘    │ │   Services   │ │              │
          │            │ │ ┌──────────┐ │ │    ┌─────────▼───────┐
          ▼            │ │ │   App    │ │ │    │ Target Groups   │
┌─────────────────┐    │ │ │   ADOT   │ │ │    │ & Listener      │
│ Secrets Manager │────┼─┼─┤ Secrets  │ │ │    │ Rules          │
│                 │    │ │ └──────────┘ │ │    └─────────────────┘
│ ┌─────────────┐ │    │ └──────────────┘ │
│ │  Database   │ │    │                  │
│ │ Credentials │ │    │ ┌──────────────┐ │
│ └─────────────┘ │    │ │Auto Scaling  │ │
│ ┌─────────────┐ │    │ │& Monitoring  │ │
│ │  API Keys   │ │    │ └──────────────┘ │
│ └─────────────┘ │    └──────────────────┘
│ ┌─────────────┐ │              │
│ │App Secrets  │ │              │
│ └─────────────┘ │    ┌─────────▼────────┐
│ ┌─────────────┐ │    │   Observability  │
│ │Auto Rotation│ │    │                  │
│ └─────────────┘ │    │ ┌──────────────┐ │
│ ┌─────────────┐ │    │ │   AWS X-Ray  │ │
│ │Cross-Region │ │    │ │  Amazon AMP  │ │
│ │ Replication │ │    │ │CloudWatch    │ │
│ └─────────────┘ │    │ │    Logs      │ │
└─────────────────┘    │ └──────────────┘ │
                       └──────────────────┘
```

## Casos de Uso

### 1. Aplicação Completa com Secrets Management
```hcl
# Database + API Keys + App Secrets + ECS Integration
enable_secrets_manager = true
create_database_secret = true
create_api_keys_secret = true
create_app_secrets     = true

# ECS automaticamente configurado para usar secrets
enable_ecs = true
secrets_manager_arns = values(module.backend_deploy.secrets_manager_arns)
```

### 2. Multi-Environment com Secrets Compartilhados
```hcl
# Secrets com replicação para DR
enable_cross_region_replication = true
replication_regions = [
  { region = "us-west-2" },
  { region = "eu-west-1" }
]

# Diferentes configurações por ambiente
secrets_recovery_window = var.environment == "prod" ? 30 : 7
```

### 3. Microservices com Secrets Específicos
```hcl
# Cada serviço com seus próprios secrets
secrets = {
  "orders-service-db" = { ... }
  "payments-service-db" = { ... }
  "users-service-cache" = { ... }
}

# ECS services configurados por serviço
ecs_services = {
  orders   = { secrets = [...] }
  payments = { secrets = [...] }
  users    = { secrets = [...] }
}
```

## Contribuição

1. Faça fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## Uso

```hcl
module "backend_deploy" {
  source = "path/to/this/module"

  # Configuração básica
  environment    = "prod"
  project_name   = "my-app"
  owner          = "platform-team"
  application    = "backend-api"
  region         = "us-east-1"

  # Configuração ECS
  enable_ecs                    = true
  ecs_cluster_name             = "my-app-cluster"  # Opcional, padrão: ${project_name}-${environment}
  enable_container_insights    = true
  cluster_execute_command_logging = true
  enable_fargate               = true
  enable_fargate_spot         = true

  # Serviços ECS
  ecs_services = {
    web = {
      desired_count    = 2
      cpu             = 512
      memory          = 1024
      assign_public_ip = false
      subnet_ids      = ["subnet-12345", "subnet-67890"]
      
      # Load balancer integration
      load_balancer = {
        target_group_arn = module.backend_deploy.target_group_arn
        container_name   = "app"
        container_port   = 8080
      }
      
      # Container definitions
      container_definitions = {
        app = {
          image     = "${module.backend_deploy.ecr_repository_url}:latest"
          essential = true
          
          portMappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
              name          = "http"
            }
          ]
          
          environment = [
            { name = "ENV", value = "production" },
            { name = "LOG_LEVEL", value = "info" }
          ]
          
          secrets = [
            { name = "DB_PASSWORD", value_from = "arn:aws:secretsmanager:..." }
          ]
          
          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
            interval = 30
            timeout = 5
            retries = 3
            start_period = 60
          }
          
          enable_cloudwatch_logging = true
          log_group_retention_days = 7
        }
        
        adot = {
          image     = "amazon/aws-otel-collector:latest"
          essential = false
          cpu       = 128
          memory    = 256
          
          enable_cloudwatch_logging = true
        }
      }
      
      # Auto Scaling
      enable_autoscaling       = true
      autoscaling_min_capacity = 2
      autoscaling_max_capacity = 10
      autoscaling_target_cpu   = 70
      autoscaling_target_memory = 80
    }
    
    worker = {
      desired_count = 1
      cpu          = 256
      memory       = 512
      subnet_ids   = ["subnet-12345", "subnet-67890"]
      
      container_definitions = {
        worker = {
          image     = "${module.backend_deploy.ecr_repository_url}:worker-latest"
          essential = true
          
          command = ["python", "worker.py"]
          
          environment = [
            { name = "WORKER_TYPE", value = "background" }
          ]
          
          enable_cloudwatch_logging = true
          log_group_retention_days = 14
        }
      }
    }
  }

  # Configuração ECR
  enable_ecr                     = true
  repository_image_scan_on_push  = true
  create_lifecycle_policy        = true
  max_image_count               = 10

  # Acesso ao ECR
  repository_read_write_access_arns = [
    "arn:aws:iam::123456789012:role/GitHubActionsRole"
  ]

  # Configuração ADOT
  enable_adot            = true
  amp_remote_write_url   = "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/ws-12345/api/v1/remote_write"
  assume_role_arn        = "arn:aws:iam::123456789012:role/ADOTCollectorRole"
  log_group             = "/aws/ecs/my-app-prod"

  # Configuração ALB Routing
  enable_alb_routing     = true
  listener_arn          = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-alb/50dc6c495c0c9188/f2f7dc8efc522ab2"
  vpc_id                = "vpc-12345678"
  priority              = 100
  path_patterns         = ["/api/v1/*"]
  target_type           = "ip"
  port                  = 8080

  # Tags personalizadas
  tags = {
    CostCenter = "engineering"
    Team       = "backend"
  }
}
```

## Outputs

O módulo expõe os seguintes outputs:

### ECS Outputs
- `ecs_cluster_arn`: ARN do cluster ECS
- `ecs_cluster_id`: ID do cluster ECS
- `ecs_cluster_name`: Nome do cluster ECS
- `ecs_cloudwatch_log_group_name`: Nome do log group do cluster
- `ecs_task_execution_role_arn`: ARN da role de execução compartilhada
- `ecs_services`: Informações detalhadas dos serviços criados
- `ecs_enabled`: Status do ECS
- `ecs_configuration`: Configuração completa (sensível)

### ECR Outputs
- `ecr_repository_name`: Nome do repositório ECR
- `ecr_repository_url`: URL para push/pull de imagens
- `ecr_repository_arn`: ARN do repositório ECR

### ADOT Outputs
- `adot_container_definition`: Definição JSON do container ADOT para ECS

### ALB Routing Outputs
- `target_group_arn`: ARN do Target Group criado
- `target_group_name`: Nome do Target Group

### Common Outputs
- `common_tags`: Tags aplicadas aos recursos
- `environment_info`: Informações do ambiente

## Variáveis Obrigatórias

| Nome | Tipo | Descrição |
|------|------|-----------|
| `environment` | `string` | Ambiente (dev/staging/prod) |
| `project_name` | `string` | Nome do projeto |
| `owner` | `string` | Time responsável |
| `application` | `string` | Nome da aplicação |

### Para ECS Services
| Nome | Tipo | Descrição |
|------|------|-----------|
| `ecs_services.*.subnet_ids` | `list(string)` | Subnets para deploy dos containers |
| `ecs_services.*.container_definitions` | `map(object)` | Definições dos containers |

### Para ALB (se habilitado)
| Nome | Tipo | Descrição |
|------|------|-----------|
| `listener_arn` | `string` | ARN do ALB Listener |
| `vpc_id` | `string` | VPC ID |

## Configurações Avançadas

### ECS Multi-Service com ADOT
```hcl
ecs_services = {
  api = {
    container_definitions = {
      app = {
        image = "my-api:latest"
        portMappings = [{ containerPort = 8080 }]
      }
      adot = {
        image = "amazon/aws-otel-collector:latest"
        essential = false
        environment = [
          { name = "ADOT_CONFIG_CONTENT", value = var.adot_config }
        ]
      }
    }
  }
  
  worker = {
    container_definitions = {
      worker = {
        image = "my-worker:latest"
        command = ["python", "celery_worker.py"]
      }
    }
  }
}
```

### ECS com Auto Scaling Avançado
```hcl
ecs_services = {
  web = {
    enable_autoscaling = true
    autoscaling_min_capacity = 2
    autoscaling_max_capacity = 20
    autoscaling_target_cpu = 60
    autoscaling_target_memory = 70
    
    # Fargate Spot para reduzir custos
    capacity_provider_strategy = {
      fargate = { base = 2, weight = 1 }
      fargate_spot = { base = 0, weight = 4 }
    }
  }
}
```

### ECS com Secrets Manager
```hcl
ecs_services = {
  app = {
    container_definitions = {
      app = {
        secrets = [
          {
            name = "DATABASE_URL"
            value_from = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/database-AbCdEf"
          },
          {
            name = "API_KEY"
            value_from = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/api-key"
          }
        ]
      }
    }
  }
}

# Permissões automáticas
secrets_manager_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/*"
]
ssm_parameters_arns = [
  "arn:aws:ssm:us-east-1:123456789012:parameter/prod/*"
]
```

### ECS com Health Checks Customizados
```hcl
ecs_services = {
  api = {
    container_definitions = {
      app = {
        health_check = {
          command = [
            "CMD-SHELL",
            "curl -f http://localhost:8080/health/ready || exit 1"
          ]
          interval = 30
          timeout = 5
          retries = 3
          start_period = 60
        }
      }
    }
  }
}
```

## Pré-requisitos

### Para ECS
1. **VPC e Subnets**: Configuradas com conectividade adequada
2. **Security Groups**: Para comunicação entre serviços (criados automaticamente)
3. **IAM Permissions**: Para ECS, ECR, CloudWatch, etc.

### Para ECR
1. **IAM Permissions**: Para push/pull de imagens

### Para ADOT
1. **Amazon Managed Prometheus Workspace** configurado
2. **IAM Role** com permissões para AMP, X-Ray, CloudWatch

### Para ALB Routing
1. **Application Load Balancer** existente
2. **Listener** configurado (HTTP/HTTPS)

## Versões

- Terraform: >= 1.5.7
- AWS Provider: >= 6.14

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CI/CD Pipeline                           │
└─────────┬───────────────────────────────────────────────────────────┘
          │ Build & Push Images
          ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Amazon ECR    │───▶│   ECS Cluster    │───▶│ Application     │
│  (Container     │    │                  │    │ Load Balancer   │
│   Registry)     │    │  ┌─────────────┐ │    └─────────┬───────┘
└─────────────────┘    │  │   Service   │ │              │
          │            │  │   ┌───────┐ │ │    ┌─────────▼───────┐
          ▼            │  │   │  App  │ │ │    │ Target Groups   │
┌─────────────────┐    │  │   │       │ │ │    │ & Listener      │
│ Lifecycle Mgmt  │    │  │   │ ADOT  │ │ │    │ Rules          │
│ Vulnerability   │    │  │   └───────┘ │ │    └─────────────────┘
│   Scanning      │    │  └─────────────┘ │
└─────────────────┘    │                  │
                       │  ┌─────────────┐ │
┌─────────────────┐    │  │   Service   │ │
│  Auto Scaling   │───▶│  │   ┌───────┐ │ │
│   Policies      │    │  │   │Worker │ │ │
└─────────────────┘    │  │   └───────┘ │ │
                       │  └─────────────┘ │
                       │                  │
                       │ ┌──────────────┐ │
                       │ │Container     │ │
                       │ │Insights      │ │
                       │ └──────────────┘ │
                       └──────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │   AWS X-Ray     │ │   Amazon AMP    │ │ CloudWatch Logs │
    │   (Traces)      │ │   (Metrics)     │ │   (Logging)     │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Casos de Uso

### 1. Microservices Platform Completa
```hcl
# API Gateway + Multiple Services
ecs_services = {
  api_gateway    = { ... }
  user_service   = { ... }
  order_service  = { ... }
  payment_service = { ... }
  notification_service = { ... }
}
```

### 2. Background Processing
```hcl
# Web + Workers + Schedulers
ecs_services = {
  web = {
    desired_count = 3
    load_balancer = { ... }
  }
  worker = {
    desired_count = 2
    # Sem load balancer
  }
  scheduler = {
    desired_count = 1
    # Singleton service
  }
}
```

### 3. Multi-Environment com Spot Instances
```hcl
# Prod: Fargate regular, Dev: Fargate Spot
fargate_capacity_provider_strategy = {
  base = var.environment == "prod" ? 2 : 0
  weight = var.environment == "prod" ? 100 : 20
}

fargate_spot_capacity_provider_strategy = {
  base = 0
  weight = var.environment == "prod" ? 0 : 80
}
```

## Contribuição

1. Faça fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request