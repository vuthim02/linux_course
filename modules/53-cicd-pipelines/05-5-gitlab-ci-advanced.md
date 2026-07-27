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



---

[← Previous](04-4-gitlab-ci.md) | [↑ Index](index.md) | [Next →](06-6-jenkins.md)
