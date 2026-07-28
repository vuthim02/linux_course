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





[← Previous](01-1-cicd-concepts.md) | [↑ Index](index.md) | [Next →](03-3-github-actions-advanced.md)
