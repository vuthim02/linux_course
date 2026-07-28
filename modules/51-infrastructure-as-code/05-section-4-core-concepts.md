## 🔍 Section 4: Core Concepts

### Resources

A **resource** is a piece of infrastructure (a VM, a DNS record, a database, etc.):

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
}
```

The syntax is `resource "<type>" "<local_name>" { ... }`. The type (`aws_instance`) maps to the provider; the local name (`web`) is used to reference this resource elsewhere.

### Data Sources

A **data source** reads information from the provider without creating anything:

```hcl
# Look up the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Use it in a resource
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

Data sources reference with `data.<type>.<name>.attribute`.

### Providers

Providers handle the API communication. They can be configured with authentication, region, and other settings:

```hcl
provider "aws" {
  region = var.aws_region
  # Credentials come from env vars, ~/.aws/credentials, or IAM role
}
```

Multiple provider configurations (e.g., for different regions):

```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "west"
}

resource "aws_instance" "web_east" {
  provider = aws.east
  ami      = "ami-0abc123"
}

resource "aws_instance" "web_west" {
  provider = aws.west
  ami      = "ami-0def456"
}
```

### State

State is the bridge between config and reality:

```
/tree
├── main.tf          # Configuration (desired state)
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── terraform.tfstate  # Real-world mapping (AUTO-GENERATED, NEVER EDIT BY HAND)
```

### Variables

Input variables make configs reusable:

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

### Outputs

Outputs expose information after apply:

```hcl
# outputs.tf
output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "The public IP of the web server"
}
```

### Locals

Locals are internal constants. They don't accept input from the caller:

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### Modules

Modules are reusable groups of resources. Every Terraform config is a module (the **root module**). Child modules are called from within:

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  env      = var.environment
}
```





[← Previous](04-section-3-installation.md) | [↑ Index](index.md) | [Next →](06-section-5-hcl-syntax-deep.md)
