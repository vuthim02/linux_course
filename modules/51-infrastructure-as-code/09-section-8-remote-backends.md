## 🔍 Section 8: Remote Backends

### Comparison of Remote Backends

| Backend | Locking | Encryption | Best For |
|---------|---------|------------|----------|
| **S3 + DynamoDB** | Yes (DDB) | SSE-S3/KMS | AWS shops |
| **GCS** | Yes (cloud storage object) | AES256/CMEK | GCP shops |
| **AzureRM** | Yes (Blob Storage lease) | SSE | Azure shops |
| **Terraform Cloud** | Yes | Yes | Multi-cloud, teams |
| **Consul** | Yes (session) | Optional | Self-hosted |
| **etcd** | Yes | No | Self-hosted, Kubernetes |

### S3 + DynamoDB (Full Example)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-company-2026"
    key            = "${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key"
  }
}
```

Bootstrap script to create the backend resources:

```hcl
# bootstrap/main.tf — run once, then migrate state
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-company-2026"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### Partial Configuration

Don't hardcode everything in the backend block. Use partial config:

```hcl
# backend.tf — partial config (values passed at init)
terraform {
  backend "s3" {
    # bucket, key, region passed at init time
  }
}
```

```bash
# Pass the rest via init
terraform init \
  -backend-config="bucket=terraform-state-company-2026" \
  -backend-config="key=prod/network.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks"
```

### Migration

To migrate from local to remote state:

```bash
# 1. Add backend block to config
# 2. Run init with -reconfigure (destructive) or -migrate (non-destructive)
terraform init -migrate

# Terraform copies local state to the remote backend
# Then asks if you want to copy existing state:
# Do you want to copy existing state to the new backend?
#   Enter a value: yes
```





[← Previous](08-section-7-state-management.md) | [↑ Index](index.md) | [Next →](10-section-9-modules.md)
