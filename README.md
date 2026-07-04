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

## 8. Видалення

```bash
terraform destroy
```

EKS і NAT Gateway платні. Після destroy S3-бакет для стейту теж видаляється.
