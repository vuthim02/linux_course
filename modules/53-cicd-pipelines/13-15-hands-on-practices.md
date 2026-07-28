## 15 Hands-On Practices

### Practice 1: Basic GitHub Actions Workflow

Create `.github/workflows/basic.yml`:
```yaml
name: Basic Workflow
on: [push]
jobs:
  hello:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Say hello
        run: echo "Hello from ${{ github.repository }} at ${{ github.sha }}"
      - name: Show directory
        run: ls -la
      - name: Run shell commands
        run: |
          echo "Current time: $(date)"
          echo "Running on: $(uname -a)"
```

Commit and push. Watch the workflow run in Actions tab.

### Practice 2: Matrix Build

```yaml
name: Matrix Build
on: [push, pull_request]
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-22.04, ubuntu-24.04, macos-14]
        node: [18, 20, 22]
        exclude:
          - os: macos-14
            node: 18
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: node -e "console.log('Node ' + process.version + ' on ' + process.platform)"
```

### Practice 3: Dependency Caching

```yaml
name: Cache Demo
on: [push]
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Cache npm
        uses: actions/cache@v4
        with:
          path: ~/.npm
          key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
          restore-keys: ${{ runner.os }}-npm-
      - run: npm ci
      - run: pip install -r requirements.txt || true
```

### Practice 4: Build and Push Docker Image to GHCR

```yaml
name: Docker Build & Push
on:
  push:
    branches: [main]
    tags: ['v*']
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
jobs:
  build-and-push:
    runs-on: ubuntu-22.04
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha,prefix=,suffix=,format=short

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Practice 5: OIDC to AWS

```yaml
name: OIDC AWS Auth
on: [push]
jobs:
  aws-auth:
    runs-on: ubuntu-22.04
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
          aws-region: us-east-1
      - run: aws sts get-caller-identity
      - run: aws ecs update-service --cluster prod --service app --force-new-deployment
```

Prerequisites: Create IAM OIDC provider for `token.actions.githubusercontent.com` + IAM role with trust policy mapping your org/repo.

### Practice 6: GitLab CI Multi-Stage Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - package
  - deploy

variables:
  APP_NAME: my-app

build:
  stage: build
  image: golang:1.22
  script:
    - go build -o $APP_NAME .
  artifacts:
    paths:
      - $APP_NAME
    expire_in: 1 hour

test:
  stage: test
  image: golang:1.22
  script:
    - go test -v ./... -coverprofile=coverage.out
  artifacts:
    reports:
      coverage_report:
        coverage_format: gocov-xml
        path: coverage.out

package:
  stage: package
  image: docker:27
  services:
    - docker:27-dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

deploy-staging:
  stage: deploy
  image: alpine/k8s:1.28
  script:
    - kubectl set image deployment/$APP_NAME app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA -n staging
    - kubectl rollout status deployment/$APP_NAME -n staging
  environment:
    name: staging
  only:
    - main
```

### Practice 7: GitLab CI DAG with Needs

```yaml
stages: [build, test, deploy]
build-frontend:
  stage: build
  script: mkdir -p artifacts/; echo "frontend" > artifacts/frontend.txt
  artifacts: { paths: [artifacts/] }
build-backend:
  stage: build
  script: mkdir -p artifacts/; echo "backend" > artifacts/backend.txt
  artifacts: { paths: [artifacts/] }
test-frontend:
  stage: test
  needs: [build-frontend]
  script: cat artifacts/frontend.txt; echo "Testing frontend"
test-backend:
  stage: test
  needs: [build-backend]
  script: cat artifacts/backend.txt; echo "Testing backend"
test-integration:
  stage: test
  needs: [build-frontend, build-backend]
  script: cat artifacts/*.txt; echo "Integration tests"
deploy:
  stage: deploy
  needs: [test-frontend, test-backend, test-integration]
  script: echo "Deploying all components"
```

### Practice 8: GitLab CI Review Apps

```yaml
stages: [review, cleanup]
review:
  stage: review
  image: alpine/k8s:1.28
  script:
    - kubectl apply -f k8s/review.yaml -n review-apps
    - kubectl rollout status deployment/review-$CI_ENVIRONMENT_SLUG -n review-apps --timeout=3m
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.review.example.com
    on_stop: stop-review
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
stop-review:
  stage: cleanup
  image: alpine/k8s:1.28
  variables: { GIT_STRATEGY: none }
  script: kubectl delete deployment review-$CI_ENVIRONMENT_SLUG -n review-apps
  environment: { name: review/$CI_COMMIT_REF_SLUG, action: stop }
  when: manual
```

### Practice 9: Install and Configure Jenkins

```bash
# 1. Install Jenkins via Docker
docker network create jenkins
docker run -d --name jenkins \
  --network jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk17

# 2. Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# 3. Open http://localhost:8080 and follow setup

# 4. Add a Linux agent
#   - Manage Jenkins → Nodes → New Node
#   - Name: linux-agent
#   - Remote root directory: /home/jenkins/agent
#   - Labels: linux docker
#   - Launch method: Launch agent via SSH

# 5. On the agent machine:
sudo useradd -m -s /bin/bash jenkins
sudo mkdir -p /home/jenkins/agent
sudo chown -R jenkins:jenkins /home/jenkins/agent
ssh-keygen -t ed25519 -f /root/jenkins-agent-key
cat /root/jenkins-agent-key.pub >> /home/jenkins/.ssh/authorized_keys
# Use the private key in Jenkins node configuration
```

### Practice 10: Declarative Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    tools { maven 'Maven-3.9'; jdk 'JDK-21' }
    stages {
        stage('Build') { steps { sh 'mvn clean compile' } }
        stage('Test') {
            steps { sh 'mvn test' }
            post { always { junit 'target/surefire-reports/TEST-*.xml' } }
        }
        stage('Package') {
            steps { sh 'mvn package -DskipTests'; archiveArtifacts artifacts: 'target/*.jar' }
        }
    }
    post { always { cleanWs() } }
}
```

Create: New Item → Pipeline → Pipeline script from SCM → Git → your repo → Script Path: Jenkinsfile

### Practice 11: Jenkins Multibranch Pipeline

1. Jenkins → New Item → Multibranch Pipeline
2. Name: `my-app-multibranch`
3. Branch Sources → Git
4. Project Repository: `https://github.com/myorg/my-app.git`
5. Credentials: (SSH or token)
6. Build Configuration:
   - Mode: by Jenkinsfile
   - Script Path: Jenkinsfile
7. Scan Multibranch Pipeline Triggers:
   - Periodically if not otherwise run: 1 minute
8. Save

Jenkins will scan all branches and create pipelines automatically. For PRs, Jenkins will also create pipelines (if using GitHub/GitLab integration).

### Practice 12: SAST Integration

```yaml
# .github/workflows/sast.yml
name: SAST
on: [push, pull_request]
jobs:
  codeql:
    runs-on: ubuntu-22.04
    permissions:
      security-events: write
    strategy:
      matrix:
        language: [javascript, python]
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
      - uses: github/codeql-action/analyze@v3

  semgrep:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: semgrep/semgrep-action@v1
        with:
          config: p/ci
```

### Practice 13: Container Image Scanning with Trivy

```yaml
# .github/workflows/container-scan.yml
name: Container Scan
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 6 * * *'
jobs:
  scan:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t my-app:${{ github.sha }} .

      - name: Scan with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: my-app:${{ github.sha }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: 1    # Fail on HIGH/CRITICAL

      - name: Upload results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif
```

### Practice 14: Deploy to Kubernetes from Pipeline

```yaml
# .github/workflows/deploy-k8s.yml
name: Deploy to K8s
on:
  workflow_run:
    workflows: ["Docker Build & Push"]
    types: [completed]
jobs:
  deploy:
    runs-on: ubuntu-22.04
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - uses: actions/checkout@v4

      - name: Set K8s context
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}

      - name: Update image tag
        run: |
          sed -i "s|image:.*|image: ghcr.io/${{ github.repository }}:${{ github.sha }}|g" k8s/deployment.yaml

      - name: Deploy
        run: |
          kubectl apply -f k8s/
          kubectl rollout status deployment/my-app -n production --timeout=5m

      - name: Verify deployment
        run: |
          kubectl get pods -n production -l app=my-app
          curl -sf https://app.example.com/health
```

### Practice 15: Real-World Full CI/CD Pipeline

```yaml
# .github/workflows/full-cicd.yml
name: Full CI/CD Pipeline
run-name: "CI/CD ${{ github.ref_name }}"

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  unit-test:
    runs-on: ubuntu-22.04
    needs: [lint]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/

  sast:
    runs-on: ubuntu-22.04
    needs: [lint]
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript
      - uses: github/codeql-action/analyze@v3

  docker-build:
    runs-on: ubuntu-22.04
    needs: [unit-test, sast]
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  container-scan:
    runs-on: ubuntu-22.04
    needs: [docker-build]
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

  deploy-staging:
    runs-on: ubuntu-22.04
    needs: [container-scan]
    if: github.ref == 'refs/heads/main'
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/checkout@v4
      - uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG_STAGING }}
      - name: Deploy
        run: |
          sed -i "s|image:.*|image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}|g" k8s/deployment.yaml
          kubectl apply -f k8s/ -n staging
          kubectl rollout status deployment/my-app -n staging --timeout=3m

  integration-test:
    runs-on: ubuntu-22.04
    needs: [deploy-staging]
    steps:
      - name: Run integration tests against staging
        run: |
          for i in $(seq 1 30); do
            STATUS=$(curl -so /dev/null -w "%{http_code}" https://staging.example.com/health)
            if [ "$STATUS" = "200" ]; then
              echo "Health check passed"
              break
            fi
            sleep 10
          done
          curl -f https://staging.example.com/api/status

  deploy-production:
    runs-on: ubuntu-22.04
    needs: [integration-test]
    if: startsWith(github.ref, 'refs/tags/v')
    environment:
      name: production
      url: https://app.example.com
    steps:
      - uses: actions/checkout@v4
      - uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG_PROD }}
      - name: Deploy to production
        run: |
          sed -i "s|image:.*|image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}|g" k8s/deployment.yaml
          kubectl apply -f k8s/ -n production
          kubectl rollout status deployment/my-app -n production --timeout=10m

  notify:
    runs-on: ubuntu-22.04
    needs: [deploy-production, deploy-staging, integration-test]
    if: always() && github.ref == 'refs/heads/main'
    steps:
      - name: Notify Slack
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_COLOR: ${{ contains(nevents.*.result, 'failure') && 'danger' || 'good' }}
          SLACK_TITLE: 'CI/CD Pipeline ${{ contains(nevents.*.result, 'failure') && 'FAILED' || 'PASSED' }}'
          SLACK_MESSAGE: |
            Repository: ${{ github.repository }}
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
            Run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
```





[← Previous](12-12-monitoring-pipelines.md) | [↑ Index](index.md) | [Next →](14-deep-understanding.md)
