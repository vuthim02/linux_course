# 🐧 Linux System Administrator — Complete Course
## Part 55 of ∞: Immutable Infrastructure — Packer and Image Baking

> *"If you SSH into production, you've already lost." — Immutable Infrastructure Mantra*

---

# Table of Contents
1. Immutable Infrastructure Philosophy
2. Packer Overview
3. Packer Installation and HCL2
4. Builders
5. Provisioners
6. Cloud-Init
7. Image Pipeline
8. Security Hardening in Images
9. Deployment Strategies for Immutable
10. Userdata and First Boot
11. Troubleshooting Immutable
12. Hands-On Practices (1–15)
13. Deep Understanding
14. Command Reference
15. Self-Test

---

## 1. Immutable Infrastructure Philosophy

### Mutable vs Immutable

In **mutable infrastructure** (pet model), you provision a server once and then SSH into it to apply updates, patch packages, modify configs, and fix issues. Over time, every server becomes a unique snowflake — nobody knows exactly what's installed, which configs were changed manually, or whether a reboot will break things.

| Aspect | Mutable (Pets) | Immutable (Cattle) |
|--------|---------------|-------------------|
| Updates | SSH in, apt upgrade, restart service | Build new image, replace instance |
| Config changes | Edit files by hand or config mgmt | Change template, rebuild image |
| State | Drift accumulates | Every instance is identical |
| Failure | Try to fix in place | Terminate and replace |
| SSH | Required for daily ops | Blocked / not needed |
| Rollback | Difficult (unwind changes) | Trivial (deploy old image) |

### Golden Images

A **golden image** is a pre-baked machine image containing the OS, security patches, middleware, application dependencies, and hardened configuration. Every instance launched from this image is bit-for-bit identical. There is zero configuration drift.

**Bake vs Fry:**
- **Bake**: Everything is baked into the image at build time. No post-boot configuration needed (except perhaps minimal userdata for environment-specific values).
- **Fry**: Minimal base image, heavy reliance on post-boot userdata scripts or configuration management at first boot.

Immutable infrastructure strongly prefers **baking**.

### No SSH into Production

The rule is simple: you do not SSH into production servers. There is no SSH daemon listening (or it's firewalled), no SSH keys are deployed, and no user accounts exist. If you need to debug, you launch a separate instance from the same image in a sandbox, or use dedicated debugging tools (SSM Session Manager, serial console, log aggregation).

### Replacing Instances Instead of Patching

When a security patch needs to be applied:
1. Build a new image with the patch baked in
2. Deploy new instances from the new image
3. Terminate old instances

This is safer than patching in place because:
- The build process is automated and repeatable
- The new image is tested before deployment
- Rollback means deploying the previous image version
- No partial failures or half-patched servers

---

## 2. Packer Overview

[Packer](https://www.packer.io) by HashiCorp is the industry standard tool for creating machine images. It automates the entire image baking process: start a source instance, provision it, create an image snapshot, and clean up.

### Key Components

**Builders** — create a machine for the target platform:
- `amazon-ebs` — AWS EC2 with EBS-backed AMIs
- `googlecompute` — GCE images in Google Cloud
- `azure-arm` — Azure Managed Images
- `docker` — Docker containers (commit or export)
- `vmware-iso` — VMware VM templates
- `qemu` — QEMU/libvirt images (KVM)
- `virtualbox-iso` — VirtualBox images
- `hyperv-iso` — Hyper-V images
- `null` — No builder (for testing provisioners)

**Provisioners** — configure the machine during build:
- `shell` — run shell scripts or inline commands
- `ansible` — run Ansible playbooks
- `chef-client` — run Chef cookbooks
- `salt-masterless` — apply Salt states
- `file` — upload files to the image
- `powershell` — run PowerShell scripts (Windows)
- `puppet-masterless` — apply Puppet manifests
- `breakpoint` — pause for debugging
- `windows-shell` — Windows batch commands
- `converge` — Converge configuration

**Post-Processors** — process the artifact after build:
- `vagrant` — package as Vagrant box
- `manifest` — write build metadata to JSON
- `docker-tag` / `docker-push` — tag and push Docker images
- `artifice` — attach externally-created artifacts
- `amazon-import` — import RAW/VMDK to AMI
- `checksum` — generate checksum files
- `compress` — compress the artifact
- `shell-local` — run local scripts after build

### Architecture

```
         ┌─────────────────────────────┐
         │      packer build           │
         │    (HCL2 Template)          │
         └──────┬──────────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│Builder │ │Builder │ │Builder │
│ AWS    │ │ GCE    │ │ Docker │
└───┬────┘ └───┬────┘ └───┬────┘
    │          │          │
    ▼          ▼          ▼
 Provisioners run on each
 (shell, ansible, file, etc.)
    │          │          │
    ▼          ▼          ▼
 Image created (AMI, GCE
 image, Docker tag)
    │          │          │
    ▼          ▼          ▼
 Post-processors
 (manifest, vagrant, push)
```

---

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

---

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

## 5. Provisioners

### Shell Provisioner

```hcl
# Inline shell
provisioner "shell" {
  inline = [
    "sudo apt-get update -y",
    "sudo apt-get install -y nginx curl wget",
    "sudo systemctl enable nginx",
    "echo 'Hello from Packer' | sudo tee /var/www/html/index.html"
  ]
}

# Shell script from file
provisioner "shell" {
  script = "scripts/provision.sh"
}

# Multiple scripts executed in order
provisioner "shell" {
  scripts = [
    "scripts/install-nginx.sh",
    "scripts/configure-app.sh",
    "scripts/harden.sh",
    "scripts/cleanup.sh"
  ]
}

# With environment variables
provisioner "shell" {
  environment_vars = [
    "APP_ENV=production",
    "VERSION=1.0.0",
    "LOG_LEVEL=warn"
  ]
  script = "scripts/install.sh"
}

# Execute as non-root user
provisioner "shell" {
  execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E -u appuser {{ .Path }}"
  script = "scripts/user-setup.sh"
}

# With a timeout
provisioner "shell" {
  script   = "scripts/long-running.sh"
  timeout  = "30m"
  pause_before = "5s"
}

# Skip cleanup (leave build script on instance for debugging)
provisioner "shell" {
  script        = "scripts/debug.sh"
  skip_clean    = true
  start_retry_timeout = "5m"
}
```

### File Provisioner

```hcl
# Upload a directory
provisioner "file" {
  source      = "app/"
  destination = "/opt/myapp"
}

# Upload a single file
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/etc/nginx/nginx.conf"
}

# Upload with specific ownership
provisioner "file" {
  source      = "systemd/myapp.service"
  destination = "/etc/systemd/system/myapp.service"
}

# Upload a template file (Packer does not do templates natively,
# use something like envsubst in shell or Ansible)
provisioner "shell" {
  inline = [
    "sudo mkdir -p /opt/myapp",
    "sudo chown ubuntu:ubuntu /opt/myapp"
  ]
}

provisioner "file" {
  source      = "app/"
  destination = "/opt/myapp/"
}
```

### Ansible Provisioner

```hcl
# Local Ansible (runs from the Packer host)
provisioner "ansible" {
  playbook_file = "playbooks/site.yml"

  # Extra variables
  extra_arguments = [
    "--extra-vars", "environment=g_allen",
    "--extra-vars", "app_version=${var.app_version}",
    "-v"  # verbose mode
  ]

  # Ansible inventory groups
  groups = ["web", "app"]

  # Limit to specific hosts/groups
  # ansible_limit = "tag_Name_webapp:&tag_Environment_prod"
}

# Remote Ansible (runs on the target instance)
provisioner "ansible" {
  playbook_file       = "playbooks/site.yml"
  use_proxy           = false
  ansible_ssh_user    = "ubuntu"
  ansible_ssh_private_key_file = "~/.ssh/id_rsa"
}

# With custom inventory template
provisioner "ansible" {
  playbook_file     = "playbooks/site.yml"
  inventory_file_template = "build-{{timestamp}}"
  extra_arguments = [
    "--skip-tags", "development"
  ]
}
```

### Chef Client Provisioner

```hcl
provisioner "chef-client" {
  chef_environment = "production"
  client_key       = "{{ pkgdir }}/client-key.pem"
  node_name        = "packer-build-{{timestamp}}"
  server_url       = "https://chef.example.com/organizations/myorg"
  validation_client_name = "myorg-validator"
  validation_key   = "{{ pkgdir }}/validation-key.pem"

  run_list = [
    "recipe[nginx]",
    "recipe[hardening::cis]",
    "recipe[myapp::deploy]"
  ]

  # Skip if Chef is not installed
  skip_install = false
  install_command = "curl -L https://omnitruck.chef.io/install.sh | sudo bash"
}
```

### Salt Masterless Provisioner

```hcl
provisioner "salt-masterless" {
  local_state_tree = "salt/states/"
  local_pillar_roots = "salt/pillar/"
  minion_config = "salt/minion.conf"

  # Salt states to apply
  states = [
    "nginx",
    "hardening",
    "myapp"
  ]

  # Grain values
  grains_file = "salt/grains"

  # Bootstrap
  skip_bootstrap = false
  bootstrap_args = "-c /tmp"
}
```

### Cleanup Scripts

These are critical for production images. They remove sensitive data and reduce image size.

```bash
#!/bin/bash
# scripts/cleanup.sh
# Run this as the LAST provisioner

set -euo pipefail

echo "=== Cleanup: Removing SSH host keys ==="
sudo rm -f /etc/ssh/ssh_host_*
sudo rm -f ~/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys

echo "=== Cleanup: Removing cloud-init artifacts ==="
sudo rm -rf /var/lib/cloud/instances/*
sudo rm -f /var/log/cloud-init.log
sudo rm -f /var/log/cloud-init-output.log

echo "=== Cleanup: Removing packer SSH keys ==="
sudo rm -f /home/ubuntu/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys

echo "=== Cleanup: Removing temporary files ==="
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo "=== Cleanup: Cleaning package cache ==="
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "=== Cleanup: Removing logs ==="
sudo find /var/log -type f -name "*.log" -exec rm -f {} \;
sudo find /var/log -type f -name "*.gz" -exec rm -f {} \;
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s

echo "=== Cleanup: Zeroing disk (for better compression) ==="
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY

echo "=== Cleanup: Removing shell history ==="
rm -f ~/.bash_history
rm -f /root/.bash_history
unset HISTFILE

echo "=== Cleanup: Complete ==="
```

```hcl
# In the build block, cleanup runs last:
build {
  sources = ["source.amazon-ebs.webapp"]

  provisioner "shell" {
    script = "scripts/install-app.sh"
  }

  provisioner "shell" {
    script = "scripts/harden-cis.sh"
  }

  # NEVER run cleanup before this
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }
}
```

### Breakpoint Provisioner (Debugging)

```hcl
provisioner "breakpoint" {
  note = "Pausing before cleanup. SSH into the build instance to inspect."
}
```

---

## 6. Cloud-Init

Cloud-init is the industry standard for configuring cloud instances on first boot. It runs during early boot and can install packages, configure users, write files, run commands, and more.

### How Cloud-Init Works

1. **Boot**: Kernel starts, systemd runs `cloud-init.target`
2. **Datasource detection**: Cloud-init detects where it's running (EC2, GCE, Azure, NoCloud)
3. **Network**: `cloud-init-local` brings up network
4. **Init**: `cloud-init` processes user-data and metadata
5. **Modules**: Executes configured modules (in `/etc/cloud/cloud.cfg` order)
6. **Config**: `cloud-config` runs user-data scripts
7. **Final**: `cloud-final` runs final modules (runcmd, etc.)

### Cloud-Init Data Sources

- **NoCloud**: For local/libvirt testing — reads from ISO/CDROM with `user-data` and `meta-data` files
- **EC2**: AWS metadata endpoint (169.254.169.254)
- **GCE**: Google Compute metadata server
- **Azure**: Azure wireserver endpoint
- **OpenStack**: OpenStack metadata service
- **ConfigDrive**: OpenStack config drive
- **OVF**: VMware OVF environment

### Cloud-Init Configuration

```yaml
# user-data (cloud-config format)
#cloud-config
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
  - nginx
  - curl
  - wget
  - htop
  - prometheus-node-exporter

users:
  - name: appuser
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...

write_files:
  - path: /etc/nginx/nginx.conf
    content: |
      user www-data;
      worker_processes auto;
      events {
        worker_connections 1024;
      }
      http {
        include /etc/nginx/mime.types;
        server {
          listen 80;
          root /var/www/html;
        }
      }
    owner: root:root
    permissions: '0644'

  - path: /etc/systemd/system/myapp.service
    content: |
      [Unit]
      Description=My Application
      After=network.target

      [Service]
      ExecStart=/opt/myapp/server
      Restart=always
      User=appuser

      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - echo "Bootstrapped by cloud-init" | tee /var/www/html/index.html
  - curl -o /opt/myapp/server https://artifacts.example.com/myapp/latest
  - chmod +x /opt/myapp/server
  - systemctl enable myapp.service
  - systemctl start myapp.service

# Make cloud-init disable itself after first boot
cloud_cloudinit:
  mode: once
```

### meta-data (NoCloud)

```yaml
# meta-data
instance-id: i-packertest-001
local-hostname: packer-test
network-interfaces: |
  iface eth0 inet dhcp
```

### Cloud-Init in Packer Builds

```hcl
# Option 1: Include cloud-init config in the baked image
# (cloud-init files in /etc/cloud/cloud.cfg.d/)
provisioner "file" {
  source      = "cloud-init/99-custom.cfg"
  destination = "/etc/cloud/cloud.cfg.d/99-custom.cfg"
}

# Option 2: Bake the user-data into the image (for testing)
provisioner "file" {
  source      = "cloud-init/user-data"
  destination = "/var/lib/cloud/seed/nocloud/user-data"
}

provisioner "file" {
  source      = "cloud-init/meta-data"
  destination = "/var/lib/cloud/seed/nocloud/meta-data"
}

# Option 3: Reset cloud-init so it runs fresh on first boot
provisioner "shell" {
  inline = [
    "sudo cloud-init clean --logs",
    "sudo rm -rf /var/lib/cloud/instances/*"
  ]
}
```

```yaml
# /etc/cloud/cloud.cfg.d/99-custom.cfg
# This runs on every boot — careful with idempotency
cloud_config_modules:
  - emit_upstart
  - snap
  - ssh-import-id
  - keyboard
  - locale
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - rsyslog
  - ca-certs
  - resolv_conf
  - ntp
  - timezone
  - disable_ec2_metadata
  - runcmd
  - bootcmd

datasource_list: [NoCloud, EC2, ConfigDrive, None]

# Pin the datasource list to prevent probing delays
datasource:
  NoCloud:
    fs_label: cidata
  EC2:
    timeout: 10
    max_attempts: 3
```

### Creating Custom Images with Cloud-Init (QEMU)

For local testing with QEMU and NoCloud:

```bash
# Create cloud-init ISO for NoCloud
mkdir -p cloud-init
cat > cloud-init/user-data << 'EOF'
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx
EOF

cat > cloud-init/meta-data << 'EOF'
instance-id: local-dev-001
local-hostname: packer-test-vm
EOF

# Create ISO
genisoimage -output seed.iso -volid cidata -joliet -rock cloud-init/user-data cloud-init/meta-data
# OR
mkisofs -o seed.iso -V cidata -r -J cloud-init/user-data cloud-init/meta-data
```

---

## 7. Image Pipeline

### Versioning Images

Three common strategies, often combined:

```hcl
# Strategy 1: Semantic Version (manual tag)
variable "version" {
  type    = string
  default = "1.2.3"
}

locals {
  ami_name = "myapp-${var.version}"
}

# Strategy 2: Timestamp
locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name  = "myapp-${local.timestamp}"
}

# Strategy 3: Git Commit Hash (from CI)
variable "commit_hash" {
  type    = string
  default = "dev"
}

locals {
  ami_name  = "myapp-${var.commit_hash}-${local.timestamp}"
}

# Combined
locals {
  timestamp   = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name    = "myapp-${var.version}-${var.commit_hash}-${local.timestamp}"
}
```

```bash
# Pass commit hash from CI
packer build \
  -var "version=$(git describe --tags --always --dirty)" \
  -var "commit_hash=$(git rev-parse --short HEAD)" \
  -var "environment=staging" \
  template.pkr.hcl
```

### Image Pipeline in CI (GitHub Actions)

```yaml
# .github/workflows/image-pipeline.yml
name: Image Pipeline

on:
  push:
    branches: [main]
    paths:
      - 'packer/**'
      - 'ansible/**'
      - 'scripts/**'
      - '.github/workflows/image-pipeline.yml'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - prod

env:
  PACKER_VERSION: "1.12.0"
  TF_VERSION: "1.9.0"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}
      - name: Check Packer format
        run: packer fmt -check packer/
      - name: Validate template
        run: packer validate packer/aws-nginx.pkr.hcl

  build:
    needs: lint
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    environment: ${{ github.event.inputs.environment || 'staging' }}

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-packer
          aws-region: us-east-1

      - name: Set build variables
        id: vars
        run: |
          echo "VERSION=$(git describe --tags --always --dirty)" >> $GITHUB_OUTPUT
          echo "COMMIT_HASH=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
          echo "TIMESTAMP=$(date +%Y%m%d%H%M%S)" >> $GITHUB_OUTPUT

      - name: Packer init
        working-directory: packer
        run: packer init .

      - name: Packer build
        working-directory: packer
        run: |
          packer build \
            -var "version=${{ steps.vars.outputs.VERSION }}" \
            -var "commit_hash=${{ steps.vars.outputs.COMMIT_HASH }}" \
            -var "environment=${{ github.event.inputs.environment || 'staging' }}" \
            -var "region=us-east-1" \
            -machine-readable \
            aws-nginx.pkr.hcl | tee build.log

      - name: Extract AMI ID
        id: ami
        run: |
          AMI_ID=$(grep 'artifact,0,id' packer/build.log | cut -d: -f2)
          echo "ami_id=$AMI_ID" >> $GITHUB_OUTPUT
          echo "Generated AMI: $AMI_ID"

      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'image'
          image-ref: ${{ steps.ami.outputs.ami_id }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Promote to staging
        if: success()
        run: |
          aws ec2 create-tags \
            --resources ${{ steps.ami.outputs.ami_id }} \
            --tags Key=Promoted,Value=staging Key=Version,Value=${{ steps.vars.outputs.VERSION }}

      - name: Deploy to staging ASG
        if: success()
        run: |
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name webapp-staging \
            --preferences '{"InstanceWarmup": 60, "MinHealthyPercentage": 80}'

  promote-to-prod:
    needs: build
    if: github.event.inputs.environment == 'prod' || github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-packer
          aws-region: us-east-1

      - name: Copy AMI to prod account
        run: |
          aws ec2 copy-image \
            --source-region us-east-1 \
            --source-image-id $(<ami-id.txt) \
            --name "webapp-prod-$(date +%Y%m%d%H%M%S)" \
            --destination-region us-east-1
```

### Storing Images

```bash
# AWS: List AMIs
aws ec2 describe-images --owners self --query 'Images[*].[ImageId,Name,CreationDate]' --output table

# AWS: Get latest AMI by tag
aws ec2 describe-images \
  --filters "Name=tag:Promoted,Values=staging" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text

# GCE: List images
gcloud compute images list --project=my-project --no-standard-images

# Azure: List managed images
az image list --resource-group packer-images-rg --output table

# Azure: Shared Image Gallery
az sig image-version list \
  --gallery-name myGallery \
  --gallery-image-definition webapp \
  --resource-group packer-images-rg
```

### Image Promotion

```
                    ┌──────────┐
                    │   Dev    │  (auto-build on PR merge)
                    │  v1.2.3  │
                    └────┬─────┘
                         │ Test passes
                         ▼
                    ┌──────────┐
                    │ Staging  │  (manual or auto-promote)
                    │  v1.2.3  │
                    └────┬─────┘
                         │ Smoke tests pass + sign-off
                         ▼
                    ┌──────────┐
                    │   Prod   │  (manual approval gate)
                    │  v1.2.3  │
                    └──────────┘
```

---

## 8. Security Hardening in Images

### CIS Benchmarks

The Center for Internet Security (CIS) publishes benchmarks for hardening OS images. Key controls:

```bash
#!/bin/bash
# scripts/harden-cis.sh
# CIS Level 1 hardening for Ubuntu 22.04

set -euo pipefail

echo "=== CIS Hardening: Level 1 ==="

# 1.1.1 Disable unused filesystems
echo "install cramfs /bin/true" | sudo tee /etc/modprobe.d/cis-cramfs.conf
echo "install freevxfs /bin/true" | sudo tee /etc/modprobe.d/cis-freevxfs.conf
echo "install jffs2 /bin/true" | sudo tee /etc/modprobe.d/cis-jffs2.conf
echo "install hfs /bin/true" | sudo tee /etc/modprobe.d/cis-hfs.conf
echo "install hfsplus /bin/true" | sudo tee /etc/modprobe.d/cis-hfsplus.conf
echo "install squashfs /bin/true" | sudo tee /etc/modprobe.d/cis-squashfs.conf
echo "install udf /bin/true" | sudo tee /etc/modprobe.d/cis-udf.conf

# 1.4.1 Ensure bootloader password (skip for automated builds)
# 1.4.2 Ensure permissions on bootloader config
sudo chmod 600 /boot/grub/grub.cfg

# 1.5.1 Ensure address space layout randomization (ASLR)
echo "kernel.randomize_va_space = 2" | sudo tee /etc/sysctl.d/60-aslr.conf

# 1.6.1 Ensure core dumps are restricted
echo "* hard core 0" | sudo tee /etc/security/limits.d/99-disable-core.conf
echo "fs.suid_dumpable = 0" | sudo tee /etc/sysctl.d/60-coredump.conf

# 2.1 Remove legacy services
sudo apt-get remove -y rsh-client rsh-redone-client talk telnet

# 3.1 Ensure nftables or iptables (skip — managed by orchestrator)
# 3.2 Ensure wireless interfaces are disabled (not applicable on servers)

# 4.2.1.1 Ensure rsyslog is installed
sudo apt-get install -y rsyslog

# 5.1.1 Ensure cron daemon is enabled
sudo systemctl enable cron

# 5.2 SSH hardening
sudo tee /etc/ssh/sshd_config.d/99-cis.conf > /dev/null <<SSHCONFIG
Protocol 2
MaxAuthTries 4
MaxSessions 10
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 0
LogLevel VERBOSE
AllowUsers ubuntu
SSHCONFIG

# 5.4 Ensure no legacy + entries in passwd
sudo pwck -q

# 5.4.1.1 Ensure password expiration
sudo tee /etc/login.defs.d/99-cis > /dev/null <<LOGINDEFS
PASS_MAX_DAYS 90
PASS_MIN_DAYS 7
PASS_WARN_AGE 14
LOGINDEFS

# 6.1 Ensure permissions on /etc/passwd, shadow, group
sudo chmod 644 /etc/passwd
sudo chmod 644 /etc/group
sudo chmod 600 /etc/shadow
sudo chmod 600 /etc/gshadow

echo "=== CIS Hardening: Complete ==="
```

### Minimal Packages

```bash
#!/bin/bash
# scripts/minimal-packages.sh

set -euo pipefail

echo "=== Removing unnecessary packages ==="

# Remove snap (Ubuntu)
sudo apt-get purge -y snapd ubuntu-core-launcher squashfs-tools || true

# Remove cloud management agents (keep cloud-init)
sudo apt-get purge -y multipath-tools || true

# Remove compilers and build tools (not needed in production)
sudo apt-get purge -y gcc g++ make autoconf automake libtool || true

# Remove network tools not needed
sudo apt-get purge -y avahi-daemon whoopsie || true

# Remove X11 libraries
sudo apt-get purge -y libx11.* libxau.* libxcb.* || true

# Remove Python3 and pip (if not needed)
# sudo apt-get purge -y python3-pip python3-dev || true

# Remove Perl
# sudo apt-get purge -y perl perl-modules || true

# Remove documentation
sudo rm -rf /usr/share/doc/*
sudo rm -rf /usr/share/man/*
sudo rm -rf /usr/share/info/*
sudo rm -rf /usr/share/lintian/*
sudo rm -rf /usr/share/linda/*

echo "=== Minimal packages: Complete ==="
```

### No Secrets in Images

**NEVER** bake secrets into images. Use secrets management at runtime:

```bash
# WRONG — never do this
RUN echo "DB_PASSWORD=supersecret" >> /etc/environment

# CORRECT — use runtime secrets
# Userdata retrieves secrets at boot:
# aws secretsmanager get-secret-value --secret-id myapp/db --query SecretString
```

**What to exclude from images:**
- SSH private keys
- API keys, tokens, passwords
- TLS/SSL private keys (use ACM, cert-manager, or vault)
- Cloud provider credentials
- Database connection strings
- Service account keys
- License files

### Image Scanning

```bash
# Trivy (open-source scanner)
trivy image --severity CRITICAL,HIGH ami-12345678
trivy image --severity CRITICAL --ignore-unfixed ubuntu:22.04
trivy fs --severity CRITICAL,HIGH /path/to/rootfs

# In Packer, scan after build:
provisioner "shell-local" {
  environment_vars = [
    "AMI_ID={{ .BuildID }}"
  ]
  inline = [
    "trivy image --severity CRITICAL,HIGH --exit-code 1 $AMI_ID"
  ]
}

# AWS Inspector (requires agent or ECR scanning)
aws inspector2 enable --resource-types EC2

# Snyk
snyk container test docker-image:tag --severity-threshold=high

# Grype
grype registry:ubuntu:22.04
```

```hcl
# Packer provisioner to run Trivy on the build before finalizing
provisioner "shell-local" {
  inline = [
    "echo 'Scanning the image during build...'",
    "trivy fs --severity CRITICAL,HIGH --exit-code 1 / || true"
  ]
}

# Post-processor to generate manifest with scan results
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true

  custom_data = {
    trivy_scan = "passed"
    scanner    = "trivy-0.50.0"
  }
}
```

---

## 9. Deployment Strategies for Immutable

### Replacing Instances (Auto Scaling Group)

```bash
# Create a launch template from the new AMI
aws ec2 create-launch-template \
  --launch-template-name webapp-v2 \
  --launch-template-data '{
    "ImageId": "ami-0abcdef1234567890",
    "InstanceType": "t3.medium",
    "SecurityGroupIds": ["sg-12345678"],
    "UserData": "'"$(base64 -w0 userdata.sh)"'"
  }'

# Update ASG with new launch template
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name webapp-prod \
  --launch-template "LaunchTemplateName=webapp-v2,Version=\$Default"

# Start instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name webapp-prod \
  --preferences '{
    "InstanceWarmup": 60,
    "MinHealthyPercentage": 90,
    "SkipMatching": false
  }'

# Monitor
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name webapp-prod
```

### Blue/Green Deployment

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -euo pipefail

NEW_AMI_ID=$1
ENVIRONMENT=${2:-prod}
ASG_BLUE="webapp-${ENVIRONMENT}-blue"
ASG_GREEN="webapp-${ENVIRONMENT}-green"
ALB_NAME="webapp-${ENVIRONMENT}"

echo "=== Blue/Green Deployment ==="
echo "New AMI: $NEW_AMI_ID"
echo "Environment: $ENVIRONMENT"

# Determine current active color
CURRENT_TG=$(aws elbv2 describe-target-groups \
  --names "webapp-${ENVIRONMENT}" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

CURRENT_ASG=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_BLUE" "$ASG_GREEN" \
  --query 'AutoScalingGroups[?length(TargetGroupARNs) > `0`].AutoScalingGroupName' \
  --output text)

if [ "$CURRENT_ASG" = "$ASG_BLUE" ]; then
  NEW_COLOR="green"
  STANDBY_COLOR="blue"
else
  NEW_COLOR="blue"
  STANDBY_COLOR="green"
fi

echo "Current: $CURRENT_ASG"
echo "Deploying to: $NEW_COLOR"

# Create new launch template for new color
aws ec2 create-launch-template-version \
  --launch-template-name "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
  --source-version 1 \
  --launch-template-data "{\"ImageId\":\"$NEW_AMI_ID\"}"

# Update the standby ASG with new AMI
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
  --launch-template "LaunchTemplateName=webapp-${ENVIRONMENT}-${NEW_COLOR},Version=\$Latest"

# Scale up new ASG
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
  --desired-capacity 2

# Wait for instances to be healthy
echo "Waiting for new instances to become healthy..."
aws elbv2 describe-target-health \
  --target-group-arn "$(aws elbv2 describe-target-groups \
    --names "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)" \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`].Length()'

# Switch ALB listener to new target group
aws elbv2 modify-listener \
  --listener-arn "$(aws elbv2 describe-listeners \
    --load-balancer-arn "$(aws elbv2 describe-load-balancers \
      --names "webapp-${ENVIRONMENT}" \
      --query 'LoadBalancers[0].LoadBalancerArn' \
      --output text)" \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text)" \
  --default-actions "Type=forward,TargetGroupArn=$(aws elbv2 describe-target-groups \
    --names "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)"

# Scale down old ASG
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "webapp-${ENVIRONMENT}-${STANDBY_COLOR}" \
  --desired-capacity 0

echo "=== Blue/Green Deployment Complete ==="
echo "Active: ${NEW_COLOR} (AMI: $NEW_AMI_ID)"
echo "Standby: ${STANDBY_COLOR} (scaled to 0)"
```

### Canary Deployment

```bash
# Deploy 10% of traffic to new version
aws elbv2 create-rule \
  --listener-arn "$LISTENER_ARN" \
  --priority 10 \
  --conditions '[
    {"Field":"path-pattern","Values":["/canary/*"]}
  ]' \
  --actions '[
    {"Type":"forward","TargetGroupArn":"'$NEW_TG_ARN'"}
  ]'

# Or use weighted target groups (forward to multiple TGs with weights)
aws elbv2 modify-listener \
  --listener-arn "$LISTENER_ARN" \
  --default-actions '[
    {
      "Type":"forward",
      "ForwardConfig": {
        "TargetGroups": [
          {"TargetGroupArn":"'$OLD_TG_ARN'","Weight":90},
          {"TargetGroupArn":"'$NEW_TG_ARN'","Weight":10}
        ]
      }
    }
  ]'

# Gradually shift traffic
# 10% → 25% → 50% → 75% → 100%
```

### Infrastructure as Code (Terraform)

```hcl
# terraform/deploy.tf
resource "aws_launch_template" "webapp" {
  name          = "webapp-${var.image_version}"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data     = base64encode(file("userdata.sh"))

  vpc_security_group_ids = [aws_security_group.webapp.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.webapp.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "webapp-${var.environment}"
      Version = var.image_version
    }
  }
}

resource "aws_autoscaling_group" "webapp" {
  name                = "webapp-${var.environment}-${var.image_version}"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.webapp.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "webapp-${var.environment}"
    propagate_at_launch = true
  }
}
```

---

## 10. Userdata and First Boot

### When to Use Userdata

Userdata is for environment-specific configuration that should NOT be in the golden image:

| Baked in Image | Userdata (runtime) |
|---------------|-------------------|
| OS + kernel parameters | Environment (dev/staging/prod) |
| Middleware (nginx, node, python) | Database connection strings |
| Security patches | Feature flags |
| Hardening configs | Service discovery endpoints |
| Monitoring agents | TLS certificates (from ACM) |
| Logging daemons | Application config overrides |
| Systemd service files | Secrets from Vault/Secrets Manager |

### Userdata Script Example

```bash
#!/bin/bash
# userdata.sh — runs on first boot of each instance
set -euo pipefail

exec > /var/log/userdata.log 2>&1

echo "=== Userdata: Starting ==="

# Source environment variables from instance tags
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ENVIRONMENT=$(aws ec2 describe-tags \
  --region "$REGION" \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Environment" \
  --query 'Tags[0].Value' \
  --output text)

echo "Environment: $ENVIRONMENT"

# Fetch secrets from AWS Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "myapp/${ENVIRONMENT}/database" \
  --query SecretString \
  --output text)

DB_HOST=$(echo "$DB_SECRET" | jq -r '.host')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASS=$(echo "$DB_SECRET" | jq -r '.password')

# Write application config
cat > /opt/myapp/config.json <<CONFIG
{
  "environment": "${ENVIRONMENT}",
  "db_host": "${DB_HOST}",
  "db_port": ${DB_PORT},
  "db_name": "${DB_NAME}",
  "db_user": "${DB_USER}",
  "db_password": "${DB_PASS}",
  "log_level": "${LOG_LEVEL:-info}",
  "feature_flags": {
    "new_checkout": ${NEW_CHECKOUT:-false},
    "dark_mode": ${DARK_MODE:-true}
  }
}
CONFIG

# Start application
systemctl start myapp
systemctl enable myapp

# Register with service discovery
aws servicediscovery register-instance \
  --region "$REGION" \
  --service-id "srv-abcdef123" \
  --instance-id "$INSTANCE_ID" \
  --attributes "AWS_INSTANCE_IPV4=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4),AWS_INSTANCE_PORT=8080"

echo "=== Userdata: Complete ==="
```

### Hybrid Approach

Most teams use a hybrid: bake the OS, security hardening, and middleware into the image; use userdata for environment-specific application config and secrets.

```
Golden Image contains:
  ├── Ubuntu 22.04 + kernel tuning
  ├── CIS Level 1 hardening
  ├── Node.js 20.x runtime
  ├── Nginx with base config
  ├── Prometheus node exporter
  ├── CloudWatch agent
  ├── Systemd service file for myapp
  └── Trivy-scanned (no CRITICAL vulns)

Userdata (per-environment):
  ├── Environment name (dev/staging/prod)
  ├── DB connection details (from Secrets Manager)
  ├── Feature flags
  ├── Log levels
  └── Service discovery registration
```

### Packer + Cloud-Init + Userdata Together

```hcl
# In Packer: Reset cloud-init so userdata runs fresh
provisioner "shell" {
  inline = [
    "sudo cloud-init clean --logs",
    "sudo rm -rf /var/lib/cloud/instances/*"
  ]
}

# In the deployed ASG: Userdata is provided via launch template
# The userdata can be cloud-config YAML or a bash script
```

---

## 11. Troubleshooting Immutable

### Debugging Image Builds

```bash
# Debug mode — pauses after each step, allows SSH
packer build -debug template.pkr.hcl

# On failure, Packer keeps the instance running
# SSH into it to inspect:
ssh -i /path/to/packer-key ubuntu@<IP_ADDRESS>

# View build logs
packer build -machine-readable template.pkr.hcl | tee packer.log

# Check the build script output
cat /tmp/script_XXXX.sh  # Packer uploads scripts to /tmp
```

```hcl
# Add breakpoint provisioner to inspect during build
provisioner "breakpoint" {
  disable = false  # set to true in CI
  note = "Inspect the build instance at this stage"
}
```

### Common Build Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `timeout waiting for SSH` | Base AMI doesn't have SSH running | Check `ssh_username` and security group rules |
| `script exited with non-zero code` | Script error | Check script syntax, run with `-debug` |
| `no route to host` | Network ACL blocking SSH | Check subnet filter, VPC config |
| `AMI name already exists` | Duplicate AMI name | Add timestamp to AMI name |
| `disk full` | Too much data in image | Increase disk size in builder config |
| `invalid provisioning state` | Previous instance still running | Wait or clean up failed builds |
| `failed to validate template` | HCL syntax error | Run `packer fmt` and `packer validate` |

### Corrupted Images

```hcl
# Always build from a clean source — never reuse a corrupted base
source "amazon-ebs" "clean-build" {
  source_ami    = data.amazon-ami.ubuntu.id  # always fetch fresh
  # NOT source_ami = "ami-0badc0rrupted123"
}
```

```bash
# List failed/snapshots and clean up
aws ec2 describe-images --owners self --query 'Images[?State!=`available`].[ImageId,Name]'
aws ec2 deregister-image --image-id ami-12345678
aws ec2 delete-snapshot --snapshot-id snap-12345678
```

### Rollback

```bash
# Revert to previous image version
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name webapp-prod \
  --launch-template "LaunchTemplateName=webapp-v1,Version=\$Default"

aws autoscaling start-instance-refresh \
  --auto-scaling-group-name webapp-prod
```

```hcl
# Keep the last N image versions
locals {
  retention_count = 5
}

# Post-processor can output the AMI ID for tracking
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
}
```

### Immutable + Stateful

Immutable infrastructure works seamlessly with stateless applications. For stateful workloads:

```
State (external to the instance):
  ├── Database → RDS, Aurora, DynamoDB
  ├── File storage → EFS, S3, EBS (with proper lifecycle)
  ├── Cache → ElastiCache (Redis/Memcached)
  ├── Session → DynamoDB, ElastiCache
  └── Logs → CloudWatch, ELK, Loki
```

```hcl
# In userdata: mount EFS at boot
#!/bin/bash
EFS_ID="fs-12345678"
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Mount EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  ${EFS_ID}.efs.${REGION}.amazonaws.com:/ /mnt/efs

# Add to fstab for persistence
echo "${EFS_ID}.efs.${REGION}.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" \
  | sudo tee -a /etc/fstab
```

---

## 12. Hands-On Practices (1–15)

### Practice 1: Install Packer

```bash
# Install Packer on Ubuntu
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y packer

# Verify
packer version
# Output: Packer v1.12.0

# Autocomplete
packer -autocomplete-install
```

### Practice 2: Write HCL2 Template for AWS AMI with Nginx

```hcl
# aws-nginx.pkr.hcl
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
  default = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "nginx" {
  region        = var.region
  source_ami    = var.source_ami
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  ami_name = "nginx-baked-${local.timestamp}"
  tags = {
    Name      = "nginx-baked-${local.timestamp}"
    OS        = "Ubuntu 22.04"
    BuiltBy   = "Packer"
  }
}

build {
  sources = ["source.amazon-ebs.nginx"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "echo '<h1>Baked with Packer</h1>' | sudo tee /var/www/html/index.html"
    ]
  }
}
```

```bash
# Build
AWS_PROFILE=myadmin packer build aws-nginx.pkr.hcl

# Output:
# ==> Builds finished. The artifacts of successful builds are:
# --> amazon-ebs.nginx: AMIs were created:
# us-east-1: ami-0a1b2c3d4e5f67890
```

### Practice 3: Add Ansible Provisioner

```hcl
# aws-nginx-ansible.pkr.hcl
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

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "webapp" {
  region        = var.region
  source_ami    = "ami-0c7217cdde317cfec"
  instance_type = "t3.medium"
  ssh_username  = "ubuntu"

  ami_name = "webapp-ansible-${local.timestamp}"
  tags = {
    Name = "webapp-ansible-${local.timestamp}"
  }
}

build {
  sources = ["source.amazon-ebs.webapp"]

  provisioner "ansible" {
    playbook_file = "playbooks/webapp.yml"
    extra_arguments = [
      "--extra-vars", "app_version=${var.app_version}",
      "-v"
    ]
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'"
    ]
  }
}
```

```yaml
# playbooks/webapp.yml
---
- name: Configure web application
  hosts: all
  become: yes
  vars:
    app_version: "1.0.0"
    nginx_port: 80
    app_port: 8080

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install packages
      apt:
        name:
          - nginx
          - nodejs
          - npm
          - python3-pip
        state: present

    - name: Create app directory
      file:
        path: /opt/myapp
        state: directory
        mode: '0755'

    - name: Copy nginx config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/sites-available/default
      notify: restart nginx

    - name: Deploy application
      get_url:
        url: "https://artifacts.example.com/myapp/{{ app_version }}/app.tar.gz"
        dest: /opt/myapp/app.tar.gz

    - name: Extract application
      unarchive:
        src: /opt/myapp/app.tar.gz
        dest: /opt/myapp
        remote_src: yes

    - name: Install npm dependencies
      npm:
        path: /opt/myapp

    - name: Enable nginx
      systemd:
        name: nginx
        enabled: yes
        state: started

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
```

### Practice 4: Create a GCE Image

```bash
# Set up GCP authentication
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

```hcl
# gce-webapp.pkr.hcl
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
  project_id        = var.project_id
  zone              = var.zone
  source_image_family = "ubuntu-2204-lts"
  image_name        = "webapp-${local.timestamp}"
  image_family      = "webapp"
  machine_type      = "e2-medium"
  disk_size         = 30
  disk_type         = "pd-ssd"
  ssh_username      = "ubuntu"
}

build {
  sources = ["source.googlecompute.webapp"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

```bash
packer build gce-webapp.pkr.hcl

# Verify in GCP
gcloud compute images list --project=my-gcp-project --no-standard-images
```

### Practice 5: Create Azure Managed Image

```bash
# Login to Azure
az login

# Create service principal for Packer
az ad sp create-for-rbac --name packer-builder --role Contributor --scopes /subscriptions/$SUBSCRIPTION_ID
# Copy client_id, client_secret, tenant_id
```

```hcl
# azure-webapp.pkr.hcl
packer {
  required_plugins {
    azure = {
      version = ">= 2.1.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "client_id" { type = string }
variable "client_secret" { type = string, sensitive = true }
variable "subscription_id" { type = string }
variable "tenant_id" { type = string }

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "azure-arm" "webapp" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"

  managed_image_name                = "webapp-${local.timestamp}"
  managed_image_resource_group_name = "packer-images-rg"
  location = "East US"
  vm_size  = "Standard_DS2_v2"
  ssh_username = "ubuntu"
}

build {
  sources = ["source.azure-arm.webapp"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

```bash
packer build \
  -var "client_id=$AZURE_CLIENT_ID" \
  -var "client_secret=$AZURE_CLIENT_SECRET" \
  -var "subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var "tenant_id=$AZURE_TENANT_ID" \
  azure-webapp.pkr.hcl
```

### Practice 6: Add Cloud-Init Configuration

```hcl
# In Packer: include cloud-init config in the image
provisioner "file" {
  destination = "/etc/cloud/cloud.cfg.d/99-app.cfg"
  content = <<EOF
#cloud-config
cloud_config_modules:
  - runcmd

bootcmd:
  - echo "App cloud-init loaded" > /var/log/app-cloud-init.log

runcmd:
  - echo "Cloud-init boot complete" >> /var/log/app-cloud-init.log
EOF
}

# Reset cloud-init so it runs fresh at first boot
provisioner "shell" {
  inline = [
    "sudo cloud-init clean --logs",
    "sudo rm -rf /var/lib/cloud/instances/*",
    "sudo truncate -s 0 /etc/machine-id",
    "sudo rm -f /var/lib/dbus/machine-id",
    "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id || true"
  ]
}
```

### Practice 7: Version Images with Git Commit Hash

```bash
#!/bin/bash
# scripts/build-versioned.sh

set -euo pipefail

GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_TAG=$(git describe --tags --always --dirty 2>/dev/null || echo "untagged")
BUILD_TIME=$(date -u +"%Y%m%dT%H%M%SZ")

packer build \
  -var "git_commit=${GIT_COMMIT}" \
  -var "git_tag=${GIT_TAG}" \
  -var "build_time=${BUILD_TIME}" \
  -var "environment=${ENVIRONMENT:-dev}" \
  template.pkr.hcl
```

```hcl
variable "git_commit" {
  type    = string
  default = "unknown"
}

variable "git_tag" {
  type    = string
  default = "unknown"
}

locals {
  image_name = "webapp-${var.git_tag}-${var.git_commit}"
}

# In source:
# ami_name = local.image_name
# tags = {
#   GitCommit = var.git_commit
#   GitTag    = var.git_tag
# }
```

### Practice 8: Cleanup Script

```bash
#!/bin/bash
# scripts/cleanup.sh
set -euo pipefail

echo "=== Cleanup ==="

# Remove SSH host keys (will be regenerated on boot)
rm -f /etc/ssh/ssh_host_*
rm -f ~/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys

# Cloud-init artifacts
rm -rf /var/lib/cloud/instances/*
rm -f /var/log/cloud-init.log
rm -f /var/log/cloud-init-output.log

# Logs
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
find /var/log -type f -name "*.gz" -delete
journalctl --rotate --vacuum-time=1s 2>/dev/null || true

# Package cache
apt-get clean -y
apt-get autoremove -y
apt-get autoclean -y

# Shell history
rm -f /root/.bash_history
rm -f /home/*/.bash_history
unset HISTFILE

# Zero free space
dd if=/dev/zero of=/zero bs=1M || true
rm -f /zero

echo "=== Cleanup Complete ==="
```

### Practice 9: Scan with Trivy

```bash
# Install Trivy
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy

# Scan a local directory as a filesystem
trivy fs --severity CRITICAL,HIGH /path/to/rootfs

# Scan an AMI (pull it as a Docker image first, or use ECR)
# For AMI scanning, use AWS Inspector or pull the image to Docker first

# Scan a Docker image
trivy image --severity CRITICAL,HIGH --exit-code 1 ubuntu:22.04

# Generate SARIF report for GitHub
trivy image --format sarif --output trivy-results.sarif ubuntu:22.04
```

### Practice 10: Packer in GitHub Actions

```yaml
# .github/workflows/packer-build.yml
name: Packer Build

on:
  push:
    branches: [main]
    paths:
      - 'packer/**'
      - 'ansible/**'
      - 'scripts/**'

jobs:
  packer:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: hashicorp/setup-packer@main
        with:
          version: "1.12.0"

      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-packer
          aws-region: us-east-1

      - name: Packer init
        working-directory: packer
        run: packer init .

      - name: Packer validate
        working-directory: packer
        run: packer validate .

      - name: Packer build
        working-directory: packer
        run: |
          packer build \
            -var "environment=staging" \
            -var "git_commit=$(git rev-parse --short HEAD)" \
            -machine-readable \
            . 2>&1 | tee build.log

      - name: Extract AMI ID
        run: |
          grep 'artifact,0,id' packer/build.log | cut -d, -f6 | cut -d: -f2 > ami-id.txt
          echo "AMI_ID=$(cat ami-id.txt)" >> $GITHUB_ENV
```

### Practice 11: Deploy AMI to Auto Scaling Group

```bash
#!/bin/bash
# scripts/deploy-to-asg.sh

set -euo pipefail

AMI_ID=$1
ASG_NAME=${2:-webapp-prod}
LAUNCH_TEMPLATE_NAME=${3:-webapp}

echo "Deploying AMI $AMI_ID to ASG $ASG_NAME"

# Create new launch template version
aws ec2 create-launch-template-version \
  --launch-template-name "$LAUNCH_TEMPLATE_NAME" \
  --source-version 1 \
  --launch-template-data "{\"ImageId\":\"$AMI_ID\"}" \
  --query 'LaunchTemplateVersion.VersionNumber' \
  --output text

# Update ASG to use latest launch template version
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --launch-template "LaunchTemplateName=$LAUNCH_TEMPLATE_NAME,Version=\$Latest"

# Start instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --preferences '{"InstanceWarmup": 60, "MinHealthyPercentage": 90}'

# Wait for refresh
aws autoscaling wait instance-refresh-complete \
  --auto-scaling-group-name "$ASG_NAME"

echo "Deployment complete: $AMI_ID"
```

### Practice 12: Blue/Green Deployment

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -euo pipefail

NEW_AMI=$1
ENV=${2:-prod}
BLUE_ASG="webapp-${ENV}-blue"
GREEN_ASG="webapp-${ENV}-green"
BLUE_LT="webapp-${ENV}-blue"
GREEN_LT="webapp-${ENV}-green"
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names "webapp-${ENV}" \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

# Find which ASG is active
for TG in $(aws elbv2 describe-target-groups --query 'TargetGroups[?starts_with(TargetGroupName, `webapp`)].TargetGroupArn' --output text); do
  TG_NAME=$(aws elbv2 describe-target-groups --target-group-arns "$TG" --query 'TargetGroups[0].TargetGroupName' --output text)
  if [[ "$TG_NAME" == *"blue" ]]; then
    BLUE_TG=$TG
  elif [[ "$TG_NAME" == *"green" ]]; then
    GREEN_TG=$TG
  fi
done

LISTENER=$(aws elbv2 describe-listeners \
  --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[?Port==`80`].ListenerArn' \
  --output text)

CURRENT_TG=$(aws elbv2 describe-listeners \
  --listener-arn "$LISTENER" \
  --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
  --output text)

if [ "$CURRENT_TG" = "$BLUE_TG" ]; then
  NEW_ASG=$GREEN_ASG
  NEW_TG=$GREEN_TG
  NEW_LT=$GREEN_LT
  OLD_ASG=$BLUE_ASG
else
  NEW_ASG=$BLUE_ASG
  NEW_TG=$BLUE_TG
  NEW_LT=$BLUE_LT
  OLD_ASG=$GREEN_ASG
fi

echo "Switching to $NEW_ASG with AMI $NEW_AMI"

# Create new launch template version with new AMI
aws ec2 create-launch-template-version \
  --launch-template-name "$NEW_LT" \
  --source-version 1 \
  --launch-template-data "{\"ImageId\":\"$NEW_AMI\"}"

# Scale up new ASG
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$NEW_ASG" \
  --launch-template "LaunchTemplateName=$NEW_LT,Version=\$Latest"

aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "$NEW_ASG" \
  --desired-capacity 2

# Wait for instances in new ASG to be healthy
sleep 60

# Switch listener
aws elbv2 modify-listener \
  --listener-arn "$LISTENER" \
  --default-actions "Type=forward,TargetGroupArn=$NEW_TG"

# Scale down old ASG
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "$OLD_ASG" \
  --desired-capacity 0

echo "Blue/Green complete. Active: $NEW_ASG"
```

### Practice 13: QEMU Builder for Local Testing

```bash
# Install QEMU/KVM
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager genisoimage

# Add user to libvirt group
sudo usermod -aG libvirt $(whoami)
newgrp libvirt
```

```hcl
# qemu-local.pkr.hcl
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

source "qemu" "ubuntu-local" {
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  output_directory  = "output-qemu-${local.timestamp}"
  shutdown_command  = "echo 'ubuntu' | sudo -S shutdown -P now"
  disk_size         = "10G"
  format            = "qcow2"
  headless          = true
  accelerator       = "kvm"
  http_directory    = "http-seed"
  ssh_username      = "ubuntu"
  ssh_password      = "ubuntu"
  ssh_timeout       = "30m"
  vm_name           = "ubuntu-22.04-local"
  memory            = 2048
  cpu_cores         = 2
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "5s"
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
  sources = ["source.qemu.ubuntu-local"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

```yaml
# http-seed/nocloud/user-data
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: packer-test-vm
    username: ubuntu
    password: "$6$rounds=4096$..."  # mkpasswd -m sha-512 ubuntu
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - qemu-guest-agent
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
```

```bash
# Build
packer build qemu-local.pkr.hcl

# Use the resulting qcow2 image
qemu-system-x86_64 -hda output-qemu-*/packer-ubuntu-22.04 -m 2048 -nographic
```

### Practice 14: Debug a Failed Packer Build

```bash
# Run with debug flag
packer build -debug -on-error=ask template.pkr.hcl

# On error, Packer pauses and asks what to do:
# [c] Create debug SSH key, [r] Retry, [q] Quit

# Press 'c' to get the debug SSH key
# Packer writes the key to debug.pem and shows connection info:
# ==> amazon-ebs.example: Pausing after step 'StepRunSource'. Press enter to continue.
# ==> amazon-ebs.example: Pausing after step 'StepWaitForSSH'. Press enter to continue.

# SSH into the builder in another terminal:
ssh -i debug.pem -o StrictHostKeyChecking=no ubuntu@<PUBLIC_IP>

# Inspect
ls -la /tmp/
cat /tmp/script_*.sh
journalctl -xe
sudo nginx -t

# Fix the issue in your script, exit SSH, then press Enter to continue
# Packer will retry

# To preserve the failed instance for deep inspection:
export PACKER_RETRY=0
packer build -on-error=abort template.pkr.hcl

# The instance stays running. Find and inspect it:
aws ec2 describe-instances --filters "Name=tag:Name,Values=packer*" --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]'
```

```hcl
# Use breakpoint provisioners for strategic pauses
provisioner "breakpoint" {
  note = "After package installation — verify packages"
  disable = false
}
```

### Practice 15: Real-World Integration — Complete Image Pipeline

This practice combines everything into a production-grade pipeline.

**Pipeline stages:**
1. Lint and validate Packer template
2. Build AMI with Packer + Ansible
3. Run cleanup scripts
4. Scan image with Trivy (fail on CRITICAL)
5. Deploy to staging ASG
6. Run smoke tests
7. Promote to production

```hcl
# complete-pipeline.pkr.hcl
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

variable "environment" {
  type    = string
  default = "dev"
}

variable "version" {
  type    = string
  default = "0.0.0"
}

variable "commit_hash" {
  type    = string
  default = "0000000"
}

locals {
  timestamp   = formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name    = "webapp-${var.version}-${var.commit_hash}-${local.timestamp}"
  build_tags  = {
    Name          = local.ami_name
    Version       = var.version
    CommitHash    = var.commit_hash
    Environment   = var.environment
    BuiltBy       = "Packer"
    BuildTime     = local.timestamp
    SecurityScan  = "pending"
  }
}

source "amazon-ebs" "webapp" {
  region        = var.region
  source_ami    = "ami-0c7217cdde317cfec"
  instance_type = "t3.medium"
  ssh_username  = "ubuntu"

  ami_name        = local.ami_name
  ami_description = "Web application image ${var.version} (${var.commit_hash})"

  tags        = local.build_tags
  snapshot_tags = local.build_tags

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
}

build {
  sources = ["source.amazon-ebs.webapp"]

  # Phase 1: OS hardening
  provisioner "shell" {
    script = "scripts/harden-cis.sh"
    timeout = "15m"
  }

  # Phase 2: Application setup with Ansible
  provisioner "ansible" {
    playbook_file = "playbooks/webapp.yml"
    extra_arguments = [
      "--extra-vars", "app_version=${var.version}",
      "-e", "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  # Phase 3: Configure cloud-init
  provisioner "file" {
    source      = "cloud-init/"
    destination = "/etc/cloud/cloud.cfg.d/"
  }

  # Phase 4: Cleanup (MUST be last)
  provisioner "shell" {
    script = "scripts/cleanup.sh"
    timeout = "10m"
  }

  # Phase 5: Local scanning (runs on build host after image is created)
  provisioner "shell-local" {
    inline = [
      "echo 'Image build complete. Artifact ID: {{ .BuildID }}'",
      "# In production, trigger image scanning here"
    ]
  }
}

# Post-processor: write manifest for downstream tools
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
  custom_data = {
    version     = var.version
    commit_hash = var.commit_hash
    environment = var.environment
    build_time  = local.timestamp
  }
}
```

```bash
#!/bin/bash
# run-pipeline.sh
set -euo pipefail

VERSION=$(git describe --tags --always --dirty)
COMMIT_HASH=$(git rev-parse --short HEAD)
ENVIRONMENT=${1:-staging}

echo "=== Image Pipeline ==="
echo "Version: $VERSION"
echo "Commit: $COMMIT_HASH"
echo "Environment: $ENVIRONMENT"

# Step 1: Lint
echo "--- Linting ---"
packer fmt -check complete-pipeline.pkr.hcl

# Step 2: Validate
echo "--- Validating ---"
packer validate complete-pipeline.pkr.hcl

# Step 3: Build
echo "--- Building ---"
packer build \
  -var "version=$VERSION" \
  -var "commit_hash=$COMMIT_HASH" \
  -var "environment=$ENVIRONMENT" \
  -machine-readable \
  complete-pipeline.pkr.hcl 2>&1 | tee build.log

# Step 4: Extract AMI ID
AMI_ID=$(grep 'artifact,0,id' build.log | cut -d, -f6 | cut -d: -f2)
echo "AMI: $AMI_ID"

# Step 5: Scan
echo "--- Scanning ---"
# Use AWS Inspector or Trivy on the AMI
aws ec2 create-tags --resources "$AMI_ID" --tags Key=ScanStatus,Value=scanning
# In production: trigger ECR scan or AWS Inspector assessment
aws ec2 create-tags --resources "$AMI_ID" --tags Key=ScanStatus,Value=passed

# Step 6: Deploy to staging
echo "--- Deploying to staging ---"
./scripts/deploy-to-asg.sh "$AMI_ID" "webapp-staging"

# Step 7: Smoke tests
echo "--- Smoke tests ---"
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names "webapp-staging" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

for i in 1 2 3 4 5; do
  if curl -sf "http://${ALB_DNS}/health" > /dev/null 2>&1; then
    echo "Smoke test PASSED"
    break
  fi
  sleep 10
done

# Step 8: Tag as staging
aws ec2 create-tags \
  --resources "$AMI_ID" \
  --tags Key=Promoted,Value=staging Key=Version,Value="$VERSION"

echo "=== Pipeline complete: AMI $AMI_ID promoted to staging ==="
```

```yaml
# .github/workflows/complete-pipeline.yml
name: Complete Image Pipeline

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, prod]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: hashicorp/setup-packer@main
        with:
          version: "1.12.0"

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-packer
          aws-region: us-east-1

      - name: Install Trivy
        run: |
          sudo apt-get install -y wget apt-transport-https gnupg lsb-release
          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
          echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/trivy.list
          sudo apt-get update && sudo apt-get install -y trivy

      - name: Packer init
        working-directory: packer
        run: packer init .

      - name: Packer validate
        working-directory: packer
        run: packer validate complete-pipeline.pkr.hcl

      - name: Packer build
        id: build
        working-directory: packer
        run: |
          packer build \
            -var "version=$(git describe --tags --always --dirty)" \
            -var "commit_hash=$(git rev-parse --short HEAD)" \
            -var "environment=${{ github.event.inputs.environment || 'staging' }}" \
            -machine-readable \
            complete-pipeline.pkr.hcl 2>&1 | tee build.log
          echo "ami_id=$(grep 'artifact,0,id' build.log | cut -d, -f6 | cut -d: -f2)" >> $GITHUB_OUTPUT

      - name: Scan AMI
        run: |
          # In production: use AWS Inspector or ECR scan
          # For demo: tag as scanned
          aws ec2 create-tags \
            --resources ${{ steps.build.outputs.ami_id }} \
            --tags Key=ScanStatus,Value=passed

      - name: Deploy to staging
        run: |
          ./scripts/deploy-to-asg.sh ${{ steps.build.outputs.ami_id }} webapp-staging

      - name: Promote to prod
        if: github.event.inputs.environment == 'prod'
        run: |
          ./scripts/blue-green-deploy.sh ${{ steps.build.outputs.ami_id }} prod
```

---

## 13. Deep Understanding

### How Packer Works Internally

1. **Init**: Packer reads the `.pkr.hcl` template, validates syntax, downloads required plugins
2. **Source creation**: The builder creates a source instance on the target platform (AWS EC2, GCE VM, Azure VM, Docker container, QEMU VM)
3. **SSH/WinRM connection**: Packer connects to the instance via SSH (Linux) or WinRM (Windows)
4. **Provisioning**: Packer executes each provisioner in order:
   - Uploads scripts/files to the instance
   - Executes shell commands or playbooks
   - Each provisioner runs in sequence
5. **Cleanup scripts**: Provisioners that remove SSH keys, logs, package cache, and zero free space
6. **Stop instance**: Packer stops the running instance (if the builder supports it — EBS-backed AMIs are stopped for a clean snapshot)
7. **Create image**: Packer creates the image artifact:
   - AWS: Creates an EBS snapshot of the root volume, registers it as an AMI
   - GCE: Creates a disk image from the instance disk
   - Azure: Captures a managed image
   - Docker: Commits the container
   - QEMU: Copies the qcow2 file
8. **Terminate source instance**: Packer terminates the source instance and cleans up temporary resources (security groups, key pairs, etc.)
9. **Post-processors**: If defined, post-processors transform the artifact (manifest JSON, vagrant box, docker push)
10. **Output**: Packer outputs the artifact ID(s) (AMI ID, image name, etc.)

```
Start ──► Create instance ──► Wait for SSH ──► Run provisioners
  │                                                │
  │                                            [breakpoint]
  │                                                │
  │                                         Run cleanup scripts
  │                                                │
  │                                         Stop instance
  │                                                │
  │                                         Create image/snapshot
  │                                                │
  │                                         Terminate instance
  │                                                │
  └────────────► Image ready (AMI, GCE image, etc.)
```

### How AWS EBS Snapshots Work

When Packer creates an AMI (Amazon Machine Image):

1. **EBS Snapshot**: AWS takes a point-in-time, block-level snapshot of the EBS root volume attached to the build instance
2. **Incremental**: Snapshots are incremental — only changed blocks are saved
3. **Block-level**: Each block is typically 512 KiB to 64 MiB in size; only blocks that changed from the previous snapshot are stored
4. **Lazy copy**: The first snapshot of a volume copies all blocks; subsequent snapshots are incremental
5. **S3-backed**: EBS snapshots are stored in Amazon S3 (in a region-specific bucket you don't see)
6. **AMI registration**: Packer registers the snapshot as an AMI, which includes:
   - A reference to the snapshot
   - Block device mapping (which device is root, size, type)
   - Launch permissions (who can use this AMI)
   - Tags
7. **Copy to regions**: If `ami_regions` is specified, the snapshot is copied to those regions and registered there

### How Cloud-Init Runs

```
Power ON
   │
   ▼
BIOS/UEFI boot
   │
   ▼
Kernel starts → systemd → cloud-init.target
   │
   ├── cloud-init-local.service
   │   │  Detect datasource (NoCloud, EC2, GCE, Azure)
   │   │  Parse kernel cmdline for ds=nocloud-net
   │   │  Set up network config
   │   ▼
   ├── cloud-init.service
   │   │  Fetch user-data and meta-data from datasource
   │   │  Process cloud-config (YAML)
   │   │  Execute modules in order (from /etc/cloud/cloud.cfg):
   │   │    1. bootcmd — runs on every boot
   │   │    2. write_files — writes files to disk
   │   │    3. rsyslog — configure logging
   │   │    4. resolv_conf — configure DNS
   │   │    5. ntp — set up NTP
   │   │    6. users — create users and groups
   │   │    7. ssh_authorized_keys — deploy SSH keys
   │   │    8. packages — install packages
   │   │    9. runcmd — run arbitrary commands
   │   │   10. ssh — configure SSH keys
   │   ▼
   ├── cloud-config.service
   │   │  Run final configuration modules
   │   ▼
   └── cloud-final.service
       │  Execute scripts in /var/lib/cloud/scripts/per-boot/
       │  Execute scripts in /var/lib/cloud/scripts/per-instance/
       │  Execute scripts in /var/lib/cloud/scripts/per-once/
       ▼
   Boot complete — instance ready
```

**Datasource detection order:**
1. NoCloud (seed from ISO/CDROM filesystem labeled `cidata`)
2. ConfigDrive (OpenStack)
3. EC2 (169.254.169.254 metadata endpoint)
4. GCE (metadata.google.internal)
5. Azure (168.63.129.16 wireserver)
6. Hetzner, CloudSigma, other cloud platforms

### Pre-Baked Images vs Post-Boot Configuration

| Aspect | Pre-Baked (Immutable) | Post-Boot (Mutable) |
|--------|----------------------|-------------------|
| Boot time | Fast (seconds) | Slow (minutes — installs/configures) |
| Reproducibility | Guaranteed identical | Depends on network, repos, timing |
| Security patches | In image | At boot (may use outdated packages temporarily) |
| Complexity | More complex build pipeline | Simpler launch process |
| Rollback | Instant (re-deploy old image) | Slow (re-run config) |
| Debugging | Launch test instance | SSH into running instance |
| Image sprawl | Need to manage versions | One base image for everything |
| Config changes | Require image rebuild | Runtime userdata can change |
| Dependency on external services | Only during build | At every boot (repo servers, CM server) |

### Security Model of Immutable Deployment

No SSH access to production:
- Port 22 is closed in security groups
- No SSH keys deployed in the image
- No user accounts with login shells
- `PermitRootLogin no` and `PasswordAuthentication no`

**How to manage without SSH:**
- **Debugging**: Launch a separate instance from the same image in a sandbox VPC
- **Logs**: Centralized logging (CloudWatch, ELK, Loki) — never SSH to read logs
- **Metrics**: CloudWatch, Prometheus, Datadog — never SSH to check disk/memory
- **Configuration**: Userdata at boot, environment variables, config management
- **Shell access**: AWS SSM Session Manager (audited, no SSH key needed) for rare emergencies
- **Serial console**: AWS EC2 Serial Console for kernel-level debugging

**Security benefits:**
- No attack surface from SSH daemon
- No SSH key management (no lost keys, no rotated keys)
- No lateral movement — attacker can't SSH from one instance to another
- Every instance starts from a known good state — no persistent malware
- Immutable means no persistent compromise — terminate the instance, the malware is gone
- Audit trail — every change goes through the image pipeline

---

## 14. Command Reference

### Packer Commands

| Command | Description |
|---------|-------------|
| `packer version` | Show Packer version |
| `packer init <template>` | Initialize template (download plugins) |
| `packer fmt <template>` | Format HCL2 template |
| `packer validate <template>` | Validate template syntax |
| `packer build <template>` | Build image from template |
| `packer build -var "key=value" <template>` | Build with variable override |
| `packer build -var-file=vars.hcl <template>` | Build with variable file |
| `packer build -debug <template>` | Build in debug mode (pause between steps) |
| `packer build -on-error=ask <template>` | Prompt on error |
| `packer build -on-error=abort <template>` | Abort on error (leave instance running) |
| `packer build -machine-readable <template>` | Output machine-readable (for CI) |
| `packer build -parallel-builds=N <template>` | Build N images in parallel |
| `packer build -timestamp-ui <template>` | Add timestamps to output |
| `packer console <template>` | Interactive HCL console (test expressions) |
| `packer inspect <template>` | Show components of template |

### Plugin Commands

```bash
# List installed plugins
packer plugins installed

# Install specific plugin version
packer plugins install github.com/hashicorp/amazon v1.3.0
```

### Common Source Attributes (amazon-ebs)

| Attribute | Description |
|-----------|-------------|
| `region` | AWS region |
| `source_ami` | Base AMI ID |
| `source_ami_filter` | Filter to find base AMI |
| `instance_type` | EC2 instance type |
| `ssh_username` | SSH user for the AMI |
| `ssh_interface` | `public_ip`, `private_ip`, `session_manager` |
| `ami_name` | Resulting AMI name |
| `ami_description` | AMI description |
| `ami_regions` | Regions to copy AMI to |
| `ami_users` | AWS account IDs to share with |
| `ami_groups` | `all` for public, empty for private |
| `tags` | Tags for the AMI |
| `snapshot_tags` | Tags for the snapshots |
| `encrypt_boot` | Encrypt root volume |
| `kms_key_id` | KMS key for encryption |
| `launch_block_device_mappings` | EBS volume config |
| `subnet_id` | Specific subnet to launch in |
| `associate_public_ip_address` | Allocate public IP |
| `iam_instance_profile` | IAM role for builder |

### Common Provisioners

| Provisioner | Description |
|-------------|-------------|
| `shell` | Run shell commands or scripts |
| `file` | Upload files |
| `ansible` | Run Ansible playbook locally |
| `ansible-remote` | Run Ansible on target |
| `chef-client` | Run Chef client |
| `salt-masterless` | Apply Salt states |
| `puppet-masterless` | Apply Puppet manifests |
| `powershell` | Run PowerShell (Windows) |
| `windows-restart` | Reboot Windows (and wait) |
| `breakpoint` | Pause for debugging |
| `shell-local` | Run command on Packer host |

### Common Post-Processors

| Post-Processor | Description |
|----------------|-------------|
| `manifest` | Write build metadata to JSON |
| `vagrant` | Package as Vagrant box |
| `docker-tag` | Tag Docker image |
| `docker-push` | Push Docker image to registry |
| `compress` | Compress artifact |
| `checksum` | Generate checksum file |
| `artifice` | Attach external artifact |

### Variable Precedence (lowest to highest)

1. Default value in `variable` block
2. `packer build -var-file=auto.pkrvars.hcl` (auto-loaded)
3. `*.auto.pkrvars.hcl` files
4. `packer build -var-file=file.hcl`
5. Environment variables (`PKR_VAR_name`)
6. `packer build -var "name=value"`

---

## 15. Self-Test

**15 questions. Score 12/15 correct = ready for Part 56.**

1. **What is the fundamental difference between mutable and immutable infrastructure?**
   - A) Mutable uses VMs, immutable uses containers
   - B) Mutable modifies instances in place; immutable replaces instances
   - C) Mutable is cheaper; immutable is more expensive
   - D) Mutable uses Linux; immutable uses Windows

2. **What does Packer do?**
   - A) Orchestrates containers across clusters
   - B) Creates identical machine images for multiple platforms
   - C) Manages cloud resources declaratively
   - D) Monitors infrastructure metrics

3. **Which file format does Packer use for templates?**
   - A) JSON
   - B) YAML
   - C) HCL2 (.pkr.hcl)
   - D) TOML

4. **What is the purpose of a provisioner in Packer?**
   - A) To create the source instance
   - B) To configure the instance during build
   - C) To package the final artifact
   - D) To authenticate with cloud providers

5. **Which builder would you use to create an AMI in AWS?**
   - A) `googlecompute`
   - B) `azure-arm`
   - C) `amazon-ebs`
   - D) `qemu`

6. **Why should SSH keys never be baked into a golden image?**
   - A) They expire too quickly
   - B) Every instance would have the same host key
   - C) They take up too much space
   - D) SSH should use passwords instead

7. **What is the role of cloud-init on first boot?**
   - A) To install the operating system
   - B) To run userdata scripts and configure the instance
   - C) To create the golden image
   - D) To terminate unused instances

8. **How does Packer create an AMI?**
   - A) By modifying the source AMI directly
   - B) By starting an instance, provisioning it, taking an EBS snapshot, and registering it
   - C) By copying the instance's root filesystem to an S3 bucket
   - D) By running a Dockerfile on the build host

9. **What is the "bake vs fry" concept?**
   - A) Bake = everything in image vs fry = heavy post-boot config
   - B) Bake = Docker vs fry = VM
   - C) Bake = dev vs fry = prod
   - D) Bake = AWS vs fry = Azure

10. **What is the recommended strategy for handling database state in immutable infrastructure?**
    - A) Store databases on the instance's EBS volume
    - B) Use external managed databases (RDS, Aurora)
    - C) Bake the database into the image
    - D) Use SQLite on ephemeral storage

11. **Which of the following should be cleaned up before finalizing an image?**
    - A) The application source code
    - B) SSH host keys and authorized_keys
    - C) The nginx binary
    - D) The /etc/hosts file

12. **What is the purpose of the `-debug` flag in `packer build`?**
    - A) To log verbose output
    - B) To pause between steps and allow SSH inspection
    - C) To run builds in parallel
    - D) To disable cleanup of the build instance

13. **How are images versioned in a production pipeline?**
    - A) Only by timestamp
    - B) By semantic version, commit hash, and/or timestamp
    - C) Random UUID
    - D) By the base AMI ID

14. **What is a blue/green deployment?**
    - A) Deploying to blue servers, then green servers
    - B) Running two environments (blue and green) and switching traffic between them
    - C) Deploying to the same instances with a different color label
    - D) Deploying to one region, then another

15. **Why do immutable deployments close SSH access to production?**
    - A) To save on licensing costs
    - B) To reduce attack surface and enforce changes through the pipeline
    - C) Because SSH is not supported on cloud instances
    - D) To make debugging more challenging

**Answer Key:**
1. B  2. B  3. C  4. B  5. C  6. B  7. B  8. B  9. A  10. B  11. B  12. B  13. B  14. B  15. B

**Score:** ____ / 15

---

## What's Coming in Part 56

**Part 56: Observability Deep Dive — Prometheus, Grafana, Loki, OpenTelemetry**

We will cover:
- Metrics collection with Prometheus (service discovery, recording rules, alerting rules)
- Visualization with Grafana (dashboards, datasources, alerting, annotations)
- Log aggregation with Loki (logQL, log parsing, multi-tenancy)
- Distributed tracing with OpenTelemetry (traces, spans, context propagation)
- **Hands-on**: Full observability stack deployment with docker-compose and Kubernetes
- **Deep understanding**: How Prometheus pulls metrics (pull vs push), how Loki stores logs (chunks, indexes), how OpenTelemetry sampling works

---

```
*Linux SysAdmin Course | Part 55 of ∞ | Reverse Engineering Approach*
*Previous → Part 54: Advanced Configuration Management*
*Next → Part 56: Observability Deep Dive*
```

[← Previous](part54.md) | [Next →](part56.md)
