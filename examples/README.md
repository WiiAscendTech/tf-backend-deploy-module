# Exemplo de Uso Completo

Este exemplo demonstra como consumir o módulo `tf-backend-deploy-module` habilitando todos os componentes (ADOT, ALB Routing, ECR, ECS e Secrets Manager) em um ambiente fictício.

## Passos para executar

1. Ajuste os valores de `terraform.tfvars.example` de acordo com a sua conta e renomeie o arquivo para `terraform.tfvars`.
2. Opcionalmente defina as credenciais AWS via perfil (`AWS_PROFILE`) ou variáveis de ambiente.
3. Inicialize e aplique o exemplo:

```bash
terraform init
terraform plan
terraform apply
```

> **Importante:** o exemplo pressupõe a existência de recursos compartilhados (ALB, Listener, VPC, sub-redes, chaves KMS, funções Lambda etc.). Atualize os ARNs e IDs antes de aplicar.
