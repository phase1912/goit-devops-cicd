# Jenkins + Argo CD CI/CD

Повний CI/CD: Jenkins збирає Docker-образ, пушить в ECR, оновлює Helm values у Git, Argo CD синхронізує кластер.

## Схема

```
Git push → Jenkins (Kaniko) → ECR
                ↓
         update values.yaml → Git push (master)
                ↓
         Argo CD auto-sync → EKS (django-app)
```

## Структура

```
├── main.tf
├── backend.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   ├── eks/
│   ├── rds/
│   ├── jenkins/
│   └── argo_cd/
├── charts/django-app/
│   ├── values.yaml          # config (не-секретні змінні)
│   └── templates/
│       ├── configmap.yaml
│       ├── secret.yaml      # POSTGRES_PASSWORD, SECRET_KEY
│       ├── deployment.yaml
│       ├── service.yaml
│       └── hpa.yaml
├── Jenkinsfile
├── screenshots/
├── Dockerfile
└── README.md
```

На `master` в Git: `Jenkinsfile` + `charts/django-app/`.  
Terraform (`main.tf`, `modules/`) — на гілці `lesson-8-9`.

Секретні паролі (`POSTGRES_PASSWORD`, `SECRET_KEY`) зберігаються в блоці `secrets` у `values.yaml` і застосовуються через `templates/secret.yaml` (Kubernetes Secret), а не через ConfigMap.

## Передумови

- AWS CLI
- Terraform
- kubectl
- Helm
- GitHub PAT (classic, scope `repo`)

## 1. Логін в AWS

```bash
aws configure
aws sts get-caller-identity
```

## 2. Terraform

```bash
mv backend.tf backend.tf.bak
terraform init && terraform apply -target=module.s3_backend -target=module.vpc -target=module.ecr -target=module.eks

terraform apply -target=module.jenkins
terraform apply

mv backend.tf.bak backend.tf
terraform init -migrate-state
```

Apply займе ~25-35 хв. У `main.tf` стоїть `desired_size = 2` для EKS — потрібно для Kaniko build.

## 3. Підключення до кластера

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-8-9-eks
kubectl get nodes
```

## 4. Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## 5. Jenkins

```bash
terraform output jenkins_url
terraform output -raw jenkins_admin_password
terraform output -raw ecr_repository_url
```

Jenkins відкривати з **`:8080`**:
```
http://<lb-hostname>:8080
```

### Налаштування

1. Логін `admin`, пароль з terraform output
2. **Manage Jenkins → Clouds → New cloud → Kubernetes**
   - Name: `kubernetes`
   - Kubernetes URL: `https://kubernetes.default`
   - Jenkins URL: `http://jenkins.jenkins.svc.cluster.local:8080`
   - Jenkins tunnel: `jenkins-agent.jenkins.svc.cluster.local:50000`
   - Namespace: `jenkins`
3. **Credentials → `github-token`** (Secret text, GitHub PAT з scope `repo`)
4. **New Item → Pipeline → `django-cicd`**
   - SCM: Git
   - URL: `https://github.com/phase1912/goit-devops-cicd.git`
   - Branch: `*/master`
   - Script Path: `Jenkinsfile`
5. У `Jenkinsfile` має бути правильний `ECR_URL`
6. **Build Now**

Перед build вимкни Argo CD (на маленькій ноді не вистачає RAM):

```bash
kubectl scale deployment -n argocd --all --replicas=0
kubectl scale statefulset argocd-application-controller -n argocd --replicas=0
```

## 6. Argo CD

```bash
kubectl scale statefulset jenkins -n jenkins --replicas=0

kubectl scale deployment argocd-server argocd-repo-server -n argocd --replicas=1
kubectl scale statefulset argocd-application-controller -n argocd --replicas=1
```

```bash
terraform output argocd_url
terraform output -raw argocd_admin_password
```

Argo CD дивиться на гілку **`master`**. Якщо Application показує помилку з `main`:

```bash
kubectl patch application django-app -n argocd --type merge \
  -p '{"spec":{"source":{"targetRevision":"master"}}}'
```

Перевірити `django-app` — **Synced** / **Healthy**.

```bash
kubectl get pods -n django
kubectl get svc -n django
```

Django URL — **EXTERNAL-IP** з `kubectl get svc -n django`, відкривати через **`http://`** (не https).

## 7. Скріншоти

Папка `screenshots/`:
- `jenkins-pipeline.png` — успішний build
- `jenkins-console.png` — git push в логах
- `ecr.png` — образи в ECR
- `git-push.png` — commit у GitHub
- `argocd.png` — Synced / Healthy
- `django-app.png` — сторінка Django

## 8. RDS Module

Універсальний модуль `modules/rds/` створює PostgreSQL/MySQL базу в двох режимах:

- `use_aurora = false` → `aws_db_instance` (звичайна RDS)
- `use_aurora = true` → `aws_rds_cluster` + writer instance (Aurora)

В обох режимах автоматично створюються:
- DB Subnet Group (private subnets)
- Security Group (ingress з VPC CIDR)
- Parameter Group з `max_connections`, `log_statement`, `work_mem` (PostgreSQL)
- `storage_encrypted = true`, `backup_retention_period = 7` (за замовчуванням)
- Aurora: writer + `reader_count` reader instances

### Приклад: звичайна RDS

```hcl
module "rds" {
  source              = "./modules/rds"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  use_aurora     = false
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"
  multi_az       = false
  allocated_storage = 20
  backup_retention_period = 7
  identifier     = "lesson-db-module"
  db_name        = "django"
  username       = "dbadmin"
  password       = var.db_password
}
```

### Приклад: Aurora

```hcl
module "rds" {
  source              = "./modules/rds"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  use_aurora     = true
  engine         = "postgres"          # автоматично мапиться на aurora-postgresql
  engine_version = "15"
  instance_class = "db.t3.micro"
  reader_count   = 1
  backup_retention_period = 7
  identifier     = "lesson-db-module"
  db_name        = "django"
  username       = "dbadmin"
  password       = var.db_password
}
```

### Змінні модуля

| Змінна | Тип | Дефолт | Опис |
|--------|-----|--------|------|
| `use_aurora` | bool | `false` | `true` = Aurora cluster, `false` = RDS instance |
| `engine` | string | `postgres` | `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql` |
| `engine_version` | string | `15` | Версія движка (major або full) |
| `instance_class` | string | `db.t3.micro` | Клас інстансу |
| `multi_az` | bool | `false` | Multi-AZ (тільки для RDS instance) |
| `vpc_id` | string | — | VPC ID |
| `subnet_ids` | list(string) | — | Private subnet IDs |
| `allowed_cidr_blocks` | list(string) | `[]` | CIDR для доступу до БД |
| `db_name` | string | `django` | Ім'я бази |
| `username` | string | `dbadmin` | Master user |
| `password` | string | — | Master password (sensitive) |
| `identifier` | string | `lesson-db-module` | Префікс імен ресурсів |
| `allocated_storage` | number | `20` | Обсяг сховища (GB) для RDS instance |
| `storage_type` | string | `gp2` | Тип диска для RDS instance |
| `backup_retention_period` | number | `7` | Період зберігання backup (днів) |
| `reader_count` | number | `1` | Кількість Aurora reader instances |

### Як змінити тип БД

1. Скопіюй `terraform.tfvars.example` → `terraform.tfvars`
2. Для PostgreSQL RDS:
   ```hcl
   use_aurora = false
   db_engine  = "postgres"
   ```
3. Для MySQL RDS:
   ```hcl
   use_aurora = false
   db_engine  = "mysql"
   db_engine_version = "8.0"
   ```
4. Для Aurora PostgreSQL:
   ```hcl
   use_aurora = true
   db_engine  = "postgres"
   ```
5. Змінити клас інстансу: `db_instance_class = "db.t3.small"`
6. Увімкнути Multi-AZ: `db_multi_az = true` (тільки RDS)

### Деплой тільки RDS (без EKS)

```bash
cp terraform.tfvars.example terraform.tfvars
mv backend.tf backend.tf.bak
terraform init
terraform apply -target=module.s3_backend -target=module.vpc -target=module.rds
mv backend.tf.bak backend.tf && terraform init -migrate-state
```

Перевірка:

```bash
terraform output db_endpoint
terraform output db_mode
aws rds describe-db-instances --region us-west-2 --db-instance-identifier lesson-db-module
```

### Перемикання RDS → Aurora

Тестуй режими **послідовно** (не одночасно):

```bash
terraform destroy -target=module.rds
# у terraform.tfvars: use_aurora = true
terraform apply -target=module.rds
aws rds describe-db-clusters --region us-west-2
```

> **Примітка:** на AWS Free Tier Aurora може бути заблокована (`FreeTierRestrictionError`). Код модуля підтримує Aurora — `terraform plan -var='use_aurora=true'` покаже коректний план. Для реального деплою Aurora потрібен платний акаунт.

RDS і Aurora платні. Використовуй `db.t3.micro` і `multi_az = false` для мінімальних витрат.

## 9. Видалення

```bash
terraform destroy
```

EKS, NAT Gateway і RDS платні. Після destroy S3-бакет для стейту теж видаляється.
