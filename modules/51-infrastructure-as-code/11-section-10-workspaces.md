## 🔍 Section 10: Workspaces

### What Are Workspaces?

Workspaces allow you to manage multiple environments (dev, staging, prod) with the **same configuration** but **separate state files**.

```
Local state:
  terraform.tfstate            ← "default" workspace
  terraform.tfstate.d/dev/     ← "dev" workspace
  terraform.tfstate.d/prod/    ← "prod" workspace

S3 remote state:
  s3://bucket/env:/default/terraform.tfstate
  s3://bucket/env:/dev/terraform.tfstate
  s3://bucket/env:/prod/terraform.tfstate
```

### Workspace Commands

```bash
# List workspaces
terraform workspace list
  * default

# Create a new workspace (and switch to it)
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between workspaces
terraform workspace select staging
terraform workspace select default

# Show current workspace
terraform workspace show
# → staging
```

### Using terraform.workspace in Config

You can reference the current workspace name inside your config:

```hcl
locals {
  # Use workspace name in resource naming
  env_name = terraform.workspace == "default" ? "dev" : terraform.workspace
}

resource "aws_s3_bucket" "data" {
  bucket = "myapp-data-${local.env_name}"

  tags = {
    Name        = "myapp-data-${local.env_name}"
    Environment = local.env_name
  }
}
```

### Variable Values Per Workspace

```hcl
# terraform.tfvars
instance_type_map = {
  dev     = "t3.micro"
  staging = "t3.small"
  prod    = "m5.large"
}

instance_count_map = {
  dev     = 1
  staging = 2
  prod    = 3
}
```

```hcl
# main.tf
variable "instance_type_map" {
  type = map(string)
}

variable "instance_count_map" {
  type = map(number)
}

locals {
  env = terraform.workspace == "default" ? "dev" : terraform.workspace
}

resource "aws_instance" "web" {
  count         = lookup(local.instance_count_map, local.env, 1)
  ami           = data.aws_ami.ubuntu.id
  instance_type = lookup(local.instance_type_map, local.env, "t3.micro")

  tags = {
    Name        = "web-${local.env}-${count.index + 1}"
    Environment = local.env
  }
}
```

### Environment Separation Pattern

```bash
# Dev
terraform workspace new dev
terraform apply

# Staging
terraform workspace new staging
terraform apply

# Prod
terraform workspace new prod
terraform apply

# Verify separation
terraform workspace select dev
terraform state list
# → only dev resources

terraform workspace select prod
terraform state list
# → only prod resources
```

---



---

[← Previous](10-section-9-modules.md) | [↑ Index](index.md) | [Next →](12-section-11-provisioners.md)
