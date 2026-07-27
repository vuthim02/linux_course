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



---

[← Previous](02-2-github-actions.md) | [↑ Index](index.md) | [Next →](04-4-gitlab-ci.md)
