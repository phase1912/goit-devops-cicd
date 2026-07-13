# Final DevOps Project

Повна інфраструктура на AWS: VPC, EKS, RDS, ECR, Jenkins, Argo CD, Prometheus/Grafana.

```
Git push → Jenkins (Kaniko) → ECR
                ↓
         update values.yaml → Git push (final-project)
                ↓
         Argo CD auto-sync → EKS (django-app)
```

## Структура

```
├── main.tf, backend.tf, outputs.tf, variables.tf
├── modules/
│   ├── s3-backend/, vpc/, ecr/, eks/, rds/
│   ├── jenkins/, argo_cd/, monitoring/
├── charts/django-app/
├── Jenkinsfile
├── Dockerfile
├── docker-compose.yml
├── mysite/
└── README.md
```

Django-код у `mysite/` (аналог `Django/app` з ТЗ).

## Передумови

- AWS CLI
- Terraform
- kubectl
- Helm
- GitHub PAT (classic, scope `repo`)

## 1. AWS

```bash
aws configure
aws sts get-caller-identity
```

## 2. Terraform

```bash
cp terraform.tfvars.example terraform.tfvars
mv backend.tf backend.tf.bak
terraform init

terraform apply -target=module.s3_backend -target=module.vpc \
  -target=module.ecr -target=module.rds -target=module.eks

terraform apply -target=module.monitoring -target=module.jenkins -target=module.argo_cd

mv backend.tf.bak backend.tf
terraform init -migrate-state
terraform apply
```

Apply займе ~30-40 хв.

## 3. kubectl + Metrics Server

```bash
aws eks update-kubeconfig --region us-west-2 --name final-project-eks
kubectl get nodes

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## 4. RDS → Django

Після apply:

```bash
terraform output db_endpoint
```

Оновити `charts/django-app/values.yaml`:
- `DB_HOST` — endpoint з output
- `secrets.POSTGRES_PASSWORD` — пароль з `terraform.tfvars`

Закомітити в гілку `final-project`, Argo CD підхопить зміни.

## 5. Jenkins

```bash
terraform output jenkins_url
terraform output -raw jenkins_admin_password
```

Port-forward (якщо LB не відкривається):

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Jenkins UI — з **`:8080`**: `http://localhost:8080`

Налаштування:
1. Логін `admin`, пароль з terraform output
2. Credentials → `github-token` (Secret text, GitHub PAT)
3. New Item → Pipeline → `django-cicd`, SCM Git, branch `*/final-project`, Script Path `Jenkinsfile`
4. Build Now

На маленьких нодах перед build можна вимкнути Argo CD:

```bash
kubectl scale deployment -n argocd --all --replicas=0
kubectl scale statefulset argocd-application-controller -n argocd --replicas=0
```

## 6. Argo CD

```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
terraform output -raw argocd_admin_password
```

Argo CD дивиться на гілку **`final-project`**.

```bash
kubectl get application -n argocd
kubectl get pods -n django
kubectl get svc -n django
```

Django URL — EXTERNAL-IP з `kubectl get svc -n django`, відкривати через **`http://`**.

## 7. Grafana

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

Grafana: http://localhost:3000 (логін admin / пароль з secret `prometheus-grafana` в namespace monitoring)

```bash
kubectl get secret -n monitoring -l app.kubernetes.io/name=grafana
```

## 8. Перевірка

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get hpa -n django
```

## 9. Видалення

```bash
terraform destroy
```

EKS, NAT Gateway, RDS і Load Balancer платні. Після destroy S3-бакет для стейту теж видаляється.

## Здача

- GitHub: гілка `final-project`
- Zip: `final_DevOps_ПІБ.zip` (без `.git`, `.terraform`, `terraform.tfvars`)
