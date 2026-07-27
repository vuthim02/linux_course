## 🔍 Section 1: What Is Infrastructure as Code?

### The Old Way vs IaC

Before IaC, provisioning infrastructure looked like this:

```bash
# Manual: SSH into a server, run commands by hand
ssh admin@server
sudo apt update && sudo apt install -y nginx
sudo systemctl enable nginx
# ... pray you don't forget a step
```

Or at best, a shell script:

```bash
#!/bin/bash
# script.sh — fragile, not idempotent, no state tracking
aws ec2 run-instances --image-id ami-1234 --count 1 --instance-type t2.micro
aws s3 mb s3://my-bucket
```

Problems:
- **Not idempotent**: Running twice creates duplicate resources
- **No drift detection**: If someone manually changes the bucket policy, you never know
- **No dependency graph**: Scripts run top-to-bottom; you manage ordering yourself
- **State is tribal knowledge**: Who created what? Why? When?

### Declarative vs Imperative

| Approach | What You Write | How It Works | Example |
|----------|---------------|--------------|---------|
| **Imperative** | Step-by-step instructions | "Do A, then B, then C" | Bash, Ansible (playbooks), CloudFormation (sort of) |
| **Declarative** | Desired end state | "I want this; make it so" | Terraform, Pulumi, AWS CDK (sort of) |

Terraform is **declarative**: you write *what you want*, Terraform figures out *how to get there*.

```hcl
# Declarative: "I want an S3 bucket with this name"
resource "aws_s3_bucket" "data" {
  bucket = "my-company-data-lake-2026"
  tags = {
    Environment = "production"
  }
}
```

### Idempotency

An idempotent operation produces the same result no matter how many times you run it. Terraform is (mostly) idempotent:

```
$ terraform apply          # Creates the bucket
$ terraform apply          # No changes — bucket already exists
$ terraform apply          # Still no changes — idempotent
```

If someone deletes the bucket manually, `terraform apply` recreates it (drift correction).

### Desired State and Drift Detection

Terraform maintains a **state file** (`terraform.tfstate`) that maps your config to real infrastructure. When you run `terraform plan`, Terraform:

1. Reads the **current config** (your `.tf` files) → this is your **desired state**
2. Reads the **state file** → this is what Terraform *thinks* exists
3. Refreshes state against the **real provider API** → this is **actual state** (drift detection)
4. Computes the **diff** → this is the plan

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Desired      │     │   State      │     │  Real World  │
│  (.tf files)  │────▶│  (.tfstate)  │◀────│  (AWS/GCP)   │
└──────────────┘     └──────────────┘     └──────────────┘
                          │                      │
                          ▼                      ▼
                     ┌──────────────────────────┐
                     │    terraform plan         │
                     │  "3 to add, 1 to change" │
                     └──────────────────────────┘
```

### Benefits Over Manual/Scripted Provisioning

| Benefit | Why It Matters |
|---------|---------------|
| **Version control** | Your infrastructure is code — PRs, reviews, tags |
| **Reproducibility** | Same config → same infra, every time |
| **Self-documenting** | The `.tf` files *are* the documentation |
| **Collaboration** | Teams share state via remote backends |
| **Rollback** | `git revert` + `terraform apply` = infrastructure rollback |
| **Audit trail** | `git log` shows who changed what and why |
| **Cost tracking** | Tag resources, see what you're spending |

---



---

[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-terraform-overview.md)
