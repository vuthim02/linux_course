## 🔍 Section 12: Terraform Cloud / Enterprise

### Terraform Cloud Overview

Terraform Cloud (TFC) adds collaboration features on top of open-source Terraform:

| Feature | Open Source | TFC Free | TFC Team | TFC Enterprise |
|---------|-------------|----------|----------|----------------|
| Local runs | ✅ | ✅ | ✅ | ✅ |
| Remote runs | ❌ | ✅ | ✅ | ✅ |
| State storage | Manual S3 | ✅ Managed | ✅ Managed | ✅ Managed |
| State locking | Manual DDB | ✅ Built-in | ✅ Built-in | ✅ Built-in |
| VCS integration | ❌ | ✅ | ✅ | ✅ |
| Sentinel policies | ❌ | ❌ | ✅ | ✅ |
| Private module registry | ❌ | ❌ | ✅ | ✅ |
| Run tasks | ❌ | ❌ | ✅ | ✅ |
| Audit logging | ❌ | ❌ | ❌ | ✅ |
| SAML/SSO | ❌ | ❌ | ❌ | ✅ |

### Remote Runs Configuration

```hcl
# terraform.tf — use TFC as backend
terraform {
  cloud {
    organization = "my-company"

    workspaces {
      name = "infra-production"
    }
  }
}
```

Or use tags for dynamic workspaces:

```hcl
terraform {
  cloud {
    organization = "my-company"

    workspaces {
      tags = ["env:prod", "app:web"]
    }
  }
}
```

### VCS Integration

Terraform Cloud integrates with GitHub, GitLab, Bitbucket:

```
Git Push → Webhook → TFC Triggers Run → terraform plan → Comment on PR
                                                   ↓
                                             Manual Apply (or auto-apply)
```

Workflow:

1. Developer opens a PR modifying `main.tf`
2. Terraform Cloud automatically runs `terraform plan`
3. The plan is posted as a PR comment
4. A reviewer approves and merges
5. Terraform Cloud runs `terraform apply`

### Sentinel Policies

Sentinel is a policy-as-code framework. Policies run before the apply:

```hcl
# policies/enforce-tags.sentinel
import "tfplan/v2" as tfplan

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.mode is "managed" implies
      all rc.change.after.tags else {} as key, _ {
        key in ["Environment", "Owner", "CostCenter"]
      }
  }
}
```

### Run Tasks

TFC can call external services during runs:

```
TFC Run → HTTP Call → External Service → Result → TFC Continues or Fails
```

Common run tasks:
- **tfsec** / **checkov** — Security scanning
- **infracost** — Cost estimation
- **aqua** — Container security
- Custom compliance checks

### Private Module Registry

Store reusable modules internally:

```bash
# Publish a module
terraform login  # Authenticate with TFC
git tag v1.0.0
git push --tags

# Then TFC auto-imports it to the private registry
```

```hcl
# Use from private registry
module "vpc" {
  source  = "app.terraform.io/my-company/vpc/aws"
  version = "1.0.0"
}
```

---



---

[← Previous](12-section-11-provisioners.md) | [↑ Index](index.md) | [Next →](14-section-13-testing-and-ci.md)
