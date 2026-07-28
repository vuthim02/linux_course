## 🔍 Section 2: Terraform Overview

### What Is Terraform?

Terraform is an open-source IaC tool by **HashiCorp**. It manages infrastructure across **2000+ providers** (AWS, GCP, Azure, Kubernetes, GitHub, Cloudflare, etc.).

Instead of learning 14 different CLIs (`aws`, `gcloud`, `az`, `kubectl`, `gh`...), you write one HCL config and run one CLI:

```
$ terraform apply
```

### HCL Syntax — A First Glance

HCL (HashiCorp Configuration Language) is the language Terraform uses. It's human-readable and structured in blocks:

```hcl
# Block type "resource" — creates infrastructure
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  tags = {
    Name = "web-server"
  }
}
```

### The Terraform Workflow

```
    ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌──────────┐
    │  init    │────▶│  plan   │────▶│  apply  │────▶│  destroy │
    └─────────┘     └─────────┘     └─────────┘     └──────────┘
         │              │              │                 │
         ▼              ▼              ▼                 ▼
    Download      Preview       Execute       Tear down
    providers     changes       changes       everything
```

1. **`terraform init`** — Downloads providers and modules, initializes backend
2. **`terraform plan`** — Shows what will be created/changed/destroyed
3. **`terraform apply`** — Executes the plan (with confirmation)
4. **`terraform destroy`** — Destroys all managed resources

### Providers

A **provider** is a plugin that translates Terraform's generic resource definitions into API calls for a specific platform.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### The terraform Block and required_version

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

`required_version` enforces a minimum Terraform version. The `~>` operator means "allow patch updates but not minor version bumps" (e.g., `~> 5.0` allows 5.0.x but not 5.1).





[← Previous](02-section-1-what-is-infrastructure.md) | [↑ Index](index.md) | [Next →](04-section-3-installation.md)
