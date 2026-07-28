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





[← Previous](09-9-pipeline-security.md) | [↑ Index](index.md) | [Next →](11-11-deployment-strategies.md)
