## 🔍 Section 7: State Management

### Why State Matters

Terraform uses **state** to:

1. **Map config to real infrastructure** — knows `aws_instance.web` is `i-0abcd1234`
2. **Track metadata** — dependencies, attributes, sensitive values
3. **Improve performance** — can compare state vs config without API calls
4. **Enable collaboration** — remote state allows teams to work together

### Local State (Default)

```hcl
# No backend config → local state
# Creates: terraform.tfstate in the current directory
```

Problems with local state:
- Lost if your machine dies
- No locking (two people running apply at the same time = corrupted state)
- Not shared with a team

### Remote State

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "production/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### State Locking with DynamoDB

Prevents concurrent operations:

```bash
# Create the DynamoDB table (one-time)
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

When you run `terraform apply`, Terraform acquires a lock in DynamoDB. Another user running apply simultaneously gets:

```
Error: Error acquiring the state lock

Lock Info:
  ID:         abc123
  Path:       my-company-terraform-state/production/network/terraform.tfstate
  Operation:  apply
  Who:        tim@dev-machine
  Version:    1.5.0
  Created:    2026-06-24 14:00:00
  Info:       https://docs.opensource.microsoft.com/

Terraform acquires a lock during operations. Use -lock=false to override.
```

Force unlock (use carefully):

```bash
terraform force-unlock <LOCK_ID>
```

### terraform state Commands

```bash
# List all resources in state
terraform state list

# Show details of one resource
terraform state show aws_instance.web

# Move a resource (rename it in state)
terraform state mv aws_instance.web aws_instance.frontend

# Remove a resource from state (without destroying it)
terraform state rm aws_s3_bucket.data

# Pull state to stdout
terraform state pull > backup.tfstate

# Push state file (DANGEROUS)
terraform state push backup.tfstate

# Replace provider in state (after provider rename)
terraform state replace-provider hashicorp/aws registry.example.com/awesomecorp/aws
```

### State File Format

State is JSON. Never edit it by hand:

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "resources": [
    {
      "module": "root",
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-0abcd1234",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t3.micro",
            "public_ip": "54.123.45.67"
          }
        }
      ]
    }
  ]
}
```

### Sensitive Data in State

State files can contain **plaintext secrets** (passwords, keys, tokens). Protect them:

1. **Enable encryption** on the backend (S3 SSE-S3/SSE-KMS, GCS encryption)
2. **Restrict access** with IAM roles and bucket policies
3. **Enable audit logging** (S3 access logs, CloudTrail)
4. **Use `sensitive = true`** in variables/outputs (still in state, but hidden from CLI)
5. **Use a secrets manager** for true secrets (AWS Secrets Manager, Vault)





[← Previous](07-section-6-variables-and-outputs.md) | [↑ Index](index.md) | [Next →](09-section-8-remote-backends.md)
