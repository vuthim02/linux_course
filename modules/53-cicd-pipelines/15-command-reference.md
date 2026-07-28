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





[← Previous](14-deep-understanding.md) | [↑ Index](index.md) | [Next →](16-whats-coming-in-part-54.md)
