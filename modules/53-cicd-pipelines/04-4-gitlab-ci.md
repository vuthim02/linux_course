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





[← Previous](03-3-github-actions-advanced.md) | [↑ Index](index.md) | [Next →](05-5-gitlab-ci-advanced.md)
