# Lesson 5 — Terraform (AWS)

Домашнє завдання. Terraform-конфігурація для AWS: S3 + DynamoDB (state backend), VPC, ECR.

## Структура

```
lesson-5/
├── main.tf
├── backend.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   └── ecr/
└── README.md
```

## Команди

```bash
cd lesson-5
terraform init
terraform plan
terraform apply
terraform destroy
```

Перший раз S3 і DynamoDB ще не існують. Поки `backend.tf` на місці, `plan`/`apply` не працюють — Terraform одразу хоче підключити S3 backend, якого ще немає.

Тому спочатку тимчасово прибери backend:

```bash
mv backend.tf backend.tf.bak
terraform init
terraform plan
terraform apply

mv backend.tf.bak backend.tf
terraform init -migrate-state
```

Далі вже звичайні `terraform plan` / `apply` — стейт зберігається в S3.

## Модулі

**s3-backend** — S3 bucket для tfstate (з versioning) і DynamoDB таблиця `terraform-locks` для блокування стейту.

**vpc** — VPC `10.0.0.0/16`, 3 public і 3 private subnets, Internet Gateway, NAT Gateway, route tables.

**ecr** — репозиторій `lesson-5-ecr`, scan on push, policy для доступу з акаунту.

## Після перевірки

Обов'язково видалити ресурси:

```bash
terraform destroy
```

NAT Gateway платний, не залишайте інфраструктуру увімкненою.
