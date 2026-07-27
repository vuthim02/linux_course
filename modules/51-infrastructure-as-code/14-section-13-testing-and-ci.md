## 🔍 Section 13: Testing and CI

### Validation

```bash
# Basic syntax check
terraform validate

# Format check
terraform fmt -check -recursive

# Plan (dry run)
terraform plan -out=tfplan
```

### Static Analysis Tools

**tflint** — Terraform-specific linter:

```bash
# Install
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Run
tflint --init
tflint --recursive
```

```hcl
# .tflint.hcl
plugin "aws" {
  enabled = true
  version = "0.24.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Environment", "Name", "Owner"]
}
```

**checkov** — Security scanner (supports Terraform, CloudFormation, K8s):

```bash
# Install
pip install checkov

# Run
checkov -d .
```

```bash
# Scan results example
terraform scan results:

Passed checks: 15, Failed checks: 2, Skipped checks: 0

Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
        FAILED for resource: aws_s3_bucket.data
        File: main.tf:15-25

Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket is securely encrypted"
        FAILED for resource: aws_s3_bucket.data
        File: main.tf:15-25
```

**terrascan** — Static code analyzer:

```bash
# Install
curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" -o terrascan.tar.gz
tar -xzf terrascan.tar.gz && sudo mv terrascan /usr/local/bin/

# Run
terrascan scan -d .
```

### CI Pipeline Integration (GitHub Actions)

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./infra

    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Format
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: tflint
        uses: terraform-linters/setup-tflint@v3
        with:
          tflint_version: v0.47.0

      - run: tflint --recursive

      - name: Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: infra
          framework: terraform

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan
          path: infra/tfplan
```

### Terratest — Integration Testing

```go
// test/terraform_test.go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestTerraformAwsInstance(t *testing.T) {
  terraformOptions := &terraform.Options{
    TerraformDir: "../examples/instance",
    Vars: map[string]interface{}{
      "instance_type": "t3.micro",
    },
  }

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

  instanceID := terraform.Output(t, terraformOptions, "instance_id")
  assert.Contains(t, instanceID, "i-")
}
```

```bash
go test -v -timeout 30m
```

---



---

[← Previous](13-section-12-terraform-cloud-enterprise.md) | [↑ Index](index.md) | [Next →](15-section-14-best-practices.md)
