## 3. Packer Installation and HCL2

### Installation

```bash
# Ubuntu/Debian
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Verify
packer version
# Packer v1.12.0

# Enable autocomplete
packer -autocomplete-install
```

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/packer

# RHEL/CentOS
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install packer
```

```bash
# From binary
wget https://releases.hashicorp.com/packer/1.12.0/packer_1.12.0_linux_amd64.zip
unzip packer_1.12.0_linux_amd64.zip
sudo mv packer /usr/local/bin/
```

### HCL2 Template Structure

Packer templates use HashiCorp Configuration Language (HCL2) with `.pkr.hcl` extension.

**Top-level blocks:**
- `packer { ... }` — required, contains `required_plugins`
- `source "type" "name" { ... }` — defines a builder source
- `build { ... }` — connects sources with provisioners and post-processors
- `variable "name" { ... }` — input variables
- `locals { ... }` — local values
- `data "type" "name" { ... }` — data sources (Packer 1.12+)

### Minimal Template

```hcl
# minimal.pkr.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "nginx" {
  region        = "us-east-1"
  source_ami    = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  tags = {
    Name    = "nginx-base-{{timestamp}}"
    OS      = "Ubuntu 22.04"
    BuiltBy = "Packer"
  }
}

build {
  name = "nginx-ami"
  sources = ["source.amazon-ebs.nginx"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

Run with:
```bash
packer init mininal.pkr.hcl
packer fmt mininal.pkr.hcl
packer validate mininal.pkr.hcl
packer build mininal.pkr.hcl
```

### Variables and Locals

```hcl
# variables.pkr.hcl
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "source_ami" {
  type        = string
  description = "Ubuntu 22.04 LTS AMI ID"
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  type    = map(string)
  default = {
    Project   = "linux-course"
    ManagedBy = "Packer"
  }
}

locals {
  timestamp     = formatdate("YYYY-MM-DD-hhmm", timestamp())
  ami_name      = "nginx-${var.environment}-${local.timestamp}"
  build_version = "${var.environment}-${local.timestamp}"
}

# Usage in source or build blocks:
# source_ami    = var.source_ami
# instance_type = var.instance_type
# name          = local.ami_name
```

Pass variables at runtime:
```bash
packer build -var "region=eu-west-1" -var "environment=prod" template.pkr.hcl
packer build -var-file=prod.pkrvars.hcl template.pkr.hcl
```

```hcl
# prod.pkrvars.hcl
region        = "eu-west-1"
instance_type = "t3.large"
environment   = "prod"
source_ami    = "ami-0abcdef1234567890"
```





[← Previous](02-2-packer-overview.md) | [↑ Index](index.md) | [Next →](04-4-builders.md)
