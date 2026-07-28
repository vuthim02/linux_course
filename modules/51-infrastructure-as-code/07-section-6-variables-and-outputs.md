## 🔍 Section 6: Variables and Outputs

### Input Variables

```hcl
# variables.tf — full spec
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "sensitive_token" {
  description = "API token"
  type        = string
  sensitive   = true  # Hidden from CLI output
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr_block = string
    az         = string
  }))
}
```

### Variable Types

| Type | Example | Description |
|------|---------|-------------|
| `string` | `"t3.micro"` | A string value |
| `number` | `42` | A number |
| `bool` | `true` | Boolean |
| `list(type)` | `["a", "b"]` | Ordered list |
| `map(type)` | `{key = "val"}` | Key-value map |
| `set(type)` | `toset(["a", "b"])` | Unordered unique set |
| `object({...})` | `{name = string, age = number}` | Structured record |
| `tuple([...])` | `["a", 1, true]` | Positional sequence |
| `any` | anything | Accept any type |

### Variable Precedence (highest to lowest)

```
 1. -var or -var-file CLI flags        — Highest
 2. *.auto.tfvars or *.auto.tfvars.json — Auto-loaded
 3. terraform.tfvars or terraform.tfvars.json — Default var file
 4. Environment variables (TF_VAR_*)   — env prefix
 5. default in variable block          — Lowest
```

```bash
# Order of precedence examples:
$ export TF_VAR_environment=staging          # #4
$ terraform apply -var="environment=prod"    # #1 (overrides all)
```

### terraform.tfvars Example

```hcl
# terraform.tfvars
environment      = "production"
instance_type    = "m5.large"
sensitive_token  = "sk-abc123..."
enable_monitoring = true
```

### Output Values

```hcl
# outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The VPC ID"
}

output "instance_ips" {
  value       = aws_instance.web[*].public_ip
  description = "Public IPs of web instances"
}

output "database_endpoint" {
  value       = aws_db_instance.main.endpoint
  sensitive   = true  # Don't show in plain text
  description = "Database connection endpoint"
}
```

View outputs after apply:

```bash
terraform output
terraform output vpc_id
terraform output -json instance_ips
```





[← Previous](06-section-5-hcl-syntax-deep.md) | [↑ Index](index.md) | [Next →](08-section-7-state-management.md)
