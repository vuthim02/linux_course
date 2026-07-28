## 7. Image Pipeline

### Versioning Images

Three common strategies, often combined:

```hcl
# Strategy 1: Semantic Version (manual tag)
variable "version" {
  type    = string
  default = "1.2.3"
}

locals {
  ami_name = "myapp-${var.version}"
}

# Strategy 2: Timestamp
locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name  = "myapp-${local.timestamp}"
}

# Strategy 3: Git Commit Hash (from CI)
variable "commit_hash" {
  type    = string
  default = "dev"
}

locals {
  ami_name  = "myapp-${var.commit_hash}-${local.timestamp}"
}

# Combined
locals {
  timestamp   = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name    = "myapp-${var.version}-${var.commit_hash}-${local.timestamp}"
}
```

```bash
# Pass commit hash from CI
packer build \
  -var "version=$(git describe --tags --always --dirty)" \
  -var "commit_hash=$(git rev-parse --short HEAD)" \
  -var "environment=staging" \
  template.pkr.hcl
```

### Image Pipeline in CI (GitHub Actions)

```yaml
# .github/workflows/image-pipeline.yml
name: Image Pipeline

on:
  push:
    branches: [main]
    paths:
      - 'packer/**'
      - 'ansible/**'
      - 'scripts/**'
      - '.github/workflows/image-pipeline.yml'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - prod

env:
  PACKER_VERSION: "1.12.0"
  TF_VERSION: "1.9.0"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}
      - name: Check Packer format
        run: packer fmt -check packer/
      - name: Validate template
        run: packer validate packer/aws-nginx.pkr.hcl

  build:
    needs: lint
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    environment: ${{ github.event.inputs.environment || 'staging' }}

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-packer
          aws-region: us-east-1

      - name: Set build variables
        id: vars
        run: |
          echo "VERSION=$(git describe --tags --always --dirty)" >> $GITHUB_OUTPUT
          echo "COMMIT_HASH=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
          echo "TIMESTAMP=$(date +%Y%m%d%H%M%S)" >> $GITHUB_OUTPUT

      - name: Packer init
        working-directory: packer
        run: packer init .

      - name: Packer build
        working-directory: packer
        run: |
          packer build \
            -var "version=${{ steps.vars.outputs.VERSION }}" \
            -var "commit_hash=${{ steps.vars.outputs.COMMIT_HASH }}" \
            -var "environment=${{ github.event.inputs.environment || 'staging' }}" \
            -var "region=us-east-1" \
            -machine-readable \
            aws-nginx.pkr.hcl | tee build.log

      - name: Extract AMI ID
        id: ami
        run: |
          AMI_ID=$(grep 'artifact,0,id' packer/build.log | cut -d: -f2)
          echo "ami_id=$AMI_ID" >> $GITHUB_OUTPUT
          echo "Generated AMI: $AMI_ID"

      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'image'
          image-ref: ${{ steps.ami.outputs.ami_id }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Promote to staging
        if: success()
        run: |
          aws ec2 create-tags \
            --resources ${{ steps.ami.outputs.ami_id }} \
            --tags Key=Promoted,Value=staging Key=Version,Value=${{ steps.vars.outputs.VERSION }}

      - name: Deploy to staging ASG
        if: success()
        run: |
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name webapp-staging \
            --preferences '{"InstanceWarmup": 60, "MinHealthyPercentage": 80}'

  promote-to-prod:
    needs: build
    if: github.event.inputs.environment == 'prod' || github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-packer
          aws-region: us-east-1

      - name: Copy AMI to prod account
        run: |
          aws ec2 copy-image \
            --source-region us-east-1 \
            --source-image-id $(<ami-id.txt) \
            --name "webapp-prod-$(date +%Y%m%d%H%M%S)" \
            --destination-region us-east-1
```

### Storing Images

```bash
# AWS: List AMIs
aws ec2 describe-images --owners self --query 'Images[*].[ImageId,Name,CreationDate]' --output table

# AWS: Get latest AMI by tag
aws ec2 describe-images \
  --filters "Name=tag:Promoted,Values=staging" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text

# GCE: List images
gcloud compute images list --project=my-project --no-standard-images

# Azure: List managed images
az image list --resource-group packer-images-rg --output table

# Azure: Shared Image Gallery
az sig image-version list \
  --gallery-name myGallery \
  --gallery-image-definition webapp \
  --resource-group packer-images-rg
```

### Image Promotion

```
                    ┌──────────┐
                    │   Dev    │  (auto-build on PR merge)
                    │  v1.2.3  │
                    └────┬─────┘
                         │ Test passes
                         ▼
                    ┌──────────┐
                    │ Staging  │  (manual or auto-promote)
                    │  v1.2.3  │
                    └────┬─────┘
                         │ Smoke tests pass + sign-off
                         ▼
                    ┌──────────┐
                    │   Prod   │  (manual approval gate)
                    │  v1.2.3  │
                    └──────────┘
```





[← Previous](06-6-cloud-init.md) | [↑ Index](index.md) | [Next →](08-8-security-hardening-in-images.md)
