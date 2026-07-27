## 🔍 Section 9: Modules

### Module Structure

A module is a directory with `.tf` files. Convention:

```
modules/
└── vpc/
    ├── main.tf          # Resources
    ├── variables.tf     # Input variables
    └── outputs.tf       # Output values
```

### Using a Module from the Registry

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = var.environment
  }
}
```

### Writing a Local Module

**modules/vpc/main.tf**:

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.env}-public-subnet-${count.index + 1}"
    Environment = var.env
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.env}-private-subnet-${count.index + 1}"
    Environment = var.env
    Type        = "private"
  }
}
```

**modules/vpc/variables.tf**:

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "env" {
  description = "Environment name"
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
```

### Calling a Module from Root

```hcl
# root main.tf
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = "10.0.0.0/16"
  env                  = var.environment
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]
}
```

### Module Sources

```hcl
# Local filesystem
module "local" {
  source = "./modules/networking"
}

# Terraform Registry
module "registry" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}

# GitHub
module "github" {
  source = "github.com/org/repo//path/to/module?ref=v1.0.0"
}

# Generic Git
module "git" {
  source = "git::https://example.com/vpc-module.git?ref=main"
}

# S3 (compressed archive)
module "s3" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/my-bucket/modules/vpc.zip"
}

# HTTP (compressed archive)
module "http" {
  source = "https://example.com/modules/vpc.zip"
}

# Terraform Cloud private registry
module "private" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "1.0.0"
}
```

### Version Constraints

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 4.0.0, < 6.0.0"

  # or just:
  version = "~> 5.0"
  # ~> 5.0 → >= 5.0, < 5.1
  # ~> 5.4 → >= 5.4, < 6.0
}
```

---



---

[← Previous](09-section-8-remote-backends.md) | [↑ Index](index.md) | [Next →](11-section-10-workspaces.md)
