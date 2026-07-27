## 🔍 Section 16: Hands-On Practices

### Practice 1: Install Terraform and Configure Shell Autocomplete

```bash
# Follow the installation steps from Section 3
sudo apt update && sudo apt install -y terraform
terraform -install-autocomplete
exec $SHELL

# Verify
terraform --version
terraform -help
```

### Practice 2: Write a main.tf to Create an AWS S3 Bucket

Create a directory and write your first config:

```bash
mkdir ~/terraform-lab
cd ~/terraform-lab
```

```hcl
# main.tf
terraform {
  required_version = ">= 1.5.0"

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

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-terraform-lab-bucket-$(random_string.suffix.result)"

  tags = {
    Name        = "terraform-lab-bucket"
    Environment = "learning"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

```bash
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve
```

### Practice 3: Use Variables and Outputs

```hcl
# variables.tf
variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "my-lab-bucket"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = false
}
```

```hcl
# outputs.tf
output "bucket_name" {
  value       = aws_s3_bucket.my_bucket.bucket
  description = "The name of the created S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.my_bucket.arn
  description = "The ARN of the created S3 bucket"
}

output "bucket_domain" {
  value       = aws_s3_bucket.my_bucket.bucket_domain_name
  description = "The domain name of the bucket"
}
```

```hcl
# main.tf (updated)
resource "aws_s3_bucket" "my_bucket" {
  bucket = "${var.bucket_name_prefix}-${random_string.suffix.result}"
}

resource "aws_s3_bucket_versioning" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

```bash
# Override defaults
terraform apply -var="environment=staging" -var="enable_versioning=true"
terraform output
```

### Practice 4: Create a Second Resource with Dependencies

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  depends_on             = [aws_s3_bucket.my_bucket]

  tags = {
    Name = "web-server-${var.environment}"
  }
}

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

```bash
terraform apply
# Observe: Terraform creates bucket FIRST, then instance
terraform destroy
```

### Practice 5: Use count and for_each

```hcl
# count example — multiple subnets
variable "subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count      = length(var.subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidrs[count.index]

  tags = {
    Name = "public-${count.index}"
  }
}

# for_each example — multiple instances with different configs
variable "instances" {
  type = map(object({
    ami           = string
    instance_type = string
  }))
  default = {
    web = {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t3.micro"
    }
    app = {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t3.small"
    }
  }
}

resource "aws_instance" "servers" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type

  tags = {
    Name = "server-${each.key}"
  }
}
```

```bash
terraform apply
terraform state list
# aws_subnet.public[0], aws_subnet.public[1], aws_subnet.public[2]
# aws_instance.servers["app"], aws_instance.servers["web"]
```

### Practice 6: Store State Remotely in S3 + DynamoDB

First, create the backend resources:

```hcl
# bootstrap-s3-backend.tf
# Run this ONCE to create the backend, then migrate
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-state-$(random_string.suffix.result)"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_lock.name
}
```

After bootstrap, add the backend config:

```hcl
# backend.tf (after bootstrap, run terraform init -migrate)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-<random-suffix>"  # From bootstrap output
    key            = "terraform-lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

```bash
# Migrate from local to remote state
terraform init -migrate

# Now state is stored in S3 and locked with DynamoDB
terraform apply
```

### Practice 7: Implement State Locking and Observe It

```bash
# Terminal 1: Start an apply
terraform apply

# Terminal 2: While Terminal 1 is running, try another apply
terraform apply
# → Error: Error acquiring the state lock

# View lock info
terraform force-unlock -force <LOCK_ID>
# (Only use if you're sure no operation is actually running)
```

### Practice 8: Create a Reusable VPC Module

```bash
mkdir -p modules/vpc
```

**modules/vpc/main.tf**:

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
  })
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

**modules/vpc/variables.tf**:

```hcl
variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

**modules/vpc/outputs.tf**:

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  value = aws_eip.nat[*].public_ip
}
```

### Practice 9: Call the Module from Root Config

```hcl
# root main.tf
module "vpc" {
  source = "./modules/vpc"

  name                 = "learning"
  cidr_block           = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway   = true

  tags = {
    Environment = "learning"
    Course      = "Linux-Admin-51"
  }
}

# Use module outputs
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = {
    Name = "web-in-learning-vpc"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

```bash
terraform init
terraform plan
terraform apply
terraform output
```

### Practice 10: Use Workspaces to Separate Environments

```bash
# Current workspace: default
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch and apply different configs
terraform workspace select dev
terraform apply -var="environment=dev" -auto-approve

terraform workspace select staging
terraform apply -var="environment=staging" -auto-approve

terraform workspace select prod
terraform apply -var="environment=prod" -auto-approve

# List all resources in each workspace
terraform workspace select dev
terraform state list

terraform workspace select prod
terraform state list
```

### Practice 11: Use Data Sources to Look Up Existing Infrastructure

```hcl
# Look up existing VPC
data "aws_vpc" "existing" {
  tags = {
    Name = "my-existing-vpc"
  }
}

# Look up existing subnets
data "aws_subnets" "existing_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# Get details of a specific subnet
data "aws_subnet" "selected" {
  id = data.aws_subnets.existing_public.ids[0]
}

# Use the data
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.selected.id
}
```

### Practice 12: Write tflint and checkov Configuration

**.tflint.hcl**:

```hcl
plugin "aws" {
  enabled = true
  version = "0.24.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_instance_default_standard_volume" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Environment", "Name"]
}

rule "aws_s3_bucket_name" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}
```

```bash
# Run tflint
tflint --init
tflint --recursive

# Run checkov
pip install checkov
checkov -d .

# Run terrascan
terrascan scan -d .
```

### Practice 13: Use templatefile to Render a Userdata Script

**templates/cloud-init.yaml.tpl**:

```yaml
#cloud-config
package_update: true
package_upgrade: false

packages:
  - nginx
  - curl
  - htop

write_files:
  - path: /etc/nginx/sites-available/default
    content: |
      server {
        listen 80;
        server_name ${server_name};
        root /var/www/html;
        index index.html;
      }

runcmd:
  - echo "Deployed by Terraform on ${timestamp}" > /var/www/html/index.html
  - systemctl enable nginx
  - systemctl restart nginx
```

```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    server_name = var.server_name
    timestamp   = time_static.deploy.rfc3339
  })

  tags = {
    Name = "web-${var.server_name}"
  }
}

resource "time_static" "deploy" {}
```

### Practice 14: Implement a Provisioner (Last Resort)

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  # Better approach: userdata (see Practice 13)
  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "Deployed by Terraform" > /var/www/html/index.html
  EOF
}

# Provisioner as absolute last resort
resource "null_resource" "post_deploy" {
  depends_on = [aws_instance.web]

  provisioner "local-exec" {
    command = <<EOF
      echo "Instance launched: ${aws_instance.web.public_ip}" >> deploy.log
      curl -s http://${aws_instance.web.public_ip} | grep -q "Deployed by Terraform" && \
        echo "Health check passed" || \
        echo "Health check failed"
    EOF
  }

  triggers = {
    instance_id = aws_instance.web.id
  }
}
```

### Practice 15: Real-World Integration — Complete Multi-Tier Infrastructure

```hcl
# main.tf — Complete multi-tier infrastructure
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "multi-tier/${terraform.workspace}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Locals ──────────────────────────────────────
locals {
  env = terraform.workspace == "default" ? "dev" : terraform.workspace

  # Per-environment sizing
  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "m5.large"
  }

  instance_count = {
    dev     = 1
    staging = 2
    prod    = 3
  }

  db_instance_class = {
    dev     = "db.t3.micro"
    staging = "db.t3.small"
    prod    = "db.r5.large"
  }

  common_tags = {
    Project     = "MultiTierApp"
    Environment = local.env
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}

# ── VPC Module ──────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  name                 = "multitier-${local.env}"
  cidr_block           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = local.env == "prod" ? true : false
  tags                 = local.common_tags
}

# ── Security Groups ─────────────────────────────
resource "aws_security_group" "web" {
  name        = "web-${local.env}"
  description = "Web tier security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "web-sg-${local.env}" })
}

resource "aws_security_group" "app" {
  name        = "app-${local.env}"
  description = "App tier security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "App traffic from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "app-sg-${local.env}" })
}

resource "aws_security_group" "db" {
  name        = "db-${local.env}"
  description = "Database security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Database from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(local.common_tags, { Name = "db-sg-${local.env}" })
}

# ── Web Tier (Auto Scaling Group + ALB) ─────────
resource "aws_lb" "web" {
  name               = "web-alb-${local.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = module.vpc.public_subnet_ids

  tags = merge(local.common_tags, { Name = "web-alb-${local.env}" })
}

resource "aws_lb_target_group" "web" {
  name     = "web-tg-${local.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, { Name = "web-tg-${local.env}" })
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-${local.env}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = lookup(local.instance_type, local.env, "t3.micro")
  user_data     = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    server_name = "web-${local.env}"
    timestamp   = time_static.deploy.rfc3339
  }))

  vpc_security_group_ids = [aws_security_group.web.id]

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "web-${local.env}" })
  }
}

resource "aws_autoscaling_group" "web" {
  name               = "web-asg-${local.env}"
  vpc_zone_identifier = module.vpc.public_subnet_ids
  target_group_arns  = [aws_lb_target_group.web.arn]
  health_check_type  = "ELB"
  min_size           = 1
  max_size           = lookup(local.instance_count, local.env, 2) * 2
  desired_capacity   = lookup(local.instance_count, local.env, 1)

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-${local.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = local.env
    propagate_at_launch = true
  }
}

# ── Database Tier ───────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "db-${local.env}"
  subnet_ids = module.vpc.private_subnet_ids

  tags = merge(local.common_tags, { Name = "db-subnet-group-${local.env}" })
}

resource "aws_db_instance" "main" {
  identifier     = "appdb-${local.env}"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = lookup(local.db_instance_class, local.env, "db.t3.micro")

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "appdb"
  username = "admin"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = local.env == "prod" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = local.env != "prod"
  final_snapshot_identifier = local.env == "prod" ? "appdb-${local.env}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  tags = merge(local.common_tags, { Name = "appdb-${local.env}" })
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

# ── App Tier (private instances) ────────────────
resource "aws_instance" "app" {
  count         = lookup(local.instance_count, local.env, 1)
  ami           = data.aws_ami.ubuntu.id
  instance_type = lookup(local.instance_type, local.env, "t3.micro")
  subnet_id     = module.vpc.private_subnet_ids[count.index % length(module.vpc.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/templates/app-userdata.sh.tpl", {
    db_host     = aws_db_instance.main.address
    db_name     = aws_db_instance.main.db_name
    db_user     = aws_db_instance.main.username
    db_password = random_password.db_password.result
    env         = local.env
  })

  tags = merge(local.common_tags, {
    Name = "app-${local.env}-${count.index + 1}"
    Tier = "app"
  })
}

# ── Data Sources ────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── Time (for template rendering) ───────────────
resource "time_static" "deploy" {}

# ── Outputs ─────────────────────────────────────
output "load_balancer_dns" {
  value       = aws_lb.web.dns_name
  description = "Web ALB DNS name"
}

output "database_endpoint" {
  value       = aws_db_instance.main.endpoint
  sensitive   = true
  description = "RDS endpoint"
}

output "app_instance_ips" {
  value       = aws_instance.app[*].private_ip
  description = "App instance private IPs"
}

output "environment" {
  value       = local.env
  description = "Current environment"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}
```

```bash
# Deploy to each environment
terraform workspace new dev
terraform apply -var-file=environments/dev.tfvars -auto-approve

terraform workspace new staging
terraform apply -var-file=environments/staging.tfvars -auto-approve

terraform workspace new prod
terraform apply -var-file=environments/prod.tfvars -auto-approve
```

---



---

[← Previous](16-section-15-deep-understanding.md) | [↑ Index](index.md) | [Next →](18-command-reference.md)
