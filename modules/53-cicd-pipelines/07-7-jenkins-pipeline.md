## 7. Jenkins Pipeline

Jenkins Pipeline as Code uses a `Jenkinsfile` in the repository root.

### Declarative Pipeline

```groovy
// Jenkinsfile (Declarative) — Build → Test → SAST → Docker → Deploy → Notify
pipeline {
    agent any
    environment {
        DOCKER_REGISTRY = 'ghcr.io/myorg'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }
    tools { maven 'Maven-3.9'; jdk 'JDK-21' }
    triggers { pollSCM('H/5 * * * *') }
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }
    stages {
        stage('Build') {
            agent { docker { image 'maven:3.9-eclipse-temurin-21'; reuseNode true } }
            steps { sh 'mvn clean compile -q' }
            post { success { archiveArtifacts artifacts: 'target/*.jar' } }
        }
        stage('Test') {
            parallel {
                stage('Unit') {
                    agent { docker { image 'maven:3.9-eclipse-temurin-21'; reuseNode true } }
                    steps { sh 'mvn test' }
                    post { always { junit 'target/surefire-reports/TEST-*.xml' } }
                }
                stage('Lint') { steps { sh 'mvn checkstyle:check' } }
            }
        }
        stage('SAST') {
            when { branch 'main' }
            steps { sh 'docker run --rm -v "$PWD:/src" aquasec/trivy:latest filesystem --severity HIGH,CRITICAL /src' }
        }
        stage('Docker Build & Push') {
            when { expression { env.BRANCH_NAME == 'main' } }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        def img = docker.build("${DOCKER_REGISTRY}/my-app:${IMAGE_TAG}", '.')
                        img.push(); img.push('latest')
                    }
                }
            }
        }
        stage('Deploy Staging') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                        sed -i 's|image:.*|image: ${DOCKER_REGISTRY}/my-app:${IMAGE_TAG}|' k8s/deployment.yaml
                        kubectl apply -f k8s/ -n staging
                        kubectl rollout status deployment/my-app -n staging --timeout=5m
                    """
                }
            }
        }
        stage('Deploy Production') {
            when { branch 'main' }
            input { message "Deploy to production?"; ok "Yes"; submitter "prod-deployers" }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-prod', variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/app app=${DOCKER_REGISTRY}/my-app:${IMAGE_TAG} -n production"
                }
            }
        }
    }
    post {
        always { cleanWs() }
        success { slackSend(channel: '#deployments', color: 'good', message: "Deploy OK: ${env.BUILD_URL}") }
        failure { slackSend(channel: '#deployments', color: 'danger', message: "Deploy FAILED: ${env.BUILD_URL}") }
    }
}
```

### Scripted Pipeline

```groovy
// Jenkinsfile (Scripted)
def IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
node('linux && docker') {
    stage('Checkout') { checkout scm }
    stage('Build') { docker.image('maven:3.9-eclipse-temurin-21').inside { sh 'mvn clean compile' } }
    stage('Test') { docker.image('maven:3.9-eclipse-temurin-21').inside { sh 'mvn test' } }
    stage('Docker') {
        def img = docker.build("ghcr.io/myorg/app:${IMAGE_TAG}")
        docker.withRegistry('https://ghcr.io', 'docker-credentials') { img.push(); img.push('latest') }
    }
    stage('Deploy') { sh "kubectl set image deployment/app app=ghcr.io/myorg/app:${IMAGE_TAG}" }
}
```

### Agent Types

```groovy
agent any                                    // any available agent
agent { label 'linux && docker' }            // specific label
agent { docker { image 'node:20'; reuseNode true } }  // Docker container
agent {
    kubernetes {                              // Kubernetes pod
        yaml '''
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.9-eclipse-temurin-21
    command: ["cat"]
    tty: true
  - name: docker
    image: docker:27-dind
    securityContext: { privileged: true }
'''
        defaultContainer 'maven'
    }
}
agent none  // stages define their own
```

### Triggers

```groovy
triggers {
    pollSCM('H/5 * * * *')
    upstream(upstreamProjects: 'shared-lib-pipeline', threshold: hudson.model.Result.SUCCESS)
    cron('0 2 * * 0')
}
// Webhooks: GitHub → http://jenkins/github-webhook/ ; GitLab → http://jenkins/project/PROJECT
```

### Shared Libraries

```groovy
// vars/deployToK8s.groovy
def call(String namespace, String image) {
    sh "kubectl set image deployment/app app=${image} -n ${namespace} && kubectl rollout status deployment/app -n ${namespace}"
}
```

Configure: Jenkins → Configure System → Global Pipeline Libraries → Name, Git repo URL. Use:
```groovy
@Library('shared-pipeline-lib')_
pipeline { stages { stage('Deploy') { steps { deployToK8s('staging', 'myapp:1.0') } } } }
```

### Multibranch Pipelines

Automatically discover branches and create pipeline runs for each:

1. New Item → Multibranch Pipeline
2. Branch Sources: Git, GitHub, GitLab, Bitbucket
3. Build Configuration: Pipeline from SCM → Jenkinsfile path

Jenkins scans branches periodically, creates pipelines per branch/PR, runs each Jenkinsfile independently. Branch-specific logic:
```groovy
post {
    success {
        script {
            if (env.BRANCH_NAME == 'main') { /* deploy */ }
            if (env.CHANGE_ID) { /* PR-specific */ }
        }
    }
}
```





[← Previous](06-6-jenkins.md) | [↑ Index](index.md) | [Next →](08-8-artifact-management.md)
