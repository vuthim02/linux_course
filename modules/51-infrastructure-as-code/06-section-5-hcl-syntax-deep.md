## 🔍 Section 5: HCL Syntax Deep Dive

### Block Types

HCL has several block types:

```hcl
# Terraform settings
terraform { ... }

# Provider configuration
provider "aws" { ... }

# Resource declaration
resource "aws_s3_bucket" "data" { ... }

# Data source
data "aws_ami" "ubuntu" { ... }

# Variable declaration
variable "region" { ... }

# Output value
output "vpc_id" { ... }

# Local value
locals { ... }

# Module call
module "networking" { ... }
```

### Arguments and Attributes

Arguments set configuration; attributes export values:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123"        # Argument (you set this)
  instance_type = "t3.micro"       # Argument

  # Reference attribute from another resource
  subnet_id = aws_subnet.main.id   # Attribute reference
}
```

### Expressions

```hcl
# String interpolation
user_data = templatefile("${path.module}/userdata.sh", {
  hostname = var.hostname
})

# Arithmetic
volume_size = var.base_size * 2 + 10

# Conditional
instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"

# Splat expressions
private_ips = aws_instance.web[*].private_ip
```

### Built-in Functions

```hcl
# lookup — safe map access
bucket_name = lookup(var.bucket_names, var.environment, "default-bucket")

# concat — merge lists
all_subnets = concat(var.public_subnets, var.private_subnets)

# toset — convert list to set (for for_each)
subnet_set = toset(var.subnet_names)

# file — read file contents
public_key = file("~/.ssh/id_rsa.pub")

# templatefile — render a template
rendered = templatefile("${path.module}/config.tpl", {
  server_name = var.server_name
})
```

### Conditionals

```hcl
# Ternary
is_prod = var.environment == "production" ? true : false

# count with conditional
resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0
  # ...
}

# for_each with conditional
resource "aws_security_group_rule" "allow_http" {
  for_each = var.enable_http ? toset(["0.0.0.0/0"]) : toset([])
  # ...
}
```

### for_each and count

These metaparameters let you create multiple resources dynamically.

**count** — creates a numbered list:

```hcl
variable "subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

resource "aws_subnet" "public" {
  count      = length(var.subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidrs[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Access: aws_subnet.public[0], aws_subnet.public[1], ...
```

**for_each** — creates a map (keyed by unique identifier):

```hcl
variable "instances" {
  type = map(object({
    ami           = string
    instance_type = string
  }))
  default = {
    web  = { ami = "ami-abc", instance_type = "t3.micro" }
    app  = { ami = "ami-def", instance_type = "t3.small"  }
    db   = { ami = "ami-ghi", instance_type = "m5.large"  }
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

# Access: aws_instance.servers["web"], aws_instance.servers["app"], ...
```

Use **for_each** when you need stable, meaningful keys. Use **count** when you need a simple numbered list.





[← Previous](05-section-4-core-concepts.md) | [↑ Index](index.md) | [Next →](07-section-6-variables-and-outputs.md)
