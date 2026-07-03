# Lesson 7 — EKS, ECR, Helm

Terraform для AWS (S3 backend, VPC, ECR, EKS) і Helm-чарт для Django.

## Структура

```
lesson-7/
├── main.tf
├── backend.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   └── eks/
├── charts/
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── README.md
```

## Передумови

- AWS CLI
- Terraform
- kubectl
- Helm
- Docker

## Інструкція

### 1. Логін в AWS

```bash
aws configure
aws sts get-caller-identity
```

### 2. Terraform

```bash
cd lesson-7
mv backend.tf backend.tf.bak
terraform init && terraform apply

mv backend.tf.bak backend.tf
terraform init -migrate-state
```

### 3. Підключення до кластера

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

### 4. Push Docker-образу в ECR

На Mac (на процесорах M) Docker збирає образ під `arm64`, а ноди EKS — `amd64`. Тому обов'язково `--platform linux/amd64`:

```bash
cd ..   # корінь репо

ECR_URL=$(cd lesson-7 && terraform output -raw ecr_repository_url)

aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin ${ECR_URL%%/*}

docker build --platform linux/amd64 -t lesson-7-ecr .
docker tag lesson-7-ecr:latest ${ECR_URL}:latest
docker push ${ECR_URL}:latest
```

### 5. Metrics Server + Helm

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

cd lesson-7/charts/django-app
helm install django-app . --set image.repository=${ECR_URL}
kubectl get svc   # EXTERNAL-IP — адреса застосунку
```

### 6. Видалення ресурсів

```bash
helm uninstall django-app
cd lesson-7 && terraform destroy
```

EKS і NAT Gateway платні, не залишай інфраструктуру увімкненою.
