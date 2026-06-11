# Infraestrutura AWS — Aulas 04-07 (Free Tier)

> **Um único `terraform apply`** sobe rede + compute + storage dentro do Free Tier na região **us-east-1**.

---

## Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Terraform | ≥ 1.5 |
| AWS CLI | qualquer versão recente |
| Conta AWS | Free Tier ou LocalStack |

```bash
aws configure          # credenciais com permissões suficientes
terraform version      # confirme ≥ 1.5
```

---

## Estrutura

```
.
├── main.tf                   # Provider + chamada dos módulos
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example  # Copie → terraform.tfvars
├── .gitignore
├── modules/
│   ├── network/              # VPC, Subnets, IGW, Route Tables
│   ├── security/             # SG web e SG RDS
│   ├── compute/              # EC2 (SSM), Lambda, API Gateway HTTP
│   └── storage/              # RDS PostgreSQL, S3, DynamoDB
└── bonus/                    # ⚠️ FORA Free Tier: NAT GW + ASG + ALB
```

---

## O que é provisionado (~35 recursos)

### Rede (Aula 04)
| Recurso | Detalhes |
|---|---|
| VPC | 10.0.0.0/16 — DNS hostnames habilitado |
| Subnets públicas | 10.0.1.0/24 (us-east-1a) · 10.0.2.0/24 (us-east-1b) · IP público automático |
| Subnets privadas | 10.0.11.0/24 (us-east-1a) · 10.0.12.0/24 (us-east-1b) |
| Internet Gateway | Associado à VPC |
| RT pública | 0.0.0.0/0 → IGW — associada às duas subnets públicas |
| RT privada | Sem rota de saída (sem NAT) |

### Segurança (Aula 05)
| Recurso | Regras |
|---|---|
| SG web/app | Ingress 80 e 443 de 0.0.0.0/0 |
| SG RDS | Ingress 5432 **somente** do SG web/app |

### Compute (Aula 06)
| Recurso | Detalhes |
|---|---|
| EC2 t3.micro | AMI Amazon Linux 2023 (data source) — subnet pública — IAM Role + SSM — httpd no user_data |
| Lambda | Node.js 20 · handler `index.handler` · IAM AWSLambdaBasicExecutionRole |
| API Gateway HTTP | Rota `POST /` → Lambda (proxy) — stage `$default` com auto_deploy |

### Storage (Aula 07)
| Recurso | Detalhes |
|---|---|
| RDS PostgreSQL 15.4 | db.t3.micro · single-AZ · 20 GB gp2 · sem acesso público · backup 7 dias · subnets privadas |
| S3 | Versionamento habilitado · Block Public Access total |
| DynamoDB Pedidos | PAY_PER_REQUEST · PK `clienteId` SK `pedidoId` · GSI `status-index` (projeção ALL) |

---

## Fluxo completo

### 1. Configure a senha do banco

```bash
# Opção A (recomendada — não aparece no histórico)
export TF_VAR_db_password="SuaSenha!Forte123"

# Opção B — arquivo local (não versione!)
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars e preencha db_password
```

### 2. Formate e valide

```bash
terraform fmt -recursive
terraform init
terraform validate
```

### 3. Planeje (~35 recursos)

```bash
terraform plan
# Procure a linha: "Plan: ~35 to add, 0 to change, 0 to destroy"
```

### 4. Aplique

```bash
terraform apply
# Digite "yes" quando solicitado
# Aguarde ~5-10 minutos (RDS demora mais)
```

### 5. Teste

```bash
# EC2 — HTTP
EC2_IP=$(terraform output -raw ec2_public_ip)
curl http://$EC2_IP

# API Gateway — POST
APIGW=$(terraform output -raw api_gateway_url)
curl -X POST $APIGW

# SSM no lugar de SSH
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=aulas-dev-web-ec2" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)
aws ssm start-session --target $INSTANCE_ID

# RDS (dentro da EC2 via SSM)
RDS=$(terraform output -raw rds_endpoint)
psql "host=$RDS user=dbadmin dbname=appdb"

# DynamoDB
TABLE=$(terraform output -raw dynamodb_table_name)
aws dynamodb put-item --table-name $TABLE \
  --item '{"clienteId":{"S":"c1"},"pedidoId":{"S":"p1"},"status":{"S":"novo"}}'
aws dynamodb query --table-name $TABLE \
  --index-name status-index \
  --key-condition-expression "#s = :v" \
  --expression-attribute-names '{"#s":"status"}' \
  --expression-attribute-values '{":v":{"S":"novo"}}'
```

### 6. Destrua (obrigatório ao final)

```bash
terraform destroy
# Digite "yes" — TUDO será removido
```

---

## Bônus ⚠️ Fora do Free Tier

```bash
cd bonus

# Preencha as variáveis com os outputs do projeto principal
terraform init
terraform apply -var="vpc_id=vpc-xxx" \
                -var='public_subnet_ids=["subnet-aaa","subnet-bbb"]' \
                -var='private_subnet_ids=["subnet-ccc","subnet-ddd"]' \
                -var="web_sg_id=sg-xxx" \
                -var="ami_id=ami-xxx"

# Demo → destrua IMEDIATAMENTE
terraform destroy ...mesmas vars...
```

Recursos bônus: **NAT Gateway** (EIP + GW) e **ASG** (Launch Template + Scaling Policy) + **ALB** (Target Group + Listener) com target tracking de CPU a 60%.

---

## Outputs

| Output | Descrição |
|---|---|
| `vpc_id` | ID da VPC |
| `public_subnet_ids` | Lista de IDs das subnets públicas |
| `private_subnet_ids` | Lista de IDs das subnets privadas |
| `web_sg_id` | SG do web/app |
| `rds_sg_id` | SG do RDS |
| `ec2_public_ip` | IP público da EC2 |
| `api_gateway_url` | URL invoke do APIGW HTTP |
| `rds_endpoint` | Endpoint do RDS (sensível) |
| `s3_bucket_name` | Nome do bucket S3 |
| `dynamodb_table_name` | Nome da tabela DynamoDB |

---

## Custos Free Tier

Todos os recursos principais ficam dentro do Free Tier **desde que você execute `terraform destroy` no mesmo dia**:

- EC2 t3.micro — 750 h/mês gratuitas (primeiro ano)
- RDS db.t3.micro — 750 h/mês + 20 GB gp2 (primeiro ano)
- Lambda — 1 M requests/mês gratuitas
- API Gateway — 1 M chamadas/mês (primeiro ano)
- S3 — 5 GB gratuitos
- DynamoDB — 25 GB + 25 WCU/RCU gratuitos (sempre free)

> **Atenção:** RDS é o recurso mais caro se esquecer rodando (~$15/mês fora do Free Tier). Configure billing alerts na AWS.
