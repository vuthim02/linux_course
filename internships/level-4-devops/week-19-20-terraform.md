# Internship — Level 4, Week 19-20
## Infrastructure as Code with Terraform

### Real-World Scenario

The company is migrating from on-premises to AWS. Your team needs to provision a production VPC environment with public/private subnets, bastion host, RDS database, and S3 storage. Everything must be version-controlled, repeatable, and documented. You'll build it with Terraform.

### Requirements

#### Module Structure

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── storage/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── config/
    └── remote-state/
```

#### Module: networking

Create VPC with:
- CIDR: `10.0.0.0/16` (variable)
- 2 public subnets (one per AZ): `10.0.1.0/24`, `10.0.2.0/24`
- 2 private subnets (one per AZ): `10.0.10.0/24`, `10.0.20.0/24`
- 2 database subnets (one per AZ): `10.0.100.0/24`, `10.0.200.0/24`
- Internet Gateway for public subnets
- NAT Gateway (single, or one per AZ for prod)
- Route tables: public (default route → IGW), private (default route → NAT)
- VPC Flow Logs to CloudWatch
- Tags: `Environment`, `ManagedBy=Terraform`, `Project`

#### Module: compute

- **Bastion host:** t3.nano in public subnet, security group (SSH only from your IP), key pair
- **Application servers:** Auto Scaling Group in private subnets, t3.medium, launch template with userdata (cloud-init script installs Docker + pulls app image), ALB in public subnets
- Security groups with least privilege:
  - ALB: 80/443 from 0.0.0.0/0
  - Bastion: 22 from office IP
  - App: 80 from ALB security group

#### Module: database

- RDS PostgreSQL 15, db.t3.medium, Multi-AZ for prod
- Subnet group using database subnets
- Security group: 5432 from app security group
- Automated backups, 7-day retention, preferred backup window
- Parameter group with optimized settings (work_mem, shared_buffers)
- Storage: 100GB gp3, 3000 IOPS

#### Module: storage

- S3 bucket for application assets
- Versioning enabled
- Lifecycle: transition to Glacier after 90 days, delete after 365 days
- SSE-S3 encryption
- Block public access

#### Remote State

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

#### Variables per Environment

**dev/terraform.tfvars:**
```hcl
environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.micro"
db_instance_class  = "db.t3.micro"
multi_az           = false
```

**prod/terraform.tfvars:**
```hcl
environment        = "prod"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.medium"
db_instance_class  = "db.t3.medium"
multi_az           = true
```

#### Outputs

```hcl
output "vpc_id" { value = module.networking.vpc_id }
output "alb_dns_name" { value = module.compute.alb_dns_name }
output "db_endpoint" { value = module.database.endpoint }
output "bastion_public_ip" { value = module.compute.bastion_ip }
output "s3_bucket_name" { value = module.storage.bucket_name }
```

### Validation

```bash
# Initialize
cd terraform/environments/dev
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Verify
terraform output
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)

# Destroy (when done)
terraform destroy
```

### Deliverables

- `~/internship/terraform/` — complete directory structure with all modules
- `~/internship/terraform/environments/dev/terraform.tfvars`
- `~/internship/terraform/environments/prod/terraform.tfvars`
- `~/internship/terraform/README.md` — architecture diagram, how to use, prerequisites
- `~/internship/terraform/test-output.txt` — `terraform plan` output from dev

### Hints

- Use `terraform fmt -recursive` to format all files
- Use `terraform validate` in each environment directory
- Use `terraform graph | dot -Tpng > graph.png` for dependency visualization
- For the S3 state bucket bootstrap: create it manually first or use `terraform init -backend-config`
- Use `count` and `element()` for multi-AZ resources: `subnet_ids = [for s in module.networking.private_subnets : s.id]`
- `cidrsubnet("10.0.0.0/16", 8, 1)` for calculating subnet CIDRs
