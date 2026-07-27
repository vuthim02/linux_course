## 6. CI/CD Pipeline

### GitHub Actions — Full Workflow

```yaml
# .github/workflows/deploy.yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
      - staging
  pull_request:
    branches:
      - main

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: capstone-api
  K8S_NAMESPACE: production
  HELM_CHART_PATH: helm

jobs:
  lint:
    name: Lint and Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install ruff mypy
      - run: ruff check app/ --fix
      - run: ruff format app/ --check
      - run: mypy app/ --ignore-missing-imports

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        ports:
          - 5432:5432
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt pytest httpx
      - run: |
          cat > pytest.ini <<EOF
          [pytest]
          env =
            DATABASE_URL=postgresql://testuser:testpass@localhost:5432/testdb
            REDIS_URL=redis://localhost:6379/0
          EOF
      - run: pytest tests/ -v --cov=app --cov-report=term-missing --junitxml=test-results.xml
      - uses: dorny/test-reporter@v1
        if: success() || failure()
        with:
          name: Test Results
          path: test-results.xml
          reporter: java-junit

  build-and-push:
    name: Build and Push Image
    needs: [lint, test]
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: GitHubActions

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Set image tag
        id: vars
        run: |
          SHORT_SHA=$(git rev-parse --short HEAD)
          BRANCH=${GITHUB_REF_NAME}
          echo "tag=${BRANCH}-${SHORT_SHA}-$(date +%s)" >> $GITHUB_OUTPUT
          echo "branch=${BRANCH}" >> $GITHUB_OUTPUT

      - name: Build Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ steps.vars.outputs.tag }}
        run: |
          docker build \
            --build-arg BUILDKIT_INLINE_CACHE=1 \
            --cache-from $ECR_REGISTRY/$ECR_REPOSITORY:main-latest \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
            -t $ECR_REGISTRY/$ECR_REPOSITORY:${{ steps.vars.outputs.branch }}-latest \
            .

      - name: Scan image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ steps.vars.outputs.tag }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: 1

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif

      - name: Push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ steps.vars.outputs.tag }}
        run: |
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:${{ steps.vars.outputs.branch }}-latest

      - name: Update image tag for deploy
        run: |
          echo "IMAGE_TAG=${{ steps.vars.outputs.tag }}" >> $GITHUB_ENV
          echo "ECR_REGISTRY=${{ steps.login-ecr.outputs.registry }}" >> $GITHUB_ENV

  deploy-staging:
    name: Deploy to Staging
    needs: build-and-push
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name capstone-cluster --region $AWS_REGION

      - name: Deploy Helm chart
        run: |
          helm upgrade --install capstone-api ./$HELM_CHART_PATH \
            --namespace staging \
            --create-namespace \
            --values ./$HELM_CHART_PATH/values.yaml \
            --values ./$HELM_CHART_PATH/values-staging.yaml \
            --set image.tag=${{ env.IMAGE_TAG }} \
            --set image.repository=${{ env.ECR_REGISTRY }}/$ECR_REPOSITORY \
            --wait --timeout 5m

      - name: Integration test
        run: |
          sleep 30
          ENDPOINT=$(kubectl get ingress -n staging -o jsonpath='{.items[0].spec.rules[0].host}')
          curl -f --retry 5 --retry-delay 10 "https://${ENDPOINT}/health" || exit 1

  deploy-production:
    name: Deploy to Production
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.capstone.example.com
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --name capstone-cluster --region $AWS_REGION

      - name: Deploy Helm chart
        run: |
          helm upgrade --install capstone-api ./$HELM_CHART_PATH \
            --namespace production \
            --create-namespace \
            --values ./$HELM_CHART_PATH/values.yaml \
            --values ./$HELM_CHART_PATH/values-prod.yaml \
            --set image.tag=${{ env.IMAGE_TAG }} \
            --set image.repository=${{ env.ECR_REGISTRY }}/$ECR_REPOSITORY \
            --wait --timeout 5m

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/capstone-api -n production --timeout=3m
          kubectl get pods -n production -o wide

      - name: Smoke test
        run: |
          ENDPOINT=$(kubectl get ingress -n production -o jsonpath='{.items[0].spec.rules[0].host}')
          curl -f --retry 5 --retry-delay 10 "https://${ENDPOINT}/health" || exit 1
          curl -s "https://${ENDPOINT}/metrics" | grep -q "app_requests_total" || exit 1
```

### OIDC IAM Role for GitHub Actions

```hcl
# terraform/modules/iam/github-actions-role.tf
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.cluster_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = var.ecr_repository_arns
      },
      {
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = ["*"]
      },
    ]
  })
}
```

---



---

[← Previous](05-5-application-deployment.md) | [↑ Index](index.md) | [Next →](07-7-database-and-stateful-services.md)
