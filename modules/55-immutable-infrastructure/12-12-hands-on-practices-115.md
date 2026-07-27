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



---

[← Previous](11-11-troubleshooting-immutable.md) | [↑ Index](index.md) | [Next →](13-13-deep-understanding.md)
