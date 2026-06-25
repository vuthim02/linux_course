# 🐧 Linux System Administrator — Complete Course
## Part 53 of ∞: CI/CD Pipelines — GitHub Actions, GitLab CI, Jenkins

---

> **Reverse Engineering Approach:** You will first see a working pipeline. Then we dismantle every piece — the trigger, the runner, the job, the step, the artifact. By the time you finish, you will not just *use* CI/CD — you will *understand* it well enough to build a custom CI system from scratch.

---

## 1. CI/CD Concepts

### Continuous Integration (CI)

Automatically build and test every commit: detect change → checkout → install deps → run tests → report results. Broken code never reaches main.

### Continuous Delivery (CD)

CI + auto-deploy tested artifact to staging. Human approves production push. Produces a release-ready artifact (JAR, Docker image, DEB) every time.

### Continuous Deployment

Full automation — every passing commit deploys to production. No human gate. Requires extreme confidence in test suite and rollback mechanisms.

### Pipeline Stages

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  BUILD  │ → │  TEST   │ → │ SCAN    │ → │ DEPLOY  │ → │ VERIFY  │
│ compile │   │ unit    │   │ SAST    │   │ staging │   │ smoke   │
│ package │   │ integ   │   │ container│   │         │   │ tests   │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Trunk-Based vs GitFlow

| Aspect | Trunk-Based | GitFlow |
|--------|------------|---------|
| Branching | Single `main` branch, short-lived feature branches | `develop`, `main`, `feature/*`, `release/*`, `hotfix/*` |
| CI frequency | Every commit to trunk | Every commit to develop, release branches |
| Deploy model | Continuous Deployment | Release-based |
| Complexity | Low | High |
| Best for | SaaS, DevOps-mature teams | Enterprise, regulated, release-train |

---

## 2. GitHub Actions

GitHub Actions is a CI/CD platform integrated into GitHub. Workflows are defined in YAML files stored in `.github/workflows/`.

### Workflow YAML Structure

```yaml
# .github/workflows/ci.yml
name: CI Pipeline
run-name: "CI ${{ github.ref_name }} by @${{ github.actor }}"

on:
  push:
    branches: [main, develop]
    paths-ignore:
      - 'docs/**'
      - '*.md'
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  schedule:
    - cron: '0 6 * * 1'   # Every Monday at 06:00 UTC
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        type: choice
        options:
          - staging
          - production
        required: true
        default: staging

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-22.04
    timeout-minutes: 30
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-22.04, ubuntu-24.04]
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run lint
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.os }}-${{ matrix.node-version }}
          path: junit.xml

  docker-build:
    needs: [build]
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

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Triggers Explained

| Trigger | When It Fires |
|---------|--------------|
| `push` | A commit is pushed to a branch |
| `pull_request` | A PR is opened, synchronized, or reopened |
| `schedule` | At specified cron times |
| `workflow_dispatch` | Manually via GitHub UI or API |
| `repository_dispatch` | External webhook (custom events) |
| `issue_comment` | An issue or PR comment is created |
| `release` | A release is published |
| `page_build` | GitHub Pages is built |

### Runners

**GitHub-hosted runners:**
- Ubuntu 20.04, 22.04, 24.04
- Windows Server 2022, 2019
- macOS 12, 13, 14
- 2-core to 8-core CPU, 7GB to 32GB RAM
- Free tier: 2000 minutes/month (Linux), 3000 minutes/month (Windows)

**Self-hosted runners:**
- Run on your own infrastructure
- Labels: `self-hosted`, `linux`, `gpu`, or custom
- Can be installed on any Linux/Windows/macOS machine
- Use `--labels` to tag for specific jobs

```yaml
jobs:
  gpu-job:
    runs-on: [self-hosted, gpu]
    steps:
      - run: nvidia-smi
```

### Environment Protection Rules

```yaml
jobs:
  deploy-prod:
    runs-on: ubuntu-22.04
    environment:
      name: production
      url: https://app.example.com
    steps:
      - run: ./deploy.sh
```

Configure in Settings → Environments:
- **Required reviewers**: 1+ approvers
- **Wait timer**: 0-43200 minutes
- **Deployment branches**: restrict which branches can deploy

### Secrets and Variables

```yaml
jobs:
  deploy:
    runs-on: ubuntu-22.04
    environment: production
    env:
      NODE_ENV: production
    steps:
      - name: Deploy
        run: ./deploy.sh --key "${{ secrets.SSH_PRIVATE_KEY }}"
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

Organization/Repository secrets (Settings → Secrets and variables):
- Repository secrets: available to all workflows in the repo
- Environment secrets: available only when targeting that environment
- Organization secrets: shared across repos

### Caching

```yaml
- name: Cache npm dependencies
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-

- name: Cache pip dependencies
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
```

For Maven:
```yaml
- name: Cache Maven dependencies
  uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('pom.xml') }}
```

### Actions Marketplace

Community and official actions: `actions/checkout`, `actions/setup-node`, `docker/build-push-action`, `aws-actions/configure-aws-credentials`, `azure/login`, `google-github-actions/auth`, `github/codeql-action`, `actions/upload-artifact`, `actions/download-artifact`, `actions/create-release`, `softprops/action-gh-release`.

---

## 3. GitHub Actions Advanced

### Reusable Workflows

Workflows in `.github/workflows/` with `workflow_call` trigger can be called from other workflows. Inputs, secrets, and outputs are declared explicitly.

```yaml
# .github/workflows/build-reusable.yml
name: Reusable Build
on:
  workflow_call:
    inputs:
      node-version: { required: true, type: string, default: '20' }
      publish: { required: false, type: boolean, default: false }
    secrets:
      NPM_TOKEN: { required: true }
    outputs:
      artifact-url:
        value: ${{ jobs.build.outputs.artifact-url }}
jobs:
  build:
    runs-on: ubuntu-22.04
    outputs:
      artifact-url: ${{ steps.publish.outputs.url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: ${{ inputs.node-version }}, cache: 'npm' }
      - run: npm ci && npm test && npm run build
      - if: ${{ inputs.publish }}
        id: publish
        run: |
          npm publish --token ${{ secrets.NPM_TOKEN }}
          echo "url=https://npmjs.com/package/$(node -p 'require("./package.json").name')" >> $GITHUB_OUTPUT
```

Caller:
```yaml
jobs:
  call-build:
    uses: ./.github/workflows/build-reusable.yml
    with: { node-version: '20', publish: ${{ github.ref == 'refs/heads/main' }} }
    secrets: { NPM_TOKEN: ${{ secrets.NPM_TOKEN }} }
  deploy:
    needs: [call-build]
    runs-on: ubuntu-22.04
    steps:
      - run: echo "Artifact at ${{ needs.call-build.outputs.artifact-url }}"
```

### Composite Actions
    - name: Set K8s context
      shell: bash
      run: |
        kubectl config use-context ${{ inputs.cluster }}

    - name: Update image tag
      shell: bash
      run: |
        sed -i "s|image:.*|image: ${{ inputs.image-tag }}|g" ${{ inputs.manifest }}

    - name: Apply manifest
      shell: bash
      run: |
        kubectl apply -f ${{ inputs.manifest }} -n ${{ inputs.namespace }}

    - name: Rollout status
      shell: bash
      run: |
        kubectl rollout status deployment/$(basename ${{ inputs.manifest }} .yaml) \
          -n ${{ inputs.namespace }} --timeout=5m
```

Usage in workflow:
```yaml
jobs:
  deploy:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/deploy-k8s
        with:
          cluster: prod-cluster
          namespace: production
          manifest: k8s/deployment.yaml
          image-tag: ghcr.io/myorg/app:${{ github.sha }}
```

### OIDC for Cloud Authentication

OpenID Connect eliminates stored cloud credentials. GitHub Actions requests a short-lived token directly from the cloud provider.

```yaml
# GitHub Actions OIDC to AWS
jobs:
  deploy-aws:
    runs-on: ubuntu-22.04
    permissions:
      id-token: write   # Required for OIDC
      contents: read
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
          aws-region: us-east-1

      - name: Deploy to ECS
        run: aws ecs update-service --cluster prod --service app --force-new-deployment
```

```yaml
# GitHub Actions OIDC to GCP
jobs:
  deploy-gcp:
    runs-on: ubuntu-22.04
    permissions:
      id-token: write
    steps:
      - id: auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider
          service_account: deployer@my-project.iam.gserviceaccount.com

      - name: Deploy to Cloud Run
        uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: my-service
          image: gcr.io/my-project/my-image:${{ github.sha }}
```

```yaml
# GitHub Actions OIDC to Azure
jobs:
  deploy-azure:
    runs-on: ubuntu-22.04
    permissions:
      id-token: write
    steps:
      - name: Azure login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy to AKS
        run: |
          az aks get-credentials -g my-rg -n my-aks
          kubectl apply -f k8s/
```

### Approval Gates

Environment protection rules enforce manual approval before deployment:

1. Go to Settings → Environments → **production**
2. Enable **Required reviewers** — add 2 team members
3. Enable **Wait timer** — 5 minutes (cooldown)
4. In workflow, set `environment: production`

When the workflow reaches the `deploy-prod` job, it pauses. The approver receives a notification and must approve via GitHub UI before the job proceeds.

### Required Status Checks

In branch protection rules:
- Require status checks to pass before merging
- Require branches to be up to date
- Status checks come from workflow job names

```yaml
# These job names become status checks
jobs:
  lint:
    runs-on: ubuntu-22.04
    steps: [run: npm run lint]
  test-unit:
    runs-on: ubuntu-22.04
    steps: [run: npm run test:unit]
  test-integration:
    runs-on: ubuntu-22.04
    steps: [run: npm run test:integration]
```

---

## 4. GitLab CI

GitLab CI is defined in `.gitlab-ci.yml` at the repository root. It uses **runners** (separate from GitLab server) to execute jobs.

### .gitlab-ci.yml Structure

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - scan
  - package
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .m2/repository/
    - node_modules/

before_script:
  - echo "Starting job for $CI_PROJECT_NAME on $CI_RUNNER_DESCRIPTION"

build-jar:
  stage: build
  image: maven:3.9-eclipse-temurin-21
  tags:
    - docker
    - linux
  script:
    - mvn clean compile -q
  artifacts:
    paths:
      - target/*.jar
    expire_in: 1 hour

unit-test:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  tags: [docker]
  needs: [build-jar]
  script:
    - mvn test
  artifacts:
    reports:
      junit: target/surefire-reports/TEST-*.xml
    when: always

code-analysis:
  stage: scan
  image: sonarsource/sonar-scanner-cli:11
  tags: [docker]
  needs: [build-jar]
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  script:
    - sonar-scanner
      -Dsonar.projectKey=${CI_PROJECT_ID}
      -Dsonar.sources=.
      -Dsonar.host.url=${SONAR_HOST_URL}
      -Dsonar.login=${SONAR_TOKEN}
  only:
    - main
    - merge_requests

containerize:
  stage: package
  image: docker:27
  tags: [docker]
  needs: [unit-test, code-analysis]
  services:
    - docker:27-dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  only:
    - main

deploy-staging:
  stage: deploy
  image: alpine/curl:8
  tags: [docker]
  needs: [containerize]
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop-staging
  script:
    - apk add --no-cache kubectl
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA -n staging
    - kubectl rollout status deployment/app -n staging --timeout=3m
  only:
    - main

stop-staging:
  stage: deploy
  image: alpine/k8s:1.28
  tags: [docker]
  script:
    - kubectl scale deployment app --replicas=0 -n staging
  environment:
    name: staging
    action: stop
  when: manual

deploy-production:
  stage: deploy
  image: alpine/k8s:1.28
  tags: [docker]
  needs: [deploy-staging]
  environment:
    name: production
    url: https://app.example.com
  script:
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA -n production
    - kubectl rollout status deployment/app -n production
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual
      allow_failure: false
```

### Stages and Parallel Execution

All jobs in the same stage run in parallel. Stages run sequentially.

```
          ┌─ build-jar ─┐
          │             │
          ▼             ▼
      ┌──────┐    ┌─────────┐
      │ unit │    │ code    │       (parallel)
      │ test │    │ analysis │
      └──────┘    └─────────┘
          │             │
          └──────┬──────┘
                 ▼
           ┌───────────┐
           │containerize│
           └───────────┘
                 │
                 ▼
           ┌──────────────┐
           │deploy-staging │
           └──────────────┘
                 │
                 ▼
           ┌─────────────────┐
           │deploy-production │  (manual gate)
           └─────────────────┘
```

### Tags (Runner Selection)

Tags on jobs must match tags on runners. This selects the right runner for each job:

```yaml
# Only runs on a runner tagged "windows"
build-windows:
  stage: build
  tags:
    - windows
    - vs2022
  script:
    - msbuild.exe MyApp.sln
```

Common runner tag strategies:
- `docker` — for container-based jobs
- `kubernetes` — for K8s pod runners
- `gpu` — for GPU workloads
- `high-mem` — for memory-intensive builds
- `windows`, `macos`, `linux` — OS-specific

### before_script / after_script

```yaml
before_script:
  - apt-get update -qq
  - apt-get install -y -qq curl jq

after_script:
  - rm -rf $CI_PROJECT_DIR/tmp
  - echo "Job finished at $(date)"

job:
  script:
    - ./do-the-work.sh
```

`after_script` runs even if the job fails. Good for cleanup.

### Artifacts

```yaml
docs-build:
  stage: build
  script:
    - mkdir public
    - doxygen Doxyfile
  artifacts:
    paths:
      - public/
    expire_in: 30 days
    expose_as: "Documentation Preview"
    reports:
      dotenv: build.env
```

Artifact types:
- `paths`: files/directories to preserve
- `expose_as`: shows in MR UI
- `reports`: JUnit, SAST, DAST, license scanning, performance, etc.
- `expire_in`: auto-cleanup (default 30 days)
- `when`: `on_success` (default), `on_failure`, `always`

### Dependencies

```yaml
build-jar:
  stage: build
  script: mvn package -q
  artifacts:
    paths: [target/*.jar]

test-integration:
  stage: test
  dependencies:
    - build-jar    # downloads build-jar's artifacts
  script:
    - java -jar target/app.jar &
    - sleep 5
    - curl -f http://localhost:8080/health
```

Without `dependencies`, all artifacts from all preceding stages are downloaded. Use `dependencies` to limit downloads and speed up jobs.

### Environment

```yaml
deploy-review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.example.com
    on_stop: stop-review
  script:
    - ./deploy-review.sh

stop-review:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script:
    - ./destroy-review.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

### Rules (Advanced Conditional Logic)

```yaml
deploy-prod:
  stage: deploy
  rules:
    - if: '$CI_COMMIT_BRANCH == "main" && $CI_PIPELINE_SOURCE == "push"'
      when: manual
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: never
    - when: never
  script:
    - ./deploy prod
```

Rules keywords:
- `if`: condition (CI/CD variable comparison)
- `changes`: trigger when specific files change
- `exists`: trigger when a file exists in the repo
- `when`: `on_success`, `manual`, `always`, `never`, `delayed`

### Needs (DAG Pipelines)

`needs` creates a directed acyclic graph, allowing jobs to start as soon as their dependencies complete — not waiting for the entire stage.

```yaml
stages:
  - build
  - test
  - deploy

build-a:
  stage: build
  script: make build-a

build-b:
  stage: build
  script: make build-b

test-a:
  stage: test
  needs: [build-a]
  script: make test-a

test-b:
  stage: test
  needs: [build-b]
  script: make test-b

test-integration:
  stage: test
  needs: [build-a, build-b]
  script: make test-integration

deploy-all:
  stage: deploy
  needs: [test-a, test-b, test-integration]
  script: make deploy
```

```
build-a ──→ test-a ──┐
                      ├──→ deploy-all
build-b ──→ test-b ──┤
                      │
          └──→ test-integration ──┘
```

---

## 5. GitLab CI Advanced

### Include Files

Split CI configuration across multiple files:

```yaml
# .gitlab-ci.yml
include:
  - local: 'ci/build.yml'
  - local: 'ci/test.yml'
  - local: 'ci/deploy.yml'
  - template: 'Workflows/MergeRequest-Pipelines.gitlab-ci.yml'
  - template: 'Security/SAST.gitlab-ci.yml'
  - template: 'Security/Dependency-Scanning.gitlab-ci.yml'
  - remote: 'https://gitlab.com/example/ci-templates/-/raw/main/security.yml'
  - project: 'my-group/shared-ci'
    file: '/templates/docker-build.yml'
    ref: v1.0
```

```yaml
# ci/build.yml
build:
  stage: build
  script: mvn package
```

```yaml
# ci/test.yml
test:
  stage: test
  script: mvn test
```

### CI/CD Variables

| Scope | Type | Visibility |
|-------|------|-----------|
| Project → Settings → CI/CD → Variables | Variable | Masked/Protected |
| Group → Settings → CI/CD → Variables | Variable | Inherited by sub-projects |
| Instance → Admin → CI/CD → Variables | Variable | All projects |

```yaml
# Protected variable — only available on protected branches/tags
# Masked variable — hidden in job logs
variables:
  DEPLOY_TOKEN: $DEPLOY_TOKEN          # masked, protected
  DB_PASSWORD: $DB_PASSWORD            # masked
  NAMESPACE: prod                      # plain text
```

Define variables in CI file:
```yaml
variables:
  APP_ENV: production
  DEPLOY_USER: deployer
```

### CI/CD for Kubernetes

Using GitLab Agent for Kubernetes:

```yaml
# .gitlab-ci.yml
deploy-k8s:
  stage: deploy
  image: bitnami/kubectl:1.28
  script:
    - kubectl config use-context my-cluster
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - kubectl rollout status deployment/app
  environment:
    name: production
    kubernetes:
      namespace: production
```

GitLab-managed apps:
- Ingress
- Cert-Manager
- Prometheus
- Runner
- Postgres
- Redis

### Review Apps

Review Apps create a temporary environment per merge request:

```yaml
review:
  stage: review
  image: alpine/k8s:1.28
  tags: [docker]
  script:
    - sed -i "s/__CI_ENVIRONMENT_SLUG__/$CI_ENVIRONMENT_SLUG/g" k8s/ review-deployment.yaml
    - kubectl apply -f k8s/review-deployment.yaml -n review-apps
    - kubectl rollout status deployment/review-$CI_ENVIRONMENT_SLUG -n review-apps
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.review.example.com
    on_stop: stop-review
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'

stop-review:
  stage: review
  image: alpine/k8s:1.28
  tags: [docker]
  variables:
    GIT_STRATEGY: none
  script:
    - kubectl delete deployment review-$CI_ENVIRONMENT_SLUG -n review-apps
    - kubectl delete service review-$CI_ENVIRONMENT_SLUG -n review-apps
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

---

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

---

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

---

## 8. Artifact Management

**GitHub Actions:** `actions/upload-artifact@v4` (name, path, retention-days) / `actions/download-artifact@v4`
**GitLab CI:** `artifacts: { paths, expire_in, expose_as }` — auto-downloaded via `dependencies`
**Jenkins:** `archiveArtifacts artifacts: 'target/*.jar'` — available at `${BUILD_URL}artifact/`

### Docker Registries

| Registry | Login | Push |
|----------|-------|------|
| Docker Hub | `docker login -u $USER -p $PASS` | `docker push myorg/app:tag` |
| GHCR | `docker/login-action@v3` with GITHUB_TOKEN | `ghcr.io/${{ github.repository }}:${{ github.sha }}` |
| GitLab | `docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY` | `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA` |
| Nexus | `docker login nexus.example.com:5000` | `nexus.example.com:5000/my-app:tag` |
| Artifactory | `docker login myrepo.jfrog.io` | `myrepo.jfrog.io/docker-local/my-app:tag` |

### Artifact Versioning

| Strategy | Example | When |
|----------|---------|------|
| Semantic | `1.2.3` | Tagged releases |
| Commit SHA | `a1b2c3d4` | Every build |
| Build number | `build-142` | Sequential |
| Git describe | `1.2.3-5-gabc1234` | Git-derived |

---

## 9. Pipeline Security

### Secret Scanning

**GitHub Secret Scanning:**
Automatically detects secrets in public repositories. Partner patterns (AWS, GCP, Azure, GitHub tokens, npm, etc.) + custom patterns.

Enable: Repository → Settings → Code security & analysis → Secret scanning → Enable

Custom patterns:
```
# Example: detect internal API tokens
ghs_[a-zA-Z0-9]{36}
```

**GitLab Secret Detection:**
```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml

secret_detection:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH =~ /^(main|develop)$/
```

Uses Gitleaks and TruffleHog under the hood.

**TruffleHog (standalone):**
```yaml
trufflehog:
  stage: scan
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog filesystem --directory=$CI_PROJECT_DIR --json | tee trufflehog-report.json
  artifacts:
    paths:
      - trufflehog-report.json
    when: always
```

### Signed Commits

```bash
# Configure GPG signing
gpg --full-generate-key
git config --global user.signingkey KEY_ID
git config --global commit.gpgsign true

# Verify signatures
git log --show-signature

# GitHub: Settings → SSH and GPG keys → New GPG key
# Enable: Settings → "Flag unsigned commits as unverified"
```

GitLab verified commits: Settings → Repository → Push rules → **Reject unsigned commits**

### SBOM Generation (CycloneDX)

```yaml
# GitHub Actions: uses: CycloneDX/gh-node-module-generatebom@v1 with path: . output: ./bom.json
# GitLab CI: npm install -g @cyclonedx/bom && cyclonedx-bom -o gl-sbom-$CI_COMMIT_SHORT_SHA.json
```

### Supply-Chain Security (SLSA)

SLSA 1–4 framework: build documented → version control + signed provenance → non-falsifiable provenance → two-person review. Use `slsa-framework/slsa-github-generator` for SLSA 3 provenance in GitHub Actions.

---

## 10. Testing in CI

### Unit Tests

```yaml
# GitHub Actions — Node.js with Jest
test:
  runs-on: ubuntu-22.04
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
    - run: npm ci
    - run: npm test -- --coverage
    - uses: actions/upload-artifact@v4
      with:
        name: coverage
        path: coverage/
```

```yaml
# GitLab CI — Python with pytest
unit-test:
  stage: test
  image: python:3.12
  script:
    - pip install -r requirements-dev.txt
    - pytest tests/ --junitxml=report.xml --cov-report=xml
  artifacts:
    reports:
      junit: report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

```groovy
// Jenkins — JUnit reporting
stage('Unit Tests') {
    steps {
        sh 'mvn test'
    }
    post {
        always {
            junit testResults: 'target/surefire-reports/TEST-*.xml'
        }
    }
}
```

### Integration Tests

```yaml
integration-test:
  stage: test
  image: docker:27
  services:
    - docker:27-dind
    - name: postgres:16
      alias: db
    - name: redis:7
      alias: cache
  variables:
    DB_HOST: db
    REDIS_HOST: cache
  script:
    - docker compose -f docker-compose.ci.yml up --abort-on-container-exit
    - docker compose -f docker-compose.ci.yml ps
```

```groovy
// Jenkins with Testcontainers
stage('Integration Tests') {
    agent {
        docker {
            image 'maven:3.9-eclipse-temurin-21'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    steps {
        sh 'mvn verify -Pintegration-tests'
    }
}
```

### Linting

```yaml
lint-eslint:
  stage: test
  image: node:20
  script:
    - npm ci
    - npm run lint
  allow_failure: true   # Lint failures don't block pipeline

lint-pylint:
  stage: test
  image: python:3.12
  script:
    - pip install pylint
    - pylint src/ --fail-under=8.0
```

```groovy
// Jenkins: parallel lint and style checks
stage('Lint') {
    parallel {
        stage('ESLint') {
            steps { sh 'npm run lint' }
        }
        stage('Prettier') {
            steps { sh 'npx prettier --check src/' }
        }
    }
}
```

### SAST — CodeQL

```yaml
# GitHub Actions — CodeQL
jobs:
  analyze:
    name: CodeQL Analyze
    runs-on: ubuntu-22.04
    permissions:
      security-events: write
      actions: read
    strategy:
      fail-fast: false
      matrix:
        language: [javascript, java, python]
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: security-and-quality
      - run: |
          npm ci
          npm run build
      - uses: github/codeql-action/analyze@v3
```

### SAST — SonarQube

```yaml
# GitLab CI — SonarQube Scanner
sonarqube:
  stage: scan
  image: sonarsource/sonar-scanner-cli:11
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  script:
    - sonar-scanner
      -Dsonar.projectKey=${CI_PROJECT_ID}
      -Dsonar.sources=.
      -Dsonar.host.url=${SONAR_HOST_URL}
      -Dsonar.login=${SONAR_TOKEN}
      -Dsonar.qualitygate.wait=true
  only:
    - main
    - merge_requests
```

```groovy
// Jenkins — SonarQube
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh 'mvn sonar:sonar'
        }
    }
}
stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

### SAST — Semgrep

```yaml
# GitHub Actions — Semgrep
jobs:
  semgrep:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: semgrep/semgrep-action@v1
        with:
          config: p/default
          auditOn: push
```

```yaml
# GitLab CI — Semgrep
semgrep:
  stage: scan
  image: semgrep/semgrep
  script:
    - semgrep --config=auto --json --output=semgrep-report.json
  artifacts:
    paths:
      - semgrep-report.json
    reports:
      sast: semgrep-report.json
```

### Container Scanning — Trivy

```yaml
# GitHub Actions
- name: Scan with Trivy
  uses: aquasec/trivy-action@master
  with:
    image-ref: my-app:${{ github.sha }}
    format: sarif
    output: trivy-results.sarif
    severity: HIGH,CRITICAL
```

```yaml
# GitLab CI (include template)
include: - template: Security/Container-Scanning.gitlab-ci.yml
```

```groovy
// Jenkins
sh 'docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 1 ghcr.io/myorg/app:${IMAGE_TAG}'
```

### DAST (Dynamic Application Security Testing)

```yaml
# GitLab CI: include: - template: DAST.gitlab-ci.yml
# GitHub Actions: uses: zaproxy/action-full-scan@v0.11.0 with target: https://staging.example.com
```

---

## 11. Deployment Strategies

### Rolling Update

Replace instances one by one with zero downtime: `kubectl set image deployment/app app=myapp:1.2.0 && kubectl rollout status deployment/app`. Kubernetes parameters: `maxSurge: 1` (extra pod), `maxUnavailable: 0` (keep all running).

### Blue/Green Deployment

Two identical environments (blue/green). Deploy to inactive, switch traffic, drain old:
```bash
kubectl apply -f k8s/deployment-green.yaml
kubectl rollout status deployment/app-green -n production
kubectl patch service app -n production -p '{"spec":{"selector":{"version":"green"}}}'
kubectl scale deployment/app-blue --replicas=0 -n production
```

### Canary Deployment

Route traffic % to new version, gradually increase. Istio VirtualService: `weight: 10` → canary, `weight: 90` → stable. Progressive delivery with Flagger automates canary analysis and rollback based on metrics (error rate, latency).

### Deploying to Kubernetes from Pipeline

**kubectl (direct):**
```yaml
# GitLab CI
deploy:
  image: alpine/k8s:1.28
  script:
    - kubectl config set-cluster k8s --server=$K8S_SERVER --insecure-skip-tls-verify
    - kubectl config set-credentials deployer --token=$K8S_TOKEN
    - kubectl config set-context k8s --cluster=k8s --user=deployer
    - kubectl config use-context k8s
    - sed -i "s|image:.*|image: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA|" k8s/deployment.yaml
    - kubectl apply -f k8s/
    - kubectl rollout status deployment/my-app -n production --timeout=5m
```

**Helm:**
```yaml
# GitHub Actions — Helm deploy
jobs:
  helm-deploy:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Configure K8s context
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}
      - name: Deploy with Helm
        uses: bitovi/github-actions-deploy-helm-kubernetes@v1
        with:
          namespace: production
          releases: |
            app:
              chart: ./helm/app
              values: ./helm/values-production.yaml
              set:
                image.tag: ${{ github.sha }}
```

**GitOps with ArgoCD:**
```yaml
# Pipeline only updates the Git repo; ArgoCD syncs to cluster
jobs:
  gitops-update:
    runs-on: ubuntu-22.04
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          repository: myorg/gitops-config
          token: ${{ secrets.GITOPs_TOKEN }}
      - name: Update image tag in GitOps repo
        run: |
          cd k8s/overlays/production
          kustomize edit set image my-app=ghcr.io/myorg/my-app:${{ github.sha }}
          git config user.name "CI Bot"
          git config user.email "ci@example.com"
          git add .
          git commit -m "Update my-app to ${{ github.sha }}"
          git push
```

**GitOps with Flux:**
```yaml
# Flux Image Update Automation
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-system
  update:
    strategy: Setters
    path: ./k8s/overlays/production
```

### Deploy to VMs/Cloud with Ansible

```yaml
# GitHub Actions — Ansible deploy
jobs:
  ansible-deploy:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Run Ansible playbook
        uses: dawidd6/action-ansible-playbook@v2
        with:
          playbook: deploy.yml
          directory: ./ansible
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          inventory: |
            [web]
            10.0.1.100
            10.0.1.101
            [web:vars]
            ansible_user=deployer
```

```yaml
# deploy.yml
- hosts: web
  become: yes
  tasks:
    - name: Pull new Docker image
      docker_image:
        name: ghcr.io/myorg/my-app:{{ image_tag }}
        source: pull

    - name: Restart container
      docker_container:
        name: my-app
        image: ghcr.io/myorg/my-app:{{ image_tag }}
        state: started
        restart: yes
        ports:
          - "80:8080"
```

### Deploy with Terraform in Pipeline

```yaml
stages: [build, deploy, terraform]
terraform-plan:
  stage: terraform
  image: hashicorp/terraform:1.9
  script: terraform init && terraform plan -out=plan.tfplan -var="image_tag=$CI_COMMIT_SHORT_SHA"
  artifacts: { paths: [terraform/plan.tfplan] }
  rules: [{ if: $CI_MERGE_REQUEST_IID }, { if: $CI_COMMIT_BRANCH == "main" }]
terraform-apply:
  stage: terraform
  script: terraform apply plan.tfplan
  dependencies: [terraform-plan]
  rules: [{ if: $CI_COMMIT_BRANCH == "main", when: manual }]
```

---

## 12. Monitoring Pipelines

| Metric | Source | What It Tells |
|--------|--------|---------------|
| Build duration | All CI systems | Pipeline efficiency |
| Success rate | API | Pipeline stability |
| Queue time | Runner logs | Runner capacity |
| Test pass rate | JUnit | Code quality |
| Coverage % | Jacoco/Cobertura | Test quality |

**Prometheus metrics:**
- GitLab: `gitlab_runner_jobs_total`, `gitlab_ci_pipeline_duration_seconds`
- Jenkins: `default_jenkins_builds_success_total`, `default_jenkins_builds_duration_milliseconds_sum`, `default_jenkins_queue_size_value`

**Grafana dashboard panels:** Pipeline Success Rate (7d), Build Duration p50/p95/p99, Active Runners, Queue Depth,
Panel 5: Test Pass Rate — bar chart
Panel 6: Top Failed Jobs — table
```

**GitHub Actions API:**
```bash
# Get workflow run stats
gh run list --repo myorg/my-app --limit 100 --json conclusion,createdAt,updatedAt,duration

# Get job-level metrics
gh run view RUN_ID --repo myorg/my-app --log
```

**GitLab CI API:**
```bash
# Pipeline statistics
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/pipelines?per_page=100"

# Job duration per pipeline
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs"
```

### Runner Utilization

```bash
# GitLab Runner autoscaling metrics
docker exec gitlab-runner cat /var/log/gitlab-runner.log | grep "processed"

# Jenkins — Manage Jenkins → Load Statistics: graphs of executor usage
# Jenkins — Script Console: Jenkins.instance.computers.each { println it }
```

### Alerts for Failures

```yaml
# GitHub Actions — Slack notification on failure
jobs:
  notify:
    runs-on: ubuntu-22.04
    if: failure() && github.ref == 'refs/heads/main'
    needs: [build, test, deploy]
    steps:
      - name: Slack Notification
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_CHANNEL: '#ci-cd-alerts'
          SLACK_COLOR: danger
          SLACK_TITLE: 'Pipeline failed on main'
          SLACK_MESSAGE: |
            Job: ${{ github.workflow }}
            Run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
```

```yaml
# GitLab CI — email + Slack
notify-failure:
  stage: .post
  script:
    - |
      curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"❌ Pipeline failed: $CI_PIPELINE_URL\"}" \
        $SLACK_WEBHOOK_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_failure
```

```groovy
// Jenkins — email notification
post {
    failure {
        emailext(
            to: 'team@example.com',
            subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
                Pipeline failed: ${env.BUILD_URL}
                Branch: ${env.BRANCH_NAME}
                Commit: ${env.GIT_COMMIT}
                Check: ${env.BUILD_URL}console
            """
        )
    }
}
```

---

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

---

## Deep Understanding

### How CI Systems Work Internally

**Polling vs Webhooks:** Polling checks the repo periodically (e.g., Jenkins `pollSCM` every 5 min). Most polls waste resources but work behind firewalls. Webhooks send HTTP POST on each event — instant, no wasted requests. GitHub goes to `/github-webhook/`, GitLab to project webhooks.

**How Runners Pick Up Jobs:** GitHub Actions runners poll `api.github.com` with JWT, receive work envelope (job ID, URL, token), download steps, execute, stream logs. GitLab runners poll `api/v4/jobs/request` with tags; server returns 409 (no job) or 201 (assigned). Jenkins agents connect via SSH/JNLP/WebSocket; master sends jobs when executors are free.

**Container Runners:** Docker-in-Docker (DinD) uses a sibling `docker:dind` container as Docker daemon for builds. Kubernetes pod runners (GitLab K8s executor) create a pod per job with build + service + optional dind containers, deleted when done.

**Composite Actions (GitHub):** Runner reads `action.yml`, parses `runs.steps`, injects each step into the calling workflow's step list at the `uses` point — syntactic AST-level step injection, not a function call.

**Reusable Workflows:** Caller dispatches a new isolated workflow run. Inputs/secrets passed via API (encrypted). Outputs propagated via `$GITHUB_OUTPUT` back through the API. The callee checks out its own code — no workspace sharing.

**Jenkins Pipeline DSL → Groovy AST:** The DSL is parsed by `groovy-parser` into AST, transformed by CPS AST transformers (`org.jenkinsci.plugins.workflow.cps.DSL`), compiled to bytecode, and run inside a **Continuation Passing Style** engine. CPS serializes each stage's execution state to disk when the pipeline pauses (waiting for input/agent) and deserializes on resume. This is why all variables must be `Serializable`.

**CI vs CD Infrastructure:** CI = build servers, test runners, caches — CPU-heavy, short-lived, auto-scalable. CD = deployment agents, orchestrators, load balancers — need network access to targets, secrets, rollback. CI *produces* artifacts; CD *consumes* them in environments. Network topology: CI in isolated build network; CD has controlled production access via bastions/VPN/service mesh.

---

## Command Reference

| Concept | GitHub Actions | GitLab CI | Jenkins |
|---------|---------------|-----------|---------|
| Config file | `.github/workflows/*.yml` | `.gitlab-ci.yml` | `Jenkinsfile` (or Pipeline config) |
| Language | YAML | YAML | Groovy |
| Trigger | `on: [push, pull_request]` | `push`, `merge_request` | `triggers { pollSCM() }` |
| Runner selection | `runs-on: ubuntu-22.04` | `tags: [docker]` | `agent { label 'linux' }` |
| Environment variables | `env:` | `variables:` | `environment { VAR = 'val' }` |
| Secrets | `${{ secrets.NAME }}` | `$SECRET_NAME` | `withCredentials([string()])` |
| Stages | `jobs:` (parallel) | `stages:` + job `stage:` | `stages { stage('Build') }` |
| Dependencies | `needs: [job1]` | `needs: [job1]` (DAG) | `stage('Test') { dependsOn (job) }` |
| Parallel execution | Matrix + `strategy.matrix` | Jobs in same stage | `parallel { stage('A') }` |
| Artifacts | `actions/upload-artifact` | `artifacts:` | `archiveArtifacts()` |
| Cache | `actions/cache` | `cache:` | `stash`/`unstash` |
| Conditional | `if:` expression | `rules:` / `only:` / `except:` | `when { branch 'main' }` |
| Manual approval | `environment` protection + `workflow_dispatch` | `when: manual` | `input { message "Approve?" }` |
| Container build | `docker/build-push-action` | `docker build` in script | `docker.build()` |
| Container scan | `aquasecurity/trivy-action` | `Container-Scanning.gitlab-ci.yml` | `trivy` in shell |
| SAST | `github/codeql-action` | `SAST.gitlab-ci.yml` | `SonarQube` plugin |
| CD to K8s | `azure/k8s-set-context` + `kubectl` | `kubectl` in script | `kubernetes` plugin |
| GitOps | Custom `kubectl` or `argocd` action | `kubectl` or agent | `argocd` plugin |
| Monitoring | GitHub Actions API | GitLab API + Prometheus | Jenkins Metrics plugin |
| Logs | Live streaming in UI | Live streaming | Console output + Blue Ocean |
| Triggers (CI) | Webhook (instant) | Webhook (instant) | Webhook or Polling |

---

## What's Coming in Part 54

**Part 54: Advanced Configuration Management — Puppet, Salt, Chef**

We will cover:
- Declarative vs imperative configuration management
- Puppet: manifests, modules, classes, resources, Hiera, PuppetDB, Puppet Server
- Salt: Salt Master/Minion, states, pillars, grains, Salt SSH, Salt Cloud
- Chef: cookbooks, recipes, resources, Chef Server, Chef Solo, Ohai, data bags
- Comparison and migration paths between tools
- Integrating CM with CI/CD pipelines (GitOps for configs)
- Idempotency, convergence, drift detection, compliance as code

---

## Self-Test

1. What is the difference between continuous delivery and continuous deployment?
2. Write a GitHub Actions `on:` trigger that runs on push to `main` and on a schedule every 6 hours.
3. What does the `strategy.matrix` keyword do in GitHub Actions?
4. How does `needs:` in GitLab CI differ from stage-based execution?
5. Write a GitLab CI job that only runs on merge requests that change files in `src/`.
6. What is the purpose of `artifacts:` in GitLab CI? How is it different from `cache:`?
7. Explain the master/agent architecture in Jenkins.
8. Write a Declarative Jenkins Pipeline stage that runs `mvn test` and archives the JUnit results.
9. What is a multibranch pipeline in Jenkins?
10. How does OIDC improve security compared to storing cloud credentials?
11. What is the difference between SAST and DAST?
12. Write a Trivy command to scan a Docker image and output SARIF format.
13. Explain blue/green deployment vs canary deployment.
14. How does a container-based runner (e.g., GitLab Runner with Docker executor) work internally?
15. What is SLSA and why is it important for supply-chain security?

**Score:** 12/15 correct = ready for Part 54.

---
*Linux SysAdmin Course | Part 53 of ∞ | Reverse Engineering Approach*
*Previous → Part 52: Kubernetes Administration*
*Next → Part 54: Advanced Configuration Management*

[← Previous](part52.md) | [Next →](part54.md)
