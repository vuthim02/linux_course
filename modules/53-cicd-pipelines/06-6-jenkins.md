## 6. Jenkins

Jenkins is a self-hosted automation server. Master/agent architecture means the master orchestrates, agents execute.

### Master/Agent Architecture

```
┌───────────────────┐
│   Jenkins Master  │
│                   │
│  • Web UI (8080)  │
│  • Job scheduling │
│  • Pipeline logic │
│  • Plugin mgmt    │
│  • Auth/ACL       │
└────────┬──────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ Agent1 │ │ Agent2 │ │ Agent3 │ │ Agent4 │
│ Linux  │ │Windows │ │macOS   │ │ K8s    │
│ x86_64 │ │ amd64  │ │ arm64  │ │ Pod    │
└────────┘ └────────┘ └────────┘ └────────┘
```

### Installation

**Via apt (Debian/Ubuntu):**
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre jenkins
sudo systemctl enable --now jenkins
```

Initial unlock:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Via Docker:**
```bash
docker network create jenkins
docker run -d --name jenkins-master \
  --network jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17
```

### Plugin Architecture

Essential plugins:
- **Pipeline**: Pipeline (Groovy DSL), Pipeline: Stage View
- **SCM**: Git, GitHub Integration, GitLab
- **Build**: Maven Integration, Gradle, NodeJS
- **Credentials**: Credentials Binding, Plain Credentials
- **Docker**: Docker Pipeline, Docker Commons
- **Cloud**: Kubernetes, Amazon ECS
- **Testing**: JUnit, Coverage, xUnit
- **Notifications**: Email Extension, Slack
- **Security**: OWASP Dependency Check, Anchore Container Scanner
- **Artifacts**: Nexus Artifactory, S3 Publisher

### Credentials

Jenkins credentials store (Manage Jenkins → Credentials):

```groovy
// Username with password
withCredentials([
  usernamePassword(
    credentialsId: 'dockerhub-cred',
    usernameVariable: 'DOCKER_USER',
    passwordVariable: 'DOCKER_PASS'
  )
]) {
  sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
}

// SSH key
withCredentials([
  sshUserPrivateKey(
    credentialsId: 'deploy-key',
    keyFileVariable: 'SSH_KEY',
    usernameVariable: 'SSH_USER'
  )
]) {
  sh 'ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@server "uptime"'
}

// Secret text (API tokens)
withCredentials([
  string(
    credentialsId: 'github-token',
    variable: 'GITHUB_TOKEN'
  )
]) {
  sh 'curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user'
}

// Secret file
withCredentials([
  file(
    credentialsId: 'gcp-sa-key',
    variable: 'GCP_SA_KEY'
  )
]) {
  sh 'gcloud auth activate-service-account --key-file=$GCP_SA_KEY'
}
```





[← Previous](05-5-gitlab-ci-advanced.md) | [↑ Index](index.md) | [Next →](07-7-jenkins-pipeline.md)
