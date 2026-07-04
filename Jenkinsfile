pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: kaniko-agent
spec:
  serviceAccountName: kaniko
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:3283.v92c105e0f819-4
    tty: true
    resources:
      requests:
        cpu: 50m
        memory: 128Mi
      limits:
        memory: 256Mi
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['/busybox/cat']
    tty: true
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        memory: 768Mi
"""
        }
    }

    environment {
        AWS_REGION = 'us-west-2'
        ECR_URL = '836809165836.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-ecr'
        HELM_VALUES_PATH = 'charts/django-app/values.yaml'
        GIT_REPO = 'https://github.com/phase1912/goit-devops-cicd.git'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \
                      --context=dir://${WORKSPACE} \
                      --dockerfile=Dockerfile \
                      --destination=${ECR_URL}:${BUILD_NUMBER} \
                      --custom-platform=linux/amd64
                    '''
                }
            }
        }

        stage('Update Helm values') {
            steps {
                sh '''
                cd ${WORKSPACE}
                sed -i "s|tag: .*|tag: \\"${BUILD_NUMBER}\\"|" ${HELM_VALUES_PATH}
                sed -i "s|repository: .*|repository: ${ECR_URL}|" ${HELM_VALUES_PATH}
                '''
            }
        }

        stage('Git push') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GIT_TOKEN')]) {
                    sh '''
                    cd ${WORKSPACE}
                    git config user.email "jenkins@local"
                    git config user.name "Jenkins"
                    git add ${HELM_VALUES_PATH}
                    git commit -m "Update image tag to ${BUILD_NUMBER}" || true
                        git push https://x-access-token:${GIT_TOKEN}@github.com/phase1912/goit-devops-cicd.git HEAD:master
                    '''
                }
            }
        }
    }
}
