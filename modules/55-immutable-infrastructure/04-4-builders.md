## 4. Builders

### Amazon EBS Builder

```hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-0c7217cdde317cfec" # Ubuntu 22.04
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "webapp" {
  region        = var.region
  source_ami    = var.source_ami
  instance_type = "t3.medium"

  # SSH configuration
  ssh_username   = "ubuntu"
  ssh_interface  = "public_ip"
  ssh_timeout    = "10m"
  associate_public_ip_address = true

  # Networking
  subnet_filter {
    filters = {
      "tag:Environment" : "build"
    }
    most_free = true
    random    = false
  }

  # Security group
  temporary_security_group_source_cidr = "0.0.0.0/0"
  temporary_security_group_description = "Packer build SG"

  # IAM
  iam_instance_profile = "packer-build-role"

  # Metadata
  ami_name = "webapp-${local.timestamp}"
  ami_description = "Web application golden image, built ${local.timestamp}"

  ami_regions = [
    "us-east-1",
    "us-west-2",
    "eu-west-1"
  ]

  ami_groups = [] # private AMI

  tags = {
    Name        = "webapp-${local.timestamp}"
    OS          = "Ubuntu 22.04"
    BuildTime   = local.timestamp
    Environment = "golden"
    ManagedBy   = "Packer"
  }

  # Encrypt EBS volumes
  encrypt_boot = true
  kms_key_id   = "alias/packer-ami-key"

  # Volume configuration
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
}
```

**Key options:**
- `source_ami` — base AMI ID
- `region` — AWS region
- `instance_type` — EC2 instance type
- `ssh_username` — SSH user for the base AMI
- `ssh_interface` — `public_ip`, `private_ip`, `public_dns`, `private_dns`, `session_manager`
- `ami_name` — name of the resulting AMI
- `ami_regions` — copy to additional regions
- `tags` — tags for the AMI and snapshots
- `encrypt_boot` — encrypt root volume
- `launch_block_device_mappings` — fine-tune EBS volumes

### Google Compute Builder

```hcl
packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project_id" {
  type    = string
  default = "my-gcp-project"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "googlecompute" "webapp" {
  project_id         = var.project_id
  zone               = var.zone
  source_image       = "ubuntu-2204-lts"
  source_image_family = "ubuntu-2204-lts"
  image_name         = "webapp-${local.timestamp}"
  image_description  = "Web application golden image"
  image_family       = "webapp"

  machine_type = "e2-medium"
  disk_size    = 30
  disk_type    = "pd-ssd"

  ssh_username = "ubuntu"

  # Service account for the builder
  account_file = "/path/to/service-account.json"

  # Service account for the instance
  instance_service_account = "packer-build@my-gcp-project.iam.gserviceaccount.com"

  # Labels
  image_labels = {
    name        = "webapp"
    timestamp   = local.timestamp
    managed-by  = "packer"
  }

  # Default to public images
  # source_image_project_id = ["ubuntu-os-cloud"]
}

build {
  sources = ["source.googlecompute.webapp"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

**Key options:**
- `project_id` — GCP project
- `zone` — compute zone
- `source_image` / `source_image_family` — base image
- `image_name` — name of resulting image
- `image_family` — family for grouping images
- `machine_type` — GCE machine type
- `account_file` — path to service account JSON key
- `disk_size` — boot disk size in GB

### Azure Builder

```hcl
packer {
  required_plugins {
    azure = {
      version = ">= 2.1.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "client_id" {
  type    = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "subscription_id" {
  type    = string
}

variable "tenant_id" {
  type    = string
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "azure-arm" "webapp" {
  # Azure auth
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Source image
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"

  # Destination
  managed_image_name                = "webapp-${local.timestamp}"
  managed_image_resource_group_name = "packer-images-rg"

  # Location
  location = "East US"
  vm_size  = "Standard_DS2_v2"

  # SSH
  ssh_username = "ubuntu"

  # Azure tags
  azure_tags = {
    name       = "webapp"
    timestamp  = local.timestamp
    managed-by = "packer"
  }
}

build {
  sources = ["source.azure-arm.webapp"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

**Key options:**
- `client_id` / `client_secret` — Azure AD service principal
- `subscription_id` — Azure subscription
- `tenant_id` — Azure AD tenant
- `managed_image_resource_group_name` — RG for the image
- `os_type` — `Linux` or `Windows`
- `image_publisher` / `image_offer` / `image_sku` — marketplace image
- `vm_size` — Azure VM size

### QEMU Builder (Local/ISO)

```hcl
packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:a4acfda10b18d6c28e462e8e4e11f88b6a39a7d1c3b9c6e8f4d7e5c6a3b2c1d0"
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "qemu" "ubuntu" {
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  output_directory  = "output-qemu-${local.timestamp}"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = "10G"
  format            = "qcow2"
  headless          = true
  accelerator       = "kvm"
  http_directory    = "http"
  ssh_username      = "ubuntu"
  ssh_password      = "packer"
  ssh_timeout       = "30m"
  vm_name           = "ubuntu-22.04"
  memory            = 2048
  cpu_cores         = 2

  # Use a preseed/autoinstall for unattended installation
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot",
    "<enter>"
  ]
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openssh-server nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

**Key options:**
- `iso_url` / `iso_checksum` — source ISO
- `accelerator` — `kvm`, `tcg`, `haxm`, `none`
- `format` — `qcow2`, `raw`, `vmdk`, `vdi`
- `boot_command` — keystrokes for automated OS install
- `http_directory` — serve files for cloud-init/preseed

---



---

[← Previous](03-3-packer-installation-and-hcl2.md) | [↑ Index](index.md) | [Next →](05-5-provisioners.md)
