# 🐧 Linux System Administrator — Complete Course
## Part 50 of ∞: Cloud Infrastructure — AWS, GCP, Azure Fundamentals for Sysadmins

---

> **Reverse Engineering Approach:** Before cloud, sysadmins racked servers, ran cables, configured SANs, and waited weeks for hardware. Cloud flipped the model — instead of managing physical infrastructure, you manage API calls. AWS, GCP, and Azure are just a CLI command away. Understanding how they work means understanding how to manage infrastructure at scale. This part covers all three major providers so you can operate in any environment.

---

## 🎯 What You Will Achieve in Part 50

By the end of this part, you will:

- Understand cloud computing models (IaaS, PaaS, SaaS, public/private/hybrid)
- Master the AWS CLI (aws configure, IAM, EC2, S3, VPC)
- Master the GCP CLI (gcloud init, Compute Engine, Cloud Storage, VPC)
- Master the Azure CLI (az login, VMs, Blob Storage, VNet)
- Launch and manage compute instances on all three clouds
- Create and manage cloud storage (S3, GCS, Azure Blob)
- Design and configure virtual networks (VPC, subnets, NAT, peering)
- Implement IAM security (users, groups, roles, policies, service accounts)
- Use cloud-native SSH access (SSM Session Manager, IAP, Bastion)
- Manage cloud costs with budgets, tags, and reserved instances
- Compare equivalent services across AWS, GCP, and Azure
- Complete **15 hands-on practices**

---

## 🔍 Section 1: Cloud Computing Models

### IaaS vs PaaS vs SaaS

```
┌─────────────────────────────────────────────────────────┐
│                   YOU MANAGE            PROVIDER MANAGES │
├─────────────────────────────────────────────────────────┤
│ IaaS  │ Applications Data Runtime OS │ Virtualization   │
│       │ Middleware Container          │ Servers Storage  │
│       │                              │ Networking       │
├─────────────────────────────────────────────────────────┤
│ PaaS  │ Applications Data            │ Runtime OS       │
│       │                              │ Middleware       │
│       │                              │ Virtualization   │
│       │                              │ Servers Storage  │
│       │                              │ Networking       │
├─────────────────────────────────────────────────────────┤
│ SaaS  │                            │ Everything        │
│       │                            │ (you just use it) │
└─────────────────────────────────────────────────────────┘
```

**IaaS (Infrastructure as a Service):** You get virtualized hardware — CPU, RAM, storage, networking. You manage the OS, middleware, runtime, and apps. AWS EC2, GCP Compute Engine, Azure VMs.

**PaaS (Platform as a Service):** You deploy code without managing the underlying infrastructure. AWS Elastic Beanstalk, GCP App Engine, Azure App Services.

**SaaS (Software as a Service):** Ready-to-use software. AWS WorkMail, GCP Workspace, Microsoft 365.

### Deployment Models

| Model | Description | Example Use |
|-------|-------------|-------------|
| Public Cloud | Shared infrastructure over internet | AWS, GCP, Azure |
| Private Cloud | Dedicated to one organization | OpenStack, VMware on-prem |
| Hybrid Cloud | Mix of public and private | Bursting, data residency |
| Multi-Cloud | Using multiple public clouds | Redundancy, best-of-breed |

### OPEX vs CAPEX

```
CAPEX (Traditional):
  Buy servers:    $50,000 upfront
  Rack space:     $2,000/month
  Cooling/Power:  $1,500/month
  Staff:          $10,000/month
  → You pay whether you use it or not

OPEX (Cloud):
  Per hour:       $0.50 for an instance
  Per GB:         $0.023 for storage
  Per request:    $0.0000004 per API call
  → You pay only for what you use
```

### Regions and Availability Zones

```
Region (us-east-1)
├── Availability Zone us-east-1a
│   ├── Data center cluster 1
│   └── Data center cluster 2
├── Availability Zone us-east-1b
│   ├── Data center cluster 3
│   └── Data center cluster 4
└── Availability Zone us-east-1c
    ├── Data center cluster 5
    └── Data center cluster 6
```

**Region:** Geographic area with 2+ availability zones. AWS: us-east-1, eu-west-2, ap-southeast-1. GCP: us-central1, europe-west1, asia-east1. Azure: eastus, westeurope, southeastasia.

**Availability Zone (AZ):** Isolated data center within a region. Each AZ has independent power, cooling, networking. AZs are connected by low-latency fiber.

**Global vs Regional vs Zonal resources:**
- **Global:** IAM users, CloudFront CDN, DNS (Route 53)
- **Regional:** VPC, S3 buckets, security groups
- **Zonal:** EC2 instances, EBS volumes (tied to one AZ)

```bash
# List AWS regions
aws ec2 describe-regions

# List GCP regions
gcloud compute regions list

# List Azure regions
az account list-locations -o table
```

---

## 🔍 Section 2: AWS CLI

### Installation

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y awscli

# RHEL/CentOS/Fedora
sudo dnf install -y awscli

# Verify
aws --version
# aws-cli/2.x.x Python/3.x.x Linux/...

# Or install v2 manually (recommended)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configuration

```bash
# Interactive config
aws configure

# It prompts for:
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name: us-east-1
# Default output format: json

# Configuration is stored in:
cat ~/.aws/config
cat ~/.aws/credentials

# Config file format:
# [default]
# region = us-east-1
# output = json

# Credentials file format:
# [default]
# aws_access_key_id = AKIAIOSFODNN7EXAMPLE
# aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Verifying Identity

```bash
# Who am I?
aws sts get-caller-identity

# Output:
# {
#     "UserId": "AIDAEXAMPLE123456789",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/admin"
# }
```

### Multiple Profiles

```bash
# Configure a named profile
aws configure --profile dev
aws configure --profile prod

# Use a specific profile
aws sts get-caller-identity --profile dev

# List profiles
aws configure list-profiles

# Use profile in commands (--profile flag)
aws s3 ls --profile prod

# Or set env variable
export AWS_PROFILE=dev
aws s3 ls  # Uses dev profile
```

### IAM Roles from EC2 (Instance Metadata)

```bash
# When running on EC2 with an IAM role attached:
# No credentials file needed! AWS CLI automatically gets temp credentials

# Retrieve instance metadata
curl http://169.254.169.254/latest/meta-data/

# Get the IAM role name
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Get temporary credentials from the role
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/MyRoleName/

# Instance metadata version 2 (IMDSv2) - more secure
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/
```

### Environment Variables (Override Everything)

```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-west-2
export AWS_DEFAULT_OUTPUT=json

aws sts get-caller-identity  # Uses env vars

# Also valid:
export AWS_SESSION_TOKEN=...  # For temporary credentials (STS)
```

---

## 🔍 Section 3: GCP CLI (gcloud)

### Installation

```bash
# Debian/Ubuntu
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
  https://packages.cloud.google.com/apt cloud-sdk main" | \
  sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo apt update && sudo apt install -y google-cloud-sdk

# Verify
gcloud --version

# RHEL/CentOS/Fedora
sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << 'EOF'
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo dnf install -y google-cloud-sdk
```

### Initialization and Authentication

```bash
# Initialize gcloud (first run)
gcloud init

# This will:
# 1. Open a browser for authentication (or provide a code)
# 2. Let you pick a project
# 3. Set default region and zone

# Or authenticate headless (no browser)
gcloud auth login --no-launch-browser
# Follow the URL to get a verification code

# List accounts
gcloud auth list

# List projects
gcloud projects list

# Set configuration
gcloud config set project my-project-id
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# View configuration
gcloud config list
gcloud config configurations list

# Create named configurations
gcloud config configurations create dev
gcloud config configurations activate dev
gcloud config set project dev-project-123
```

### Application Default Credentials

```bash
# For applications/libraries to authenticate
gcloud auth application-default login

# Stores credentials in:
# ~/.config/gcloud/application_default_credentials.json

# This is used by:
# - Google Cloud client libraries (Python, Go, Java, etc.)
# - Tools like Terraform, Packer
# - gcloud storage, bq, etc.

# Service account impersonation
gcloud auth application-default login \
  --impersonate-service-account=sa-name@project.iam.gserviceaccount.com
```

### Service Account Key Files

```bash
# Export a service account key
gcloud iam service-accounts keys create ~/sa-key.json \
  --iam-account=my-sa@my-project.iam.gserviceaccount.com

# Use with gcloud
gcloud auth activate-service-account \
  --key-file=~/sa-key.json

# Use with environment variable (works with all Google SDK tools)
export GOOGLE_APPLICATION_CREDENTIALS=~/sa-key.json
```

### GCP Resource Hierarchy

```
Organization (example.com)
└── Folder (Engineering)
    └── Folder (Production)
        └── Project (my-app-prod)
            ├── VPC
            ├── Compute Engine instances
            ├── Cloud Storage buckets
            └── IAM policies
```

---

## 🔍 Section 4: Azure CLI (az)

### Installation

```bash
# Debian/Ubuntu
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Or manually:
sudo apt update
sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ \
  $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt update && sudo apt install -y azure-cli

# RHEL/CentOS/Fedora
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo

sudo dnf install -y azure-cli

# Verify
az --version
```

### Authentication

```bash
# Interactive login (opens browser)
az login

# Headless login
az login --use-device-code
# Follow the URL and enter the code

# Login with service principal (non-interactive)
az login --service-principal \
  --username APP_ID \
  --password PASSWORD \
  --tenant TENANT_ID

# Login with managed identity (Azure VM)
az login --identity
```

### Account Management

```bash
# List subscriptions
az account list -o table

# Show current subscription
az account show

# Set subscription
az account set --subscription "My Subscription Name"
az account set --subscription SUBSCRIPTION_ID

# Create and manage multiple accounts
az account list --query "[?isDefault]" -o table

# Clear cached credentials
az logout
```

### Azure CLI Configuration

```bash
# Interactive config
az configure

# Set defaults
az config set core.output=table
az config set defaults.location=eastus
az config set defaults.group=myResourceGroup

# View config
az config get defaults

# Config file location:
cat ~/.azure/config
```

### Azure Resource Hierarchy

```
Management Group (Root)
└── Management Group (Production)
    └── Subscription (Pay-As-You-Go)
        └── Resource Group (my-app-rg)
            ├── Virtual Network
            ├── Virtual Machine
            ├── Storage Account
            └── Network Security Group
```

---

## 🔍 Section 5: Compute

### AWS EC2

#### Instance Types

```
General Purpose:   t3.micro, t3.medium, m5.large   (balanced)
Compute Optimized: c5.large, c5n.xlarge, c6i.2xlarge  (CPU-heavy)
Memory Optimized:  r5.large, x1e.xlarge, z1d.large  (RAM-heavy)
Storage Optimized: i3.large, d2.xlarge, i3en.2xlarge  (SSD-heavy)
GPU:               p3.2xlarge, g4dn.xlarge, p4d.24xlarge  (ML/rendering)
```

#### AMIs (Amazon Machine Images)

```bash
# Search for Ubuntu 22.04 LTS AMI
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table

# Common owners:
# 099720109477 = Canonical (Ubuntu)
# 309956199498 = Red Hat (RHEL)
# 137112412989 = Amazon (Amazon Linux)
# 125523088429 = Debian
```

#### Launching an Instance

```bash
# Create a key pair
aws ec2 create-key-pair \
  --key-name my-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/my-key.pem
chmod 400 ~/.ssh/my-key.pem

# Create a security group
aws ec2 create-security-group \
  --group-name my-sg \
  --description "SSH access"

# Add SSH rule
aws ec2 authorize-security-group-ingress \
  --group-name my-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --key-name my-key \
  --security-groups my-sg \
  --user-data file://userdata.sh

# userdata.sh example:
# #!/bin/bash
# apt update && apt install -y nginx
# systemctl enable --now nginx
```

#### Userdata Scripts

```bash
cat > userdata.sh << 'EOF'
#!/bin/bash
exec > /var/log/userdata.log 2>&1
set -ex

apt update
apt install -y nginx
echo "<h1>Deployed via EC2 Userdata</h1>" > /var/www/html/index.html
systemctl enable --now nginx
EOF

aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --key-name my-key \
  --security-groups my-sg \
  --user-data file://userdata.sh
```

#### Managing Instances

```bash
# List instances
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress]' \
  --output table

# Stop an instance
aws ec2 stop-instances --instance-ids i-0abcdef1234567890

# Start an instance
aws ec2 start-instances --instance-ids i-0abcdef1234567890

# Terminate an instance
aws ec2 terminate-instances --instance-ids i-0abcdef1234567890

# Get instance metadata
aws ec2 describe-instances \
  --instance-ids i-0abcdef1234567890 \
  --query 'Reservations[0].Instances[0]'
```

#### Security Groups (Firewall at Instance Level)

```bash
# Create security group
aws ec2 create-security-group \
  --group-name web-sg \
  --description "Web server security group" \
  --vpc-id vpc-12345678

# Add inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Add rule referencing another security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 3306 \
  --source-group sg-87654321  # Allow MySQL from app tier
```

### GCP Compute Engine

#### Machine Types

```
General Purpose:   e2-micro, e2-small, e2-medium, n2-standard-2
CPU Optimized:     c2-standard-4, c2-standard-8
Memory Optimized:  m2-megamem-416, n2-highmem-32
GPU:               g2-standard-4 (with NVIDIA L4), a2-highgpu-2g
Predefined:        n1-standard-1 (1 vCPU, 3.75 GB)
Custom:            custom-4-8192 (4 vCPU, 8 GB RAM)
```

#### Images

```bash
# List available images
gcloud compute images list

# List Ubuntu images specifically
gcloud compute images list \
  --project ubuntu-os-cloud \
  --no-standard-images

# Common image projects:
# ubuntu-os-cloud, centos-cloud, debian-cloud, rhel-cloud
# cos-cloud (Container-Optimized OS), windows-cloud
```

#### Creating an Instance

```bash
# Create a VM with startup script
gcloud compute instances create my-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --tags=http-server \
  --metadata-from-file startup-script=startup.sh

# startup.sh example:
cat > startup.sh << 'EOF'
#!/bin/bash
apt update
apt install -y apache2
echo "<h1>Deployed via GCP Startup Script</h1>" > /var/www/html/index.html
systemctl enable --now apache2
EOF

# Create without external IP
gcloud compute instances create private-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --no-address
```

#### Firewall Rules

```bash
# Create a firewall rule to allow HTTP
gcloud compute firewall-rules create allow-http \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# Allow SSH from specific IP
gcloud compute firewall-rules create allow-ssh-admin \
  --network=default \
  --allow=tcp:22 \
  --source-ranges=203.0.113.0/24

# List firewall rules
gcloud compute firewall-rules list

# Delete a firewall rule
gcloud compute firewall-rules delete allow-http
```

#### Managing Instances

```bash
# List instances
gcloud compute instances list

# SSH into instance
gcloud compute ssh my-instance --zone=us-central1-a

# Stop
gcloud compute instances stop my-instance --zone=us-central1-a

# Start
gcloud compute instances start my-instance --zone=us-central1-a

# Delete
gcloud compute instances delete my-instance --zone=us-central1-a

# Get serial console output
gcloud compute instances get-serial-port-output my-instance \
  --zone=us-central1-a

# Add/remove tags
gcloud compute instances add-tags my-instance \
  --tags=https-server \
  --zone=us-central1-a

gcloud compute instances remove-tags my-instance \
  --tags=http-server \
  --zone=us-central1-a
```

### Azure Virtual Machines

#### VM Sizes

```
General Purpose:   Standard_B1s, Standard_D2s_v3, Standard_D4s_v5
Compute Optimized: Standard_F2s_v2, Standard_F4s_v2
Memory Optimized:  Standard_E2s_v3, Standard_E64-3s_v5
Storage Optimized: Standard_L8s_v3, Standard_L32s_v3
GPU:               Standard_NC6s_v3, Standard_ND40rs_v2
```

#### Creating a VM

```bash
# Create a resource group (required first)
az group create \
  --name myResourceGroup \
  --location eastus

# Create a VM with custom data
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --custom-data customdata.sh

# customdata.sh (must be base64 encoded, but az handles this)
cat > customdata.sh << 'EOF'
#!/bin/bash
apt update
apt install -y nginx
echo "<h1>Deployed via Azure Custom Data</h1>" > /var/www/html/index.html
systemctl enable --now nginx
EOF

# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

#### Managed Disks

```bash
# Create a managed disk
az disk create \
  --resource-group myResourceGroup \
  --name myDataDisk \
  --size-gb 100 \
  --sku StandardSSD_LRS

# Attach to VM
az vm disk attach \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name myDataDisk \
  --new

# List disks
az disk list --resource-group myResourceGroup -o table

# Snapshot a disk
az snapshot create \
  --resource-group myResourceGroup \
  --name myDiskSnapshot \
  --source myDataDisk

# Create disk from snapshot
az disk create \
  --resource-group myResourceGroup \
  --name restoredDisk \
  --source myDiskSnapshot
```

#### Network Security Groups (NSGs)

```bash
# Create NSG
az network nsg create \
  --resource-group myResourceGroup \
  --name myNSG

# Create rules
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name AllowSSH \
  --protocol tcp \
  --priority 1000 \
  --destination-port-ranges 22 \
  --access Allow \
  --source-address-prefixes 203.0.113.0/24

az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name AllowHTTP \
  --protocol tcp \
  --priority 1010 \
  --destination-port-ranges 80 \
  --access Allow \
  --source-address-prefixes '*'

# Associate NSG with subnet
az network vnet subnet update \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name default \
  --network-security-group myNSG
```

#### Managing VMs

```bash
# List VMs
az vm list -o table

# Show details
az vm show --resource-group myResourceGroup --name myVM

# Stop (deallocate — stops billing)
az vm deallocate --resource-group myResourceGroup --name myVM

# Start
az vm start --resource-group myResourceGroup --name myVM

# Restart
az vm restart --resource-group myResourceGroup --name myVM

# Delete
az vm delete --resource-group myResourceGroup --name myVM

# Run command on VM (no SSH needed)
az vm run-command invoke \
  --resource-group myResourceGroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts "uptime && df -h"
```

---

## 🔍 Section 6: Storage

### AWS S3 (Simple Storage Service)

#### Buckets and Objects

```bash
# Create a bucket (bucket names are GLOBALLY unique)
aws s3 mb s3://my-unique-bucket-name-12345

# List buckets
aws s3 ls

# Upload an object
aws s3 cp myfile.txt s3://my-unique-bucket-12345/
aws s3 cp /var/log/syslog s3://my-unique-bucket-12345/logs/

# Download an object
aws s3 cp s3://my-unique-bucket-12345/myfile.txt ./

# List objects
aws s3 ls s3://my-unique-bucket-12345/
aws s3 ls s3://my-unique-bucket-12345/logs/

# Sync a directory (like rsync for S3)
aws s3 sync ./local-dir s3://my-unique-bucket-12345/backup/

# Delete an object
aws s3 rm s3://my-unique-bucket-12345/oldfile.txt

# Delete a bucket (must be empty)
aws s3 rb s3://my-unique-bucket-12345/
```

#### Versioning

```bash
# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-unique-bucket-12345 \
  --versioning-configuration Status=Enabled

# List object versions
aws s3api list-object-versions \
  --bucket my-unique-bucket-12345 \
  --prefix myfile.txt

# Download a specific version
aws s3api get-object \
  --bucket my-unique-bucket-12345 \
  --key myfile.txt \
  --version-id VERSION_ID \
  myfile-restored.txt

# Delete a specific version (permanent)
aws s3api delete-object \
  --bucket my-unique-bucket-12345 \
  --key myfile.txt \
  --version-id VERSION_ID

# Suspend versioning
aws s3api put-bucket-versioning \
  --bucket my-unique-bucket-12345 \
  --versioning-configuration Status=Suspended
```

#### Lifecycle Policies

```bash
cat > lifecycle.json << 'EOF'
{
  "Rules": [
    {
      "Id": "Transition-to-IA",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "logs/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    },
    {
      "Id": "Expire-old-versions",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket my-unique-bucket-12345 \
  --lifecycle-configuration file://lifecycle.json
```

#### Storage Classes

```
S3 Standard:          Frequent access, 11x9s durability, millisecond access
S3 Intelligent-Tiering: Auto-optimizes cost, monitoring fee
S3 Standard-IA:       Infrequent access, lower cost, retrieval fee
S3 One Zone-IA:       Infrequent access, single AZ, lower cost
S3 Glacier:           Archival, 1-5 min retrieval, lowest cost
S3 Glacier Deep Archive: Archival, 12-hour retrieval, absolute lowest
S3 Express One Zone:  Single AZ, very low latency, 10x faster
```

#### Presigned URLs

```bash
# Generate a presigned URL for temporary access (e.g., 1 hour)
aws s3 presign s3://my-unique-bucket-12345/myfile.txt \
  --expires-in 3600

# From Python SDK
python3 -c "
import boto3
url = boto3.client('s3').generate_presigned_url(
    'get_object',
    Params={'Bucket': 'my-unique-bucket-12345', 'Key': 'myfile.txt'},
    ExpiresIn=3600
)
print(url)
"

# Anyone with this URL can download the file for 1 hour
```

### GCP Cloud Storage

#### Buckets and Objects

```bash
# Create a bucket (globally unique)
gcloud storage buckets create gs://my-unique-bucket-67890 \
  --location=US \
  --default-storage-class=STANDARD

# Use the newer gcloud storage (recommended) or gsutil

# Upload files
gcloud storage cp myfile.txt gs://my-unique-bucket-67890/

# Or use gsutil (legacy)
gsutil cp myfile.txt gs://my-unique-bucket-67890/

# Upload with specific storage class
gsutil cp -s NEARLINE myfile.txt gs://my-unique-bucket-67890/

# Download
gcloud storage cp gs://my-unique-bucket-67890/myfile.txt ./

# List objects
gcloud storage ls gs://my-unique-bucket-67890/
gsutil ls gs://my-unique-bucket-67890/

# Rsync directory
gsutil rsync -r ./local-dir gs://my-unique-bucket-67890/backup/

# Delete
gcloud storage rm gs://my-unique-bucket-67890/oldfile.txt
```

#### Object Lifecycle Management

```bash
cat > lifecycle-config.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "NEARLINE"
        },
        "condition": {
          "age": 30,
          "matchesPrefix": ["logs/"]
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "COLDLINE"
        },
        "condition": {
          "age": 90
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "ARCHIVE"
        },
        "condition": {
          "age": 365
        }
      },
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "age": 730
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle-config.json \
  gs://my-unique-bucket-67890/

# View lifecycle config
gsutil lifecycle get gs://my-unique-bucket-67890/
```

#### IAM on Buckets

```bash
# Grant a service account object viewer access
gsutil iam ch \
  serviceAccount:my-sa@my-project.iam.gserviceaccount.com:roles/storage.objectViewer \
  gs://my-unique-bucket-67890/

# Grant public read access
gsutil iam ch allUsers:roles/storage.objectViewer \
  gs://my-unique-bucket-67890/

# View current IAM
gsutil iam get gs://my-unique-bucket-67890/
```

#### Storage Classes

```
STANDARD:  Frequently accessed data, multi-region or regional
NEARLINE:  Accessed < once per 30 days, lower cost, retrieval fee
COLDLINE:  Accessed < once per 90 days, even lower cost, retrieval fee
ARCHIVE:   Accessed < once per 365 days, lowest cost, >1 hour retrieval
Autoclass: Automatically transitions objects based on access patterns
```

### Azure Blob Storage

#### Storage Accounts and Containers

```bash
# Create a storage account (globally unique)
az storage account create \
  --name myuniquestorage12345 \
  --resource-group myResourceGroup \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# List storage accounts
az storage account list -o table

# Get connection string
az storage account show-connection-string \
  --name myuniquestorage12345 \
  --resource-group myResourceGroup \
  --query connectionString

# Create a container (like a bucket)
az storage container create \
  --name mycontainer \
  --account-name myuniquestorage12345

# List containers
az storage container list \
  --account-name myuniquestorage12345 \
  -o table
```

#### Uploading and Downloading

```bash
# Upload a blob
az storage blob upload \
  --account-name myuniquestorage12345 \
  --container-name mycontainer \
  --name myfile.txt \
  --file myfile.txt

# Upload with specific access tier
az storage blob upload \
  --account-name myuniquestorage12345 \
  --container-name mycontainer \
  --name archive.log \
  --file archive.log \
  --tier Cool

# List blobs
az storage blob list \
  --account-name myuniquestorage12345 \
  --container-name mycontainer \
  -o table

# Download a blob
az storage blob download \
  --account-name myuniquestorage12345 \
  --container-name mycontainer \
  --name myfile.txt \
  --file downloaded.txt

# Delete a blob
az storage blob delete \
  --account-name myuniquestorage12345 \
  --container-name mycontainer \
  --name oldfile.txt
```

#### Access Tiers

```
Hot:  Frequent access, highest storage cost, no retrieval cost
Cool: Infrequent access (< 30 days), lower storage cost, retrieval fee
Cold: Rare access (< 90 days), even lower storage cost, higher retrieval fee
Archive: < 180 days access, lowest cost, up to 15-hour rehydration
```

#### SAS Tokens (Shared Access Signatures)

```bash
# Generate a SAS token for a container (1 hour expiry)
az storage container generate-sas \
  --account-name myuniquestorage12345 \
  --name mycontainer \
  --permissions rw \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ')

# Generate a SAS token for a specific blob
az storage blob generate-sas \
  --account-name myuniquestorage12345 \
  --container-name mycontainer \
  --name myfile.txt \
  --permissions r \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ')

# Use SAS URL to access (anyone with this URL can access for 1 hour)
# https://myuniquestorage12345.blob.core.windows.net/mycontainer/myfile.txt?sv=2020-04-08&se=...

# Account-level SAS (more powerful — use carefully)
az storage account generate-sas \
  --account-name myuniquestorage12345 \
  --permissions racwdl \
  --resource-types sco \
  --services b \
  --expiry $(date -u -d "1 day" '+%Y-%m-%dT%H:%MZ')
```

---

## 🔍 Section 7: Networking

### AWS VPC (Virtual Private Cloud)

#### VPC and Subnets

```bash
# Create a VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]'

# Create subnets
aws ec2 create-subnet \
  --vpc-id vpc-12345678 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-1a}]'

aws ec2 create-subnet \
  --vpc-id vpc-12345678 \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-1a}]'
```

#### Internet Gateway

```bash
# Create and attach Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id vpc-12345678

# Create a route table for public subnets
RTB_ID=$(aws ec2 create-route-table \
  --vpc-id vpc-12345678 \
  --query 'RouteTable.RouteTableId' \
  --output text)

# Add default route via IGW
aws ec2 create-route \
  --route-table-id $RTB_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Associate with public subnet
aws ec2 associate-route-table \
  --route-table-id $RTB_ID \
  --subnet-id subnet-public-1a
```

#### NAT Gateway

```bash
# Allocate Elastic IP
ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' \
  --output text)

# Create NAT Gateway in public subnet
NAT_ID=$(aws ec2 create-nat-gateway \
  --subnet-id subnet-public-1a \
  --allocation-id $ALLOC_ID \
  --query 'NatGateway.NatGatewayId' \
  --output text)

# Wait for it to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_ID

# Add route to private subnet route table
aws ec2 create-route \
  --route-table-id rtb-private \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_ID
```

#### VPC Peering

```bash
# Create peering connection
PEER_ID=$(aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-12345678 \
  --peer-vpc-id vpc-87654321 \
  --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
  --output text)

# Accept the peering (by the owner of the other VPC)
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id $PEER_ID

# Add routes in both VPC route tables
aws ec2 create-route \
  --route-table-id rtb-a \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id $PEER_ID

aws ec2 create-route \
  --route-table-id rtb-b \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id $PEER_ID
```

#### Security Groups vs NACLs

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY GROUPS          NACLs               │
├─────────────────────────────────────────────────────────────────┤
│ Level          Instance-level              Subnet-level         │
│ State          Stateful                    Stateless            │
│ Rules          Allow only                  Allow + Deny         │
│ Evaluation     All rules evaluated         Rule number order    │
│ Return traffic Auto-allowed                Must allow explicitly│
│ Use case       Per-instance firewall       Subnet-level defense │
└─────────────────────────────────────────────────────────────────┘
```

### GCP VPC

#### VPC and Subnets

```bash
# Create a custom VPC
gcloud compute networks create my-vpc \
  --subnet-mode=custom \
  --bgp-routing-mode=regional

# Create subnets
gcloud compute networks subnets create public-subnet \
  --network=my-vpc \
  --region=us-central1 \
  --range=10.0.1.0/24

gcloud compute networks subnets create private-subnet \
  --network=my-vpc \
  --region=us-central1 \
  --range=10.0.2.0/24

# List subnets
gcloud compute networks subnets list

# Create a VM in a specific subnet
gcloud compute instances create web-server \
  --zone=us-central1-a \
  --subnet=public-subnet
```

#### Firewall Rules

```bash
# Allow HTTP from anywhere
gcloud compute firewall-rules create allow-http \
  --network=my-vpc \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0

# Allow SSH from specific IP only
gcloud compute firewall-rules create allow-ssh-admin \
  --network=my-vpc \
  --allow=tcp:22 \
  --source-ranges=203.0.113.0/24

# Allow internal traffic between subnets
gcloud compute firewall-rules create allow-internal \
  --network=my-vpc \
  --allow=tcp:0-65535,udp:0-65535,icmp \
  --source-ranges=10.0.0.0/16

# Deny all inbound from a specific IP (priority matters, lower = higher)
gcloud compute firewall-rules create deny-bad-actor \
  --network=my-vpc \
  --deny=tcp:0-65535 \
  --source-ranges=198.51.100.0/24 \
  --priority=100

# List firewall rules
gcloud compute firewall-rules list --network=my-vpc
```

#### Cloud NAT

```bash
# Create a Cloud Router (required for Cloud NAT)
gcloud compute routers create my-router \
  --network=my-vpc \
  --region=us-central1

# Create Cloud NAT (allows private instances to reach internet)
gcloud compute routers nats create my-nat \
  --router=my-router \
  --region=us-central1 \
  --nat-external-ip-pool=auto-allocate \
  --nat-all-subnet-ip-ranges \
  --enable-logging

# Verify Cloud NAT
gcloud compute routers nats list \
  --router=my-router \
  --region=us-central1
```

#### VPC Peering

```bash
# Create peering between two VPCs
gcloud compute networks peerings create peer-to-vpc-b \
  --network=my-vpc \
  --peer-network=other-vpc \
  --peer-project=other-project-id

# On the other side (other project):
gcloud compute networks peerings create peer-to-vpc-a \
  --network=other-vpc \
  --peer-network=my-vpc \
  --peer-project=original-project-id

# Verify
gcloud compute networks peerings list --network=my-vpc
```

### Azure VNet

#### Virtual Network and Subnets

```bash
# Create VNet
az network vnet create \
  --resource-group myResourceGroup \
  --name myVNet \
  --address-prefixes 10.0.0.0/16 \
  --location eastus

# Create subnets
az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name public-subnet \
  --address-prefixes 10.0.1.0/24

az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name private-subnet \
  --address-prefixes 10.0.2.0/24

# List subnets
az network vnet subnet list \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  -o table
```

#### NSG Rules

```bash
# Create NSG
az network nsg create \
  --resource-group myResourceGroup \
  --name webNSG

# Create inbound rules
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name webNSG \
  --name AllowHTTP \
  --priority 100 \
  --protocol Tcp \
  --destination-port-ranges 80 \
  --access Allow \
  --source-address-prefixes '*' \
  --direction Inbound

az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name webNSG \
  --name AllowHTTPS \
  --priority 110 \
  --protocol Tcp \
  --destination-port-ranges 443 \
  --access Allow \
  --source-address-prefixes '*' \
  --direction Inbound

# Deny all other inbound (implicit deny, but explicit is clearer)
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name webNSG \
  --name DenyAllInbound \
  --priority 200 \
  --protocol '*' \
  --destination-port-ranges '*' \
  --access Deny \
  --source-address-prefixes '*' \
  --direction Inbound

# Associate NSG with subnet
az network vnet subnet update \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name public-subnet \
  --network-security-group webNSG
```

#### VNet Peering

```bash
# Create peering from VNet A to VNet B
az network vnet peering create \
  --resource-group myResourceGroup \
  --name peerAtoB \
  --vnet-name myVNet \
  --remote-vnet /subscriptions/SUB_ID/resourceGroups/otherRG/providers/Microsoft.Network/virtualNetworks/otherVNet \
  --allow-vnet-access

# On the other side (must be done separately)
az network vnet peering create \
  --resource-group otherRG \
  --name peerBtoA \
  --vnet-name otherVNet \
  --remote-vnet /subscriptions/SUB_ID/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVNet \
  --allow-vnet-access

# Verify peering
az network vnet peering list \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  -o table
```

#### Azure Firewall

```bash
# Create a public IP for Azure Firewall
az network public-ip create \
  --resource-group myResourceGroup \
  --name fw-pip \
  --sku Standard \
  --location eastus

# Create Azure Firewall
az network firewall create \
  --resource-group myResourceGroup \
  --name myFirewall \
  --location eastus

# Configure firewall IP config
az network firewall ip-config create \
  --resource-group myResourceGroup \
  --firewall-name myFirewall \
  --name FWConfig \
  --public-ip-address fw-pip \
  --vnet-name myVNet

# Create a firewall rule
az network firewall network-rule create \
  --resource-group myResourceGroup \
  --firewall-name myFirewall \
  --name AllowDNS \
  --protocol UDP \
  --source-addresses '*' \
  --destination-addresses 8.8.8.8 1.1.1.1 \
  --destination-ports 53
```

---

## 🔍 Section 8: IAM (Identity and Access Management)

### AWS IAM

#### Users and Groups

```bash
# Create IAM user
aws iam create-user --user-name devops-user

# Create IAM group
aws iam create-group --group-name developers

# Add user to group
aws iam add-user-to-group \
  --user-name devops-user \
  --group-name developers

# Create access key for programmatic access
aws iam create-access-key \
  --user-name devops-user

# Create login profile (console access)
aws iam create-login-profile \
  --user-name devops-user \
  --password "TempP@ss123!" \
  --password-reset-required
```

#### Policies

```bash
# Attach managed policy to group
aws iam attach-group-policy \
  --group-name developers \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create a custom policy
cat > s3-write-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::my-company-bucket",
                "arn:aws:s3:::my-company-bucket/*"
            ]
        }
    ]
}
EOF

aws iam create-policy \
  --policy-name S3WriteAccess \
  --policy-document file://s3-write-policy.json

# Attach custom policy
aws iam attach-user-policy \
  --user-name devops-user \
  --policy-arn arn:aws:iam::123456789012:policy/S3WriteAccess
```

#### IAM Roles

```bash
# Create a trust policy for EC2
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# Create the role
aws iam create-role \
  --role-name EC2-S3-ReadOnly \
  --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy \
  --role-name EC2-S3-ReadOnly \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create instance profile (EC2-specific wrapper for role)
aws iam create-instance-profile \
  --instance-profile-name EC2-S3-ReadOnly-Profile

aws iam add-role-to-instance-profile \
  --instance-profile-name EC2-S3-ReadOnly-Profile \
  --role-name EC2-S3-ReadOnly

# Attach to EC2 instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-0abcdef1234567890 \
  --iam-instance-profile Name=EC2-S3-ReadOnly-Profile
```

#### Policy Evaluation Logic

```
Request context:
  Principal (who), Action (what), Resource (which),
  Condition (when/where)

Step 1: Is there a DENY? → DENIED (explicit deny wins)
Step 2: Is there an ALLOW? → ALLOWED
Step 3: Default → DENIED (implicit deny)

Decision:
  DENY > ALLOW > implicit deny
```

#### Trust Policies

```bash
# Cross-account role trust policy
cat > cross-account-trust.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::OTHER_ACCOUNT_ID:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "EXTERNAL_ID_FOR_SECURITY"
                }
            }
        }
    ]
}
EOF
```

### GCP IAM

#### Roles

```bash
# Primitive roles (legacy, broad):
# roles/viewer (read-only)
# roles/editor (read-write)
# roles/owner (full control, billing)

# Predefined roles (fine-grained):
# roles/compute.admin
# roles/compute.instanceAdmin
# roles/storage.objectViewer
# roles/storage.objectAdmin
# roles/iam.serviceAccountUser

# List roles
gcloud iam roles list
gcloud iam roles list --project my-project

# List permissions in a role
gcloud iam roles describe roles/storage.objectViewer
```

#### Custom Roles

```bash
# Create a custom role
gcloud iam roles create myCustomRole \
  --project my-project \
  --title "Custom Instance Operator" \
  --description "Start, stop, and view instances" \
  --permissions \
    compute.instances.get,\
    compute.instances.list,\
    compute.instances.start,\
    compute.instances.stop \
  --stage GA

# List custom roles
gcloud iam roles list --project my-project

# Update a custom role
gcloud iam roles update myCustomRole \
  --project my-project \
  --add-permissions compute.instances.reset
```

#### Service Accounts

```bash
# Create a service account
gcloud iam service-accounts create my-sa \
  --display-name="My Service Account"

# List service accounts
gcloud iam service-accounts list

# Grant a role to service account
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:my-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Create and download key
gcloud iam service-accounts keys create ~/sa-key.json \
  --iam-account=my-sa@my-project.iam.gserviceaccount.com

# Grant a service account access to act as another (impersonation)
gcloud iam service-accounts add-iam-policy-binding \
  target-sa@my-project.iam.gserviceaccount.com \
  --member="serviceAccount:my-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

#### GCP IAM Policy Structure

```bash
# View IAM policy for a project
gcloud projects get-iam-policy my-project

# View IAM policy for a specific resource
gsutil iam get gs://my-bucket

# Set IAM policy (binding)
cat > policy.yaml << 'EOF'
bindings:
- members:
  - user: admin@example.com
  - serviceAccount:my-sa@my-project.iam.gserviceaccount.com
  role: roles/compute.admin
- members:
  - group: devops@example.com
  role: roles/storage.objectViewer
EOF

gcloud projects set-iam-policy my-project policy.yaml

# Conditional IAM (temporary access)
gcloud projects add-iam-policy-binding my-project \
  --member="user:contractor@example.com" \
  --role="roles/storage.objectAdmin" \
  --condition="expression=request.time < timestamp('2025-12-31T23:59:59Z'),title=temporary_access"
```

### Azure RBAC

#### Built-in Roles

```bash
# List built-in roles
az role definition list -o table

# Common built-in roles:
# Owner           — Full access, can assign roles
# Contributor     — Full access, cannot assign roles
# Reader          — Read-only
# Network Contributor — Manage networking
# Virtual Machine Contributor — Manage VMs
# Storage Blob Data Owner — Full blob storage access
# Storage Blob Data Reader — Read blob storage
```

#### Custom Roles

```bash
cat > custom-role.json << 'EOF'
{
    "Name": "VM Operator",
    "Description": "Can start, stop, and restart VMs",
    "Actions": [
        "Microsoft.Compute/virtualMachines/start/action",
        "Microsoft.Compute/virtualMachines/restart/action",
        "Microsoft.Compute/virtualMachines/deallocate/action",
        "Microsoft.Compute/virtualMachines/read"
    ],
    "NotActions": [],
    "AssignableScopes": [
        "/subscriptions/SUBSCRIPTION_ID",
        "/subscriptions/SUBSCRIPTION_ID/resourceGroups/myResourceGroup"
    ]
}
EOF

# Create custom role
az role definition create --role-definition custom-role.json

# List custom roles
az role definition list --custom-role-only -o table
```

#### Role Assignments

```bash
# Assign a role to a user
az role assignment create \
  --assignee user@example.com \
  --role "Reader" \
  --resource-group myResourceGroup

# Assign a role at subscription scope
az role assignment create \
  --assignee user@example.com \
  --role "Contributor" \
  --subscription "My Subscription"

# Assign a role to a service principal
az role assignment create \
  --assignee APP_ID \
  --role "Virtual Machine Contributor" \
  --resource-group myResourceGroup

# List role assignments
az role assignment list \
  --resource-group myResourceGroup \
  -o table

# Remove a role assignment
az role assignment delete \
  --assignee user@example.com \
  --role "Reader" \
  --resource-group myResourceGroup
```

#### Managed Identities

```bash
# Create a system-assigned managed identity (on Azure VM)
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --assign-identity

# Create a user-assigned managed identity
az identity create \
  --resource-group myResourceGroup \
  --name myUserIdentity

# Assign to VM
az vm identity assign \
  --resource-group myResourceGroup \
  --name myVM \
  --identities /subscriptions/SUB_ID/resourcegroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myUserIdentity

# Grant permissions to the managed identity
az role assignment create \
  --assignee-object-id $(az identity show --name myUserIdentity --resource-group myResourceGroup --query principalId -o tsv) \
  --role "Storage Blob Data Reader" \
  --scope /subscriptions/SUB_ID/resourceGroups/myResourceGroup/providers/Microsoft.Storage/storageAccounts/myuniquestorage12345
```

---

## 🔍 Section 9: Cloud SSH Access

### AWS Session Manager (SSM)

```bash
# Prerequisites on EC2 instance:
# 1. AmazonSSMManagedInstanceCore IAM policy attached to instance role
# 2. SSM Agent installed (preinstalled on Amazon Linux 2, Ubuntu 18.04+)

# Connect to an instance WITHOUT SSH key, WITHOUT public IP
aws ssm start-session \
  --target i-0abcdef1234567890

# Once connected, you get a shell:
# sh-4.2$ _

# Port forwarding through SSM (tunnel to RDS, etc.)
aws ssm start-session \
  --target i-0abcdef1234567890 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3306"], "localPortNumber":["3306"]}'
# Now connect to localhost:3306 → forwarded to instance's 3306

# Copy files through SSM (no SCP needed)
# Send a file
aws ssm send-command \
  --instance-ids i-0abcdef1234567890 \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["echo hello > /tmp/test.txt"]'

# Start a port forwarding session to remote host through instance
aws ssm start-session \
  --target i-0abcdef1234567890 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["10.0.2.50"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

### GCP IAP TCP Forwarding

```bash
# Prerequisites:
# 1. Instance has no public IP or firewall blocks SSH
# 2. IAP firewall rule allows TCP 22 from IAP IP range (35.235.240.0/20)
# 3. IAM: roles/iap.tunnelResourceAccessor + roles/compute.instanceAdmin

# Create firewall rule for IAP
gcloud compute firewall-rules create allow-ssh-from-iap \
  --network=default \
  --allow=tcp:22 \
  --source-ranges=35.235.240.0/20

# Connect via IAP
gcloud compute ssh my-instance \
  --zone=us-central1-a \
  --tunnel-through-iap

# IAP TCP forwarding for RDP
gcloud compute ssh my-windows-instance \
  --zone=us-central1-a \
  --tunnel-through-iap \
  -- -L 3389:localhost:3389

# Without gcloud (raw TCP forwarding)
gcloud compute start-iap-tunnel my-instance 22 \
  --zone=us-central1-a \
  --local-host-port=localhost:2222

# Then in another terminal:
ssh -p 2222 username@localhost
```

### Azure Bastion

```bash
# Create a Bastion host (requires AzureFirewallSubnet or AzureBastionSubnet)
az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name AzureBastionSubnet \
  --address-prefixes 10.0.3.0/27

# Create public IP for Bastion
az network public-ip create \
  --resource-group myResourceGroup \
  --name bastion-pip \
  --sku Standard

# Create Bastion host
az network bastion create \
  --resource-group myResourceGroup \
  --name myBastion \
  --vnet-name myVNet \
  --public-ip-address bastion-pip

# Connect via Bastion (Azure Portal: Bastion → Connect → SSH)
# Requires: Azure AD authentication or SSH key in key vault

# Or use Azure CLI extension
az extension add --name ssh
az ssh vm \
  --resource-group myResourceGroup \
  --name myVM \
  --local-user azureuser \
  --private-key-file ~/.ssh/id_rsa
```

### Serial Console Access (All Clouds)

```bash
# AWS: EC2 Serial Console (must be enabled per account)
aws ec2 enable-serial-console-access

# Then connect via web console or AWS CLI
# (uses SSH to serial-console.aws)

# GCP: Serial port access
gcloud compute instances add-metadata my-instance \
  --metadata=serial-port-enable=true

gcloud compute connect-to-serial-port my-instance \
  --zone=us-central1-a

# Azure: Serial Console
# Enable boot diagnostics first:
az vm boot-diagnostics enable \
  --resource-group myResourceGroup \
  --name myVM

# Serial console access is via Azure Portal only
```

---

## 🔍 Section 10: Cloud Cost Management

### Tagging Strategy

```bash
# AWS: Tag resources
aws ec2 create-tags \
  --resources i-0abcdef1234567890 \
  --tags Key=Environment,Value=Production \
         Key=CostCenter,Value=CC-1234 \
         Key=Owner,Value=devops-team \
         Key=Project,Value=my-app

# GCP: Label resources
gcloud compute instances add-labels my-instance \
  --labels=environment=production,cost-center=cc-1234,owner=devops

# Azure: Tag resources
az tag create \
  --resource-id /subscriptions/SUB_ID/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM \
  --tags Environment=Production CostCenter=CC-1234 Owner=DevOps
```

### Billing Alerts

```bash
# AWS: Create a budget
# Can be done via CLI with budgets.json:
cat > budget.json << 'EOF'
{
    "BudgetName": "Monthly-Development-Budget",
    "BudgetLimit": {
        "Amount": "1000",
        "Unit": "USD"
    },
    "CostFilters": {
        "TagKeyValue": [
            "Environment$Development"
        ]
    },
    "CostTypes": {
        "IncludeTax": true,
        "IncludeSubscription": true,
        "UseBlended": false
    },
    "TimeUnit": "MONTHLY",
    "BudgetNotifications": [
        {
            "Notification": {
                "NotificationType": "ACTUAL",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 80,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "devops@example.com"
                }
            ]
        },
        {
            "Notification": {
                "NotificationType": "FORECASTED",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 100,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "devops@example.com"
                }
            ]
        }
    ]
}
EOF

aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json

# GCP: Create a budget
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Dev Budget" \
  --budget-amount=1000 \
  --threshold-rules=percent=0.5 \
  --threshold-rules=percent=0.8 \
  --threshold-rules=percent=1.0 \
  --notifications-rule-pubsub-topic=projects/my-project/topics/budget-alerts \
  --notifications-rule-schema-update=true \
  --notifications-rule-disable-default-iam-recipients=false \
  --filter-projects=projects/my-project-id

# Azure: Create a budget
az consumption budget create \
  --budget-name "MonthlyBudget" \
  --category cost \
  --amount 1000 \
  --time-grain monthly \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --notifications \
    '{"operator":"GreaterThan","threshold":80,"contact-emails":["devops@example.com"],"enabled":true}' \
  --resource-group myResourceGroup
```

### Reserved Instances and Savings Plans

```bash
# AWS: Purchase reserved instance
# (Use console — CLI is complex, but here's the concept)
# Standard RI: 1yr or 3yr, can modify AZ/instance size within family
# Convertible RI: Can change instance family, higher discount, but flexible

# AWS Savings Plans
# Compute Savings Plans: Apply to any compute (EC2, Fargate, Lambda)
# EC2 Instance Savings Plans: Apply to specific instance family in a region

# GCP: Committed Use Discounts (CUDs)
# 1yr or 3yr commitment for vCPUs and memory
gcloud compute commitments create my-commitment \
  --region=us-central1 \
  --plan=36-month \
  --resources=vcpu=50,memory=200GB

# Azure: Reserved VM Instances
# 1yr or 3yr, pay upfront/partial/monthly
az reservation calculate --sku Standard_D2s_v3 --location eastus

# Azure Savings Plan for Compute
# Similar to AWS — commit to hourly spend for 1yr or 3yr
```

### Right-Sizing

```bash
# AWS: Get right-sizing recommendations
aws compute-optimizer get-ec2-instance-recommendations \
  --instance-arns arn:aws:ec2:us-east-1:123456789012:instance/i-0abcdef1234567890

# GCP: Rightsizing recommendations
gcloud recommender recommendations list \
  --project=my-project \
  --location=us-central1-a \
  --recommender=google.compute.instance.MachineTypeRecommender \
  --format="json"

# Azure: Advisor recommendations
az advisor recommendation list \
  --resource-group myResourceGroup \
  --category Cost
```

---

## 🔍 Section 11: Multi-Cloud Comparison

### Equivalent Services

| Category | AWS | GCP | Azure |
|----------|-----|-----|-------|
| Compute | EC2 | Compute Engine | Virtual Machines |
| Container | ECS/EKS | GKE | AKS |
| Serverless | Lambda | Cloud Functions | Azure Functions |
| Object Storage | S3 | Cloud Storage | Blob Storage |
| Block Storage | EBS | Persistent Disk | Managed Disks |
| File Storage | EFS | Filestore | Azure Files |
| DNS | Route 53 | Cloud DNS | Azure DNS |
| CDN | CloudFront | Cloud CDN | Azure CDN |
| Load Balancer | ALB/NLB | Cloud LB | Azure Load Balancer |
| Database (SQL) | RDS | Cloud SQL | Azure SQL |
| Database (NoSQL) | DynamoDB | Firestore | Cosmos DB |
| Caching | ElastiCache | Memorystore | Azure Cache for Redis |
| Queue | SQS | Pub/Sub | Queue Storage |
| Email | SES | - | SendGrid |
| Monitoring | CloudWatch | Cloud Monitoring | Azure Monitor |
| Logging | CloudWatch Logs | Cloud Logging | Log Analytics |
| IAM | IAM | Cloud IAM | Azure RBAC |
| VPC | VPC | VPC | VNet |
| Bastion | SSM Session Manager | IAP TCP Forwarding | Azure Bastion |
| Budgets | AWS Budgets | GCP Budgets | Cost Management |
| Terraform | provider "aws" | provider "google" | provider "azurerm" |

### Common Multi-Cloud Patterns

```
1. Active-Passive: Primary on AWS, DR on GCP
   - Route 53 fails over to GCP LB
   - Data replicated via S3 → GCS transfer

2. Best-of-Breed: Choose each service from its strongest provider
   - AWS: EC2, S3, DynamoDB
   - GCP: BigQuery, Dataflow
   - Azure: Active Directory, Office 365

3. Avoid Lock-in: Use cloud-agnostic tools
   - Terraform (all three)
   - Kubernetes (AKS, EKS, GKE)
   - Prometheus + Grafana (monitoring)
   - Crossplane (control plane)
```

### Vendor Lock-In Considerations

```
High Lock-In Risk:
  - AWS DynamoDB (NoSQL API is proprietary)
  - GCP BigQuery (SQL dialect, pricing model)
  - Azure Cosmos DB (API is proprietary)
  - Cloud-native serverless (Lambda, Cloud Functions, Azure Functions)
  - Managed Kubernetes (control plane differences)

Low Lock-In Risk:
  - Compute (you control the OS, portable across clouds)
  - Object Storage (S3 API is de facto standard)
  - Kubernetes (standard API, portable workloads)
  - Terraform/HCL (same config works across clouds)
  - SQL databases (PostgreSQL, MySQL are portable)

Mitigation Strategies:
  - Use S3-compatible storage API (MinIO, Ceph)
  - Use standard Kubernetes (EKS, GKE, AKS all support standard K8s)
  - Use Terraform for all infrastructure definitions
  - Avoid proprietary database services unless necessary
  - Abstract cloud SDK calls behind your own interfaces
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### ✅ Practice 1: Configure AWS CLI with IAM User Credentials

```bash
mkdir -p ~/linux-course/part50
cd ~/linux-course/part50

# Step 1: Install AWS CLI if not installed
which aws || sudo apt install -y awscli

# Step 2: Create IAM user via AWS Console (or use existing)
# For this exercise, create an access key in the AWS Console:
# IAM → Users → Create user → Attach "AdministratorAccess" → Create access key

# Step 3: Configure AWS CLI
aws configure

# Enter:
# AWS Access Key ID: [your access key]
# AWS Secret Access Key: [your secret key]
# Default region name: us-east-1
# Default output format: json

# Step 4: Verify
aws sts get-caller-identity

# Step 5: Create a named profile for a different environment
aws configure --profile dev
aws configure --profile prod

# Step 6: Test profiles
aws s3 ls --profile dev
aws s3 ls --profile prod

# Step 7: View the config and credentials files
echo "=== ~/.aws/config ==="
cat ~/.aws/config
echo ""
echo "=== ~/.aws/credentials ==="
cat ~/.aws/credentials
```

---

### ✅ Practice 2: Launch an EC2 Instance with Userdata Script

```bash
cd ~/linux-course/part50

# Step 1: Create a key pair
aws ec2 create-key-pair \
  --key-name course-key \
  --query 'KeyMaterial' \
  --output text > course-key.pem
chmod 400 course-key.pem

# Step 2: Create a security group
SG_ID=$(aws ec2 create-security-group \
  --group-name course-sg \
  --description "Course security group" \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Step 3: Create userdata script
cat > userdata.sh << 'EOF'
#!/bin/bash
exec > /var/log/userdata.log 2>&1
set -ex
apt update
apt install -y nginx
echo "<h1>EC2 Instance launched from userdata</h1>" > /var/www/html/index.html
systemctl enable --now nginx
EOF

# Step 4: Get latest Ubuntu AMI
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[0].ImageId' \
  --output text)

echo "Using AMI: $AMI_ID"

# Step 5: Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name course-key \
  --security-group-ids $SG_ID \
  --user-data file://userdata.sh \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched instance: $INSTANCE_ID"

# Step 6: Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Step 7: Get public IP
IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instance public IP: $IP"

# Step 8: Wait for userdata to complete (give it 30 seconds)
sleep 30

# Step 9: Test
curl http://$IP

# Step 10: Terminate the instance when done
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
```

---

### ✅ Practice 3: Create an S3 Bucket with Versioning and Lifecycle Policy

```bash
cd ~/linux-course/part50

# Step 1: Create a bucket (must be globally unique)
BUCKET_NAME="course-bucket-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME

# Step 2: Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Step 3: Create lifecycle policy
cat > lifecycle.json << 'EOF'
{
  "Rules": [
    {
      "Id": "archive-logs",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "logs/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    },
    {
      "Id": "expire-old-versions",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file://lifecycle.json

# Step 4: Upload objects
echo "Hello S3" > hello.txt
aws s3 cp hello.txt s3://$BUCKET_NAME/
aws s3 cp hello.txt s3://$BUCKET_NAME/  # Upload again (creates version)
aws s3 cp hello.txt s3://$BUCKET_NAME/logs/

# Step 5: List objects and versions
aws s3 ls s3://$BUCKET_NAME/
aws s3api list-object-versions --bucket $BUCKET_NAME

# Step 6: Generate a presigned URL
aws s3 presign s3://$BUCKET_NAME/hello.txt --expires-in 3600

# Step 7: Clean up (delete all versions first, then bucket)
aws s3 rm s3://$BUCKET_NAME/ --recursive

# Must delete versioned objects before deleting bucket
VERSIONS=$(aws s3api list-object-versions \
  --bucket $BUCKET_NAME \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
  --output text 2>/dev/null)

if [ -n "$VERSIONS" ]; then
  aws s3api delete-objects \
    --bucket $BUCKET_NAME \
    --delete "$(aws s3api list-object-versions --bucket $BUCKET_NAME --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" 2>/dev/null || true
fi

aws s3 rb s3://$BUCKET_NAME
```

---

### ✅ Practice 4: Configure a VPC with Public and Private Subnets, NAT Gateway

```bash
cd ~/linux-course/part50

# Step 1: Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --query 'Vpc.VpcId' \
  --output text)

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames

# Step 2: Create subnets
PUBLIC_SN=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SN=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1a \
  --query 'Subnet.SubnetId' \
  --output text)

# Enable auto-assign public IP on public subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SN \
  --map-public-ip-on-launch

# Step 3: Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

# Step 4: Create route table for public subnet
PUBLIC_RTB=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PUBLIC_RTB \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RTB \
  --subnet-id $PUBLIC_SN

# Step 5: Create NAT Gateway
ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' \
  --output text)

NAT_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SN \
  --allocation-id $ALLOC_ID \
  --query 'NatGateway.NatGatewayId' \
  --output text)

echo "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_ID

# Step 6: Create route table for private subnet
PRIVATE_RTB=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PRIVATE_RTB \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_ID

aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RTB \
  --subnet-id $PRIVATE_SN

# Step 7: Verify
aws ec2 describe-route-tables --route-table-ids $PUBLIC_RTB
aws ec2 describe-route-tables --route-table-ids $PRIVATE_RTB

# Step 8: Clean up
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_ID
aws ec2 release-address --allocation-id $ALLOC_ID
aws ec2 delete-route-table --route-table-id $PRIVATE_RTB
aws ec2 delete-route-table --route-table-id $PUBLIC_RTB
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
aws ec2 delete-subnet --subnet-id $PRIVATE_SN
aws ec2 delete-subnet --subnet-id $PUBLIC_SN
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

### ✅ Practice 5: Create an IAM Role and Attach to an EC2 Instance

```bash
cd ~/linux-course/part50

# Step 1: Create IAM role trust policy for EC2
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# Step 2: Create the role
aws iam create-role \
  --role-name S3ReadOnlyRole \
  --assume-role-policy-document file://trust-policy.json

# Step 3: Attach S3 read-only policy
aws iam attach-role-policy \
  --role-name S3ReadOnlyRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Step 4: Create instance profile
aws iam create-instance-profile \
  --instance-profile-name S3ReadOnlyProfile

aws iam add-role-to-instance-profile \
  --instance-profile-name S3ReadOnlyProfile \
  --role-name S3ReadOnlyRole

# Step 5: Launch an instance with this role
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[0].ImageId' \
  --output text)

aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --iam-instance-profile Name=S3ReadOnlyProfile \
  --user-data "#!/bin/bash\necho 'IAM role attached!'" \
  --query 'Instances[0].InstanceId' \
  --output text

# Step 6: Verify the role works
# (SSH into the instance if you have key access)
# aws s3 ls  # This should work without any access key!

# Step 7: Clean up
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=iam-instance-profile.arn,Values=*S3ReadOnlyProfile*" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws iam remove-role-from-instance-profile \
  --instance-profile-name S3ReadOnlyProfile \
  --role-name S3ReadOnlyRole
aws iam delete-instance-profile --instance-profile-name S3ReadOnlyProfile
aws iam detach-role-policy \
  --role-name S3ReadOnlyRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam delete-role --role-name S3ReadOnlyRole
```

---

### ✅ Practice 6: Use AWS SSM Session Manager to Connect (No SSH Key)

```bash
cd ~/linux-course/part50

# Step 1: Create IAM role for SSM
cat > ssm-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

aws iam create-role \
  --role-name SSM-Role \
  --assume-role-policy-document file://ssm-trust-policy.json

aws iam attach-role-policy \
  --role-name SSM-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

aws iam create-instance-profile \
  --instance-profile-name SSM-Profile

aws iam add-role-to-instance-profile \
  --instance-profile-name SSM-Profile \
  --role-name SSM-Role

# Step 2: Launch instance with SSM role (no key pair, no SG SSH rule!)
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[0].ImageId' \
  --output text)

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --iam-instance-profile Name=SSM-Profile \
  --query 'Instances[0].InstanceId' \
  --output text)

# Wait for it to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Step 3: Wait for SSM agent to register (30-60s)
sleep 60

# Step 4: Connect via SSM Session Manager
# aws ssm start-session --target $INSTANCE_ID

# Step 5: Run a command remotely via SSM (no interactive session needed)
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["echo SSM_WORKS && uname -a && uptime"]' \
  --output text

# Wait for command to execute
sleep 10

# Get command output
COMMAND_ID=$(aws ssm list-commands \
  --instance-id $INSTANCE_ID \
  --query 'Commands[0].CommandId' \
  --output text)

aws ssm get-command-invocation \
  --command-id $COMMAND_ID \
  --instance-id $INSTANCE_ID

# Step 6: Clean up
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws iam remove-role-from-instance-profile \
  --instance-profile-name SSM-Profile \
  --role-name SSM-Role
aws iam delete-instance-profile --instance-profile-name SSM-Profile
aws iam detach-role-policy \
  --role-name SSM-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-role --role-name SSM-Role
```

---

### ✅ Practice 7: Configure gcloud and Create a GCE Instance with Startup Script

```bash
cd ~/linux-course/part50

# Step 1: Initialize gcloud
gcloud init

# Step 2: Set defaults
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# Step 3: List projects and verify
gcloud projects list
gcloud config list

# Step 4: Create a startup script
cat > startup.sh << 'EOF'
#!/bin/bash
exec > /var/log/startup.log 2>&1
set -ex
apt update
apt install -y apache2
echo "<h1>GCE instance from startup script</h1>" > /var/www/html/index.html
systemctl enable --now apache2
EOF

# Step 5: Create firewall rule for HTTP
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0

# Step 6: Create instance
gcloud compute instances create course-instance \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --tags=http-server \
  --metadata-from-file startup-script=startup.sh

# Step 7: Wait for instance
sleep 30

# Step 8: Get external IP
EXTERNAL_IP=$(gcloud compute instances describe course-instance \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Instance IP: $EXTERNAL_IP"

# Step 9: Test the web server
curl http://$EXTERNAL_IP

# Step 10: Connect via SSH
gcloud compute ssh course-instance --command="hostname && uptime"

# Step 11: Clean up
gcloud compute instances delete course-instance --quiet
gcloud compute firewall-rules delete allow-http --quiet
```

---

### ✅ Practice 8: Set Up GCS Bucket with Object Lifecycle Management

```bash
cd ~/linux-course/part50

# Step 1: Create a GCS bucket
BUCKET_NAME="course-gcs-bucket-$(date +%s)"
gcloud storage buckets create gs://$BUCKET_NAME \
  --location=US

# Step 2: Create lifecycle config
cat > lifecycle.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 30}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
        "condition": {"age": 365}
      },
      {
        "action": {"type": "Delete"},
        "condition": {"age": 730}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME

# Step 3: Upload files
echo "Hello GCS" > hello.txt
gsutil cp hello.txt gs://$BUCKET_NAME/
gsutil cp hello.txt gs://$BUCKET_NAME/backup/
gsutil cp /etc/hostname gs://$BUCKET_NAME/config/

# Step 4: List files
gsutil ls gs://$BUCKET_NAME/
gsutil ls -r gs://$BUCKET_NAME/

# Step 5: Set object metadata
gsutil setmeta -h "Cache-Control:no-cache" gs://$BUCKET_NAME/hello.txt

# Step 6: Generate a signed URL (equivalent to presigned URL)
gsutil signurl -d 1h ~/sa-key.json gs://$BUCKET_NAME/hello.txt

# Step 7: Make object publicly readable
gsutil acl ch -u AllUsers:R gs://$BUCKET_NAME/hello.txt

# Step 8: Clean up
gsutil rm -r gs://$BUCKET_NAME/
```

---

### ✅ Practice 9: Create GCP VPC with Firewall Rules and Cloud NAT

```bash
cd ~/linux-course/part50

# Step 1: Create custom VPC
gcloud compute networks create course-vpc \
  --subnet-mode=custom

# Step 2: Create subnets
gcloud compute networks subnets create public-subnet \
  --network=course-vpc \
  --region=us-central1 \
  --range=10.0.1.0/24

gcloud compute networks subnets create private-subnet \
  --network=course-vpc \
  --region=us-central1 \
  --range=10.0.2.0/24

# Step 3: Create firewall rules
gcloud compute firewall-rules create allow-http \
  --network=course-vpc \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create allow-ssh \
  --network=course-vpc \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create allow-internal \
  --network=course-vpc \
  --allow=tcp:0-65535,udp:0-65535,icmp \
  --source-ranges=10.0.0.0/16

# Step 4: Create Cloud Router and Cloud NAT
gcloud compute routers create course-router \
  --network=course-vpc \
  --region=us-central1

gcloud compute routers nats create course-nat \
  --router=course-router \
  --region=us-central1 \
  --nat-external-ip-pool=auto-allocate \
  --nat-all-subnet-ip-ranges

# Step 5: Create instance in private subnet
gcloud compute instances create private-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --subnet=private-subnet \
  --no-address \
  --metadata=enable-oslogin=true

# Step 6: Create a bastion in public subnet
gcloud compute instances create bastion \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --subnet=public-subnet

# Step 7: Verify private instance can reach internet (via NAT)
gcloud compute ssh bastion --command="gcloud compute ssh private-instance --command='curl -s ifconfig.me' --zone=us-central1-a --tunnel-through-iap" 2>/dev/null || \
echo "Private instance should have internet via Cloud NAT"

# Step 8: Clean up
gcloud compute instances delete private-instance bastion --quiet
gcloud compute routers nats delete course-nat --router=course-router --region=us-central1 --quiet
gcloud compute routers delete course-router --region=us-central1 --quiet
gcloud compute firewall-rules delete allow-http allow-ssh allow-internal --quiet
gcloud compute networks subnets delete public-subnet private-subnet --region=us-central1 --quiet
gcloud compute networks delete course-vpc --quiet
```

---

### ✅ Practice 10: Configure GCP IAM Service Account and Grant Permissions

```bash
cd ~/linux-course/part50

# Step 1: Create a service account
gcloud iam service-accounts create course-sa \
  --display-name="Course Service Account"

# Step 2: List service accounts
gcloud iam service-accounts list

# Step 3: Grant roles to the service account
gcloud projects add-iam-policy-binding $(gcloud config get project) \
  --member="serviceAccount:course-sa@$(gcloud config get project).iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding $(gcloud config get project) \
  --member="serviceAccount:course-sa@$(gcloud config get project).iam.gserviceaccount.com" \
  --role="roles/compute.instanceAdmin"

# Step 4: Create and download a key
gcloud iam service-accounts keys create course-sa-key.json \
  --iam-account=course-sa@$(gcloud config get project).iam.gserviceaccount.com

# Step 5: Test service account authentication
export GOOGLE_APPLICATION_CREDENTIALS=course-sa-key.json
gcloud auth activate-service-account --key-file=course-sa-key.json

# Step 6: Verify it works (should list instances)
gcloud compute instances list

# Step 7: Create a custom role
gcloud iam roles create courseInstanceViewer \
  --project=$(gcloud config get project) \
  --title="Course Instance Viewer" \
  --description="View instances only" \
  --permissions=compute.instances.get,compute.instances.list \
  --stage=GA

# Step 8: Switch back to your user
gcloud config set account $(gcloud auth list --format='value(account)' --filter=status:ACTIVE)

# Step 9: Clean up
gcloud iam service-accounts delete course-sa@$(gcloud config get project).iam.gserviceaccount.com --quiet
gcloud iam roles delete courseInstanceViewer --project=$(gcloud config get project) --quiet
rm -f course-sa-key.json
```

---

### ✅ Practice 11: Configure Azure CLI and Create a VM with Custom Data

```bash
cd ~/linux-course/part50

# Step 1: Install Azure CLI
which az || curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Step 2: Login
az login --use-device-code

# Step 3: List subscriptions
az account list -o table

# Step 4: Set subscription
az account set --subscription "Your Subscription Name"

# Step 5: Create a resource group
az group create \
  --name CourseRG \
  --location eastus

# Step 6: Create custom data script
cat > customdata.sh << 'EOF'
#!/bin/bash
apt update
apt install -y nginx
echo "<h1>Azure VM from custom data</h1>" > /var/www/html/index.html
systemctl enable --now nginx
EOF

# Step 7: Create SSH key (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/course_key -N "" 2>/dev/null || true

# Step 8: Create VM
az vm create \
  --resource-group CourseRG \
  --name CourseVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/course_key.pub \
  --custom-data customdata.sh

# Step 9: Get public IP and test
PUBLIC_IP=$(az vm show \
  --resource-group CourseRG \
  --name CourseVM \
  --show-details \
  --query publicIps \
  -o tsv)

echo "VM IP: $PUBLIC_IP"

# Step 10: Open port 80
az vm open-port \
  --resource-group CourseRG \
  --name CourseVM \
  --port 80

# Step 11: Test web server
sleep 60
curl -m 10 http://$PUBLIC_IP || echo "VM still provisioning..."

# Step 12: Clean up
az vm delete --resource-group CourseRG --name CourseVM --yes
az group delete --name CourseRG --yes --no-wait
```

---

### ✅ Practice 12: Create Azure Blob Storage with SAS Token

```bash
cd ~/linux-course/part50

# Step 1: Create resource group
az group create \
  --name CourseStorageRG \
  --location eastus

# Step 2: Create storage account
STORAGE_ACCOUNT="coursestorage$(date +%s)"
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group CourseStorageRG \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Step 3: Get connection string
CONNECTION_STRING=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group CourseStorageRG \
  --query connectionString \
  -o tsv)

# Step 4: Create container
az storage container create \
  --name coursecontainer \
  --connection-string "$CONNECTION_STRING"

# Step 5: Upload blobs
echo "Hello Azure Blob Storage" > hello.txt
az storage blob upload \
  --container-name coursecontainer \
  --name hello.txt \
  --file hello.txt \
  --connection-string "$CONNECTION_STRING"

az storage blob upload \
  --container-name coursecontainer \
  --name backup/config.txt \
  --file /etc/hostname \
  --connection-string "$CONNECTION_STRING"

# Step 6: List blobs
az storage blob list \
  --container-name coursecontainer \
  --connection-string "$CONNECTION_STRING" \
  -o table

# Step 7: Generate SAS token for container (read + list, 1 hour)
SAS_TOKEN=$(az storage container generate-sas \
  --account-name $STORAGE_ACCOUNT \
  --name coursecontainer \
  --permissions rl \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ') \
  -o tsv)

echo "SAS Token: $SAS_TOKEN"
echo "SAS URL: https://$STORAGE_ACCOUNT.blob.core.windows.net/coursecontainer?$SAS_TOKEN"

# Step 8: Test SAS URL
curl -o /dev/null -s "https://$STORAGE_ACCOUNT.blob.core.windows.net/coursecontainer/hello.txt?$SAS_TOKEN" && echo "SAS URL works!"

# Step 9: Set access tier on a blob
az storage blob set-tier \
  --container-name coursecontainer \
  --name backup/config.txt \
  --tier Cool \
  --connection-string "$CONNECTION_STRING"

# Step 10: Download a blob
az storage blob download \
  --container-name coursecontainer \
  --name hello.txt \
  --file downloaded.txt \
  --connection-string "$CONNECTION_STRING"

cat downloaded.txt

# Step 11: Clean up
az group delete --name CourseStorageRG --yes --no-wait
```

---

### ✅ Practice 13: Configure Azure VNet with NSG Rules

```bash
cd ~/linux-course/part50

# Step 1: Create resource group
az group create \
  --name CourseNetRG \
  --location eastus

# Step 2: Create VNet with subnets
az network vnet create \
  --resource-group CourseNetRG \
  --name CourseVNet \
  --address-prefixes 10.0.0.0/16

az network vnet subnet create \
  --resource-group CourseNetRG \
  --vnet-name CourseVNet \
  --name public-subnet \
  --address-prefixes 10.0.1.0/24

az network vnet subnet create \
  --resource-group CourseNetRG \
  --vnet-name CourseVNet \
  --name private-subnet \
  --address-prefixes 10.0.2.0/24

# Step 3: Create NSG for public subnet
az network nsg create \
  --resource-group CourseNetRG \
  --name publicNSG

az network nsg rule create \
  --resource-group CourseNetRG \
  --nsg-name publicNSG \
  --name AllowHTTP \
  --priority 100 \
  --protocol Tcp \
  --destination-port-ranges 80 \
  --access Allow \
  --source-address-prefixes '*'

az network nsg rule create \
  --resource-group CourseNetRG \
  --nsg-name publicNSG \
  --name AllowSSH \
  --priority 110 \
  --protocol Tcp \
  --destination-port-ranges 22 \
  --access Allow \
  --source-address-prefixes '*'

# Step 4: Create NSG for private subnet
az network nsg create \
  --resource-group CourseNetRG \
  --name privateNSG

az network nsg rule create \
  --resource-group CourseNetRG \
  --nsg-name privateNSG \
  --name DenyAllInbound \
  --priority 100 \
  --protocol '*' \
  --destination-port-ranges '*' \
  --access Deny \
  --source-address-prefixes '*'

az network nsg rule create \
  --resource-group CourseNetRG \
  --nsg-name privateNSG \
  --name AllowInternal \
  --priority 110 \
  --protocol '*' \
  --destination-port-ranges '*' \
  --access Allow \
  --source-address-prefixes 10.0.0.0/16

# Step 5: Associate NSGs with subnets
az network vnet subnet update \
  --resource-group CourseNetRG \
  --vnet-name CourseVNet \
  --name public-subnet \
  --network-security-group publicNSG

az network vnet subnet update \
  --resource-group CourseNetRG \
  --vnet-name CourseVNet \
  --name private-subnet \
  --network-security-group privateNSG

# Step 6: Create a test VM in the private subnet
az vm create \
  --resource-group CourseNetRG \
  --name PrivateVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name CourseVNet \
  --subnet private-subnet \
  --no-public-ip-address

# Step 7: Verify NSG rules
az network nsg rule list \
  --resource-group CourseNetRG \
  --nsg-name publicNSG \
  -o table

az network nsg rule list \
  --resource-group CourseNetRG \
  --nsg-name privateNSG \
  -o table

# Step 8: Clean up
az group delete --name CourseNetRG --yes --no-wait
```

---

### ✅ Practice 14: Set Up Cloud Billing Alerts on All Three Providers

```bash
cd ~/linux-course/part50

echo "=============================================="
echo "BILLING ALERT SETUP GUIDE"
echo "=============================================="
echo ""
echo "AWS Billing Alert:"
echo "  aws budgets create-budget \\"
echo '    --account-id $(aws sts get-caller-identity --query Account --output text) \'
echo '    --budget file://budget.json'
echo ""
echo "  Where budget.json contains:"
echo '  { "BudgetName": "MonthlyBudget", "BudgetLimit": { "Amount": "100", "Unit": "USD" },'
echo '    "TimeUnit": "MONTHLY", "BudgetNotifications": [...] }'
echo ""
echo "GCP Billing Alert:"
echo "  gcloud billing budgets create \\"
echo "    --billing-account=BILLING_ACCOUNT_ID \\"
echo "    --display-name=MonthlyBudget \\"
echo "    --budget-amount=100 \\"
echo "    --threshold-rules=percent=0.5,percent=0.8,percent=1.0"
echo ""
echo "Azure Billing Alert:"
echo "  az consumption budget create \\"
echo "    --budget-name MonthlyBudget \\"
echo "    --category cost --amount 100 \\"
echo "    --time-grain monthly \\"
echo "    --start-date 2024-01-01 --end-date 2024-12-31"
echo ""
echo "=============================================="

# For AWS, create a budget JSON file
cat > budget.json << 'EOF'
{
    "BudgetName": "Monthly-Course-Budget",
    "BudgetLimit": {
        "Amount": "50",
        "Unit": "USD"
    },
    "CostTypes": {
        "IncludeTax": true,
        "IncludeSubscription": true,
        "UseBlended": false
    },
    "TimeUnit": "MONTHLY",
    "BudgetNotifications": [
        {
            "Notification": {
                "NotificationType": "ACTUAL",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 80,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "your-email@example.com"
                }
            ]
        },
        {
            "Notification": {
                "NotificationType": "FORECASTED",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 100,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "your-email@example.com"
                }
            ]
        }
    ]
}
EOF

echo "Edit budget.json with your email, then run:"
echo "aws budgets create-budget --account-id \$(aws sts get-caller-identity --query Account --output text) --budget file://budget.json"
```

---

### ✅ Practice 15: Real-World Integration — Multi-Cloud Inventory Script

```bash
cd ~/linux-course/part50

cat > multi-cloud-inventory.sh << 'EOF'
#!/bin/bash
# Multi-Cloud Inventory Script
# Lists all compute resources across AWS, GCP, and Azure
set -euo pipefail

OUTPUT_DIR="${1:-./inventory}"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT="$OUTPUT_DIR/cloud-inventory-$TIMESTAMP.txt"

mkdir -p "$OUTPUT_DIR"

{
echo "=============================================="
echo "  MULTI-CLOUD INVENTORY REPORT"
echo "  Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
} > "$REPORT"

echo "" >> "$REPORT"

# ─── AWS ───
echo "[AWS EC2 Instances]" >> "$REPORT"
if command -v aws &>/dev/null; then
  if aws sts get-caller-identity &>/dev/null; then
    aws ec2 describe-instances \
      --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,LaunchTime,Placement.AvailabilityZone,PublicIpAddress]' \
      --output table 2>/dev/null >> "$REPORT" || echo "  No instances found or access denied" >> "$REPORT"
  else
    echo "  AWS not configured" >> "$REPORT"
  fi
else
  echo "  AWS CLI not installed" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "[AWS S3 Buckets]" >> "$REPORT"
if command -v aws &>/dev/null; then
  if aws sts get-caller-identity &>/dev/null; then
    aws s3 ls 2>/dev/null >> "$REPORT" || echo "  Cannot list buckets" >> "$REPORT"
  fi
fi
echo "" >> "$REPORT"

# ─── GCP ───
echo "[GCP Compute Engine Instances]" >> "$REPORT"
if command -v gcloud &>/dev/null; then
  if gcloud auth list --format='value(account)' 2>/dev/null | grep -q .; then
    gcloud compute instances list \
      --format='table(name,zone,status,machineType,networkInterfaces[0].networkIP.list())' \
      2>/dev/null >> "$REPORT" || echo "  No instances found or access denied" >> "$REPORT"
  else
    echo "  GCP not authenticated" >> "$REPORT"
  fi
else
  echo "  gcloud CLI not installed" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "[GCP Cloud Storage Buckets]" >> "$REPORT"
if command -v gsutil &>/dev/null; then
  gsutil ls 2>/dev/null >> "$REPORT" || echo "  Cannot list buckets" >> "$REPORT"
fi
echo "" >> "$REPORT"

# ─── Azure ───
echo "[Azure Virtual Machines]" >> "$REPORT"
if command -v az &>/dev/null; then
  if az account show &>/dev/null; then
    az vm list \
      --query '[*].[name,location,hardwareProfile.vmSize,osProfile.computerName,provisioningState]' \
      -o table 2>/dev/null >> "$REPORT" || echo "  No VMs found or access denied" >> "$REPORT"
  else
    echo "  Azure not logged in" >> "$REPORT"
  fi
else
  echo "  Azure CLI not installed" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "[Azure Blob Storage Accounts]" >> "$REPORT"
if command -v az &>/dev/null; then
  if az account show &>/dev/null; then
    az storage account list \
      --query '[*].[name,location,kind,sku.tier]' \
      -o table 2>/dev/null >> "$REPORT" || echo "  Cannot list storage accounts" >> "$REPORT"
  fi
fi
echo "" >> "$REPORT"

{
echo "=============================================="
echo "  END OF REPORT"
echo "=============================================="
} >> "$REPORT"

echo "Report generated: $REPORT"
cat "$REPORT"
EOF

chmod +x multi-cloud-inventory.sh

echo "Inventory script created. To run:"
echo "./multi-cloud-inventory.sh ./inventory"
echo ""
echo "NOTE: This script requires valid credentials for at least one cloud provider."
echo "Run each cloud CLI's auth command first, then this script."
```

---

## 🧠 Deep Understanding — How Cloud Infrastructure Really Works

### How Cloud Hypervisors Differ from Traditional Virtualization

**AWS Nitro System:**
```
Traditional Virtualization:
┌──────────────────────────────┐
│  Virtual Machine              │
│  ├── Guest OS                 │
│  ├── Virtual Devices (emulated)│
│  └── Hypervisor (Xen/KVM)    │
│        ├── CPU scheduler      │
│        ├── Memory manager     │
│        └── Device emulation   │
└──────────────────────────────┘
  → All I/O goes through hypervisor (overhead)

AWS Nitro:
┌──────────────────────────────┐
│  Virtual Machine              │
│  ├── Guest OS                 │
│  └── Nitro Drivers (paravirt) │
├──────────────────────────────┤
│  Nitro Hypervisor (KVM-based) │
│  ├── CPU/Memory only          │
│  └── No device emulation      │
├──────────────────────────────┤
│  Nitro Cards (hardware):      │
│  ├── Nitro EBS (storage)      │
│  ├── Nitro ENIC (networking)  │
│  └── Nitro TPM (security)     │
└──────────────────────────────┘
  → I/O is offloaded to dedicated hardware
  → Near bare-metal performance
  → Each Nitro card has its own CPU
```

**GCP KVM (Google's custom KVM):**
- GCP uses a highly modified KVM hypervisor
- Custom networking stack in the hypervisor (gVNIC, Andromeda)
- No traditional host OS — hypervisor is minimal
- Live migration is transparent (VM moves while running)
- Nested virtualization supported natively

**Azure Hyper-V:**
- Microsoft's own Type 1 hypervisor
- Root partition (Parent) manages child partitions
- VMBus is the communication channel between partitions
- Host OS is a stripped-down Windows Server
- Supports nested virtualization for containers

### How Cloud Networking Is Implemented at Scale

**VXLAN Overlay Networks:**
```
Physical Network (Underlay):
┌──────┐    ┌──────┐    ┌──────┐
│ Spine│────│ Spine│────│ Spine│
└──┬───┘    └──┬───┘    └──┬───┘
   │           │           │
┌──┴───┐    ┌──┴───┐    ┌──┴───┐
│ Leaf │    │ Leaf │    │ Leaf │
└──┬───┘    └──┬───┘    └──┬───┘
   │           │           │
 ┌─┴─┐       ┌─┴─┐       ┌─┴─┐
 │Host│      │Host│      │Host│
 └───┘       └───┘       └───┘

Virtual Network (Overlay):
  VM-A (10.0.1.5) ── VXLAN Tunnel ── VM-B (10.0.2.10)
       │                                    │
  VTEP (VXLAN Tunnel Endpoint)         VTEP
       │                                    │
  ┌────┴────┐                         ┌────┴────┐
  │  VNI 42 │  ← Encapsulated in UDP  │  VNI 42 │
  └─────────┘   Outer: Host IPs       └─────────┘
```

**VXLAN frame structure:**
```
┌──────────────────────────────────────────────────────────┐
│ Outer MAC │ Outer IP │ Outer UDP │ VXLAN │ Inner MAC/IP │
│ (14 bytes)│ (20 bytes)│ (8 bytes)│ (8 bytes)│ (original) │
└──────────────────────────────────────────────────────────┘
```

**Distributed Firewalls:**
- AWS Security Groups are NOT running on a physical appliance
- They are implemented in the Nitro ENIC card
- Rules are evaluated at line rate in hardware
- Every packet is checked; there's no bottleneck
- This is why SGs scale to thousands of rules without performance impact

**AWS Hyperplane (NAT Gateway, ALB, NLB):**
- Not a VM — it's a distributed data plane
- Runs on dedicated Nitro hardware
- Multi-tenant, multi-availability zone
- Scales to 100 Gbps automatically

### How IAM Authorization Works

**Policy Evaluation Engine:**
```
Request arrives with:
┌─────────────────────────────────┐
│ Principal: user/alice           │
│ Action:    ec2:RunInstances     │
│ Resource:  arn:aws:ec2:.../*   │
│ Context:   IP=203.0.113.5      │
│           Time=2024-06-15T10:00│
│           MFA=true              │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 1. AUTHENTICATION CHECK         │
│    Is the principal who they    │
│    claim to be? (cryptographic) │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 2. POLICY AGGREGATION           │
│    Collect ALL applicable       │
│    policies:                    │
│    - Identity-based (user/group)│
│    - Resource-based (bucket)    │
│    - Organizations SCP          │
│    - Session policies (STS)     │
│    - Permissions boundary       │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 3. DENY EVALUATION              │
│    Any explicit DENY? → DENIED  │
│    (SCPs, boundary, identity)   │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 4. ALLOW EVALUATION             │
│    Any explicit ALLOW? → ALLOWED│
│    (identity or resource policy)│
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 5. DEFAULT → DENY (implicit)    │
│    No explicit allow = denied   │
└─────────────────────────────────┘
```

**Condition Keys:**
```json
{
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "*",
    "Condition": {
        "IpAddress": {
            "aws:SourceIp": "203.0.113.0/24"
        },
        "Bool": {
            "aws:SecureTransport": "true"
        },
        "DateGreaterThan": {
            "aws:CurrentTime": "2024-01-01T00:00:00Z"
        },
        "StringEquals": {
            "aws:RequestedRegion": ["us-east-1", "eu-west-1"]
        }
    }
}
```

**GCP IAM Authorization:**
```
1. Policy is attached to the RESOURCE (not the user)
2. Hierarchy inheritance: Organization → Folder → Project → Resource
3. Bindings are evaluated: member + role = set of permissions
4. Deny policies (available in GCP) override allow
5. Conditions use CEL (Common Expression Language):
   - condition: "resource.name.startsWith('projects/my-project/zones/us-central1-a/instances/web-')"
```

**Azure RBAC Authorization:**
```
1. Scope hierarchy: Management Group → Subscription → Resource Group → Resource
2. Role definition includes Actions, NotActions, DataActions
3. Assignments are additive (inherited from parent scope)
4. Deny assignments (explicit) override role assignments
5. Azure Policy (different from RBAC) enforces compliance rules
```

### How Cloud Storage Is Replicated

**Cross-Region Replication (CRR):**
```
AWS S3 CRR:
  us-east-1                  eu-west-1
┌──────────────┐    async   ┌──────────────┐
│ Bucket A      │───────────│ Bucket B      │
│ ├─ obj v1     │  S3 event │ ├─ obj v1     │
│ ├─ obj v2     │  triggers │ ├─ obj v2     │
│ └─ obj v3     │  PUT copy │ └─ obj v3     │
└──────────────┘            └──────────────┘
  → S3 replicates within 15 minutes typically
  → Replication time = object size / bandwidth
  → Each version is replicated separately
```

**Storage Classes Across Clouds:**

| AWS | GCP | Azure | Durability | Min Storage | Retrieval |
|-----|-----|-------|------------|-------------|-----------|
| S3 Standard | Standard | Hot | 99.999999999% | None | Instant |
| S3 Standard-IA | Nearline | Cool | 99.999999999% | 30 days | Instant |
| S3 One Zone-IA | - | - | 99.999999999% | 30 days | Instant |
| S3 Glacier | Coldline | Cold | 99.999999999% | 90 days | 1-5 min |
| S3 Glacier Deep Archive | Archive | Archive | 99.999999999% | 180 days | 12 hours |

**Erasure Coding vs Replication:**
```
Replication (Traditional):
  ┌─────┐   ┌─────┐   ┌─────┐
  │ Obj │   │ Obj │   │ Obj │
  └─────┘   └─────┘   └─────┘
  Disk 1    Disk 2    Disk 3
  → 3x storage cost, can lose 2 disks
  → Simple, works with any data

Erasure Coding (Cloud):
  ┌─────┬──┬──┬──┬──┬──┐
  │ d1  │d2│d3│p1│p2│p3│  ← 6 data + 3 parity shards
  └─────┴──┴──┴──┴──┴──┘
  Disk 1 2  3  4  5  6
  → 1.5x storage cost, can lose 3 disks
  → More efficient than replication
  → Used in: S3, GCS, Azure Blob
  → Reed-Solomon encoding: any k of n shards reconstruct the data

GCS uses 16 data + 3 parity shards by default (11x9s durability)
S3 uses 11x9s durability across multiple devices
Azure LRS = 3 replicas within a single datacenter (LRS)
Azure GRS = 3 replicas + 3 replicas in paired region
```

---

## 📋 Complete Command Reference — Equivalent Commands Across Clouds

### Authentication and Configuration

| Task | AWS | GCP | Azure |
|------|-----|-----|-------|
| Install CLI | `sudo apt install awscli` | `sudo apt install google-cloud-sdk` | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| Login | `aws configure` | `gcloud init` | `az login` |
| List accounts | `aws configure list-profiles` | `gcloud auth list` | `az account list` |
| Set account | `export AWS_PROFILE=dev` | `gcloud config set project X` | `az account set --subscription X` |
| Who am I | `aws sts get-caller-identity` | `gcloud auth list` | `az account show` |
| Use service account | `export AWS_PROFILE=...` | `gcloud auth activate-service-account --key-file=X` | `az login --service-principal -u X -p Y --tenant Z` |

### Compute

| Task | AWS | GCP | Azure |
|------|-----|-----|-------|
| List instances | `aws ec2 describe-instances` | `gcloud compute instances list` | `az vm list` |
| Create instance | `aws ec2 run-instances` | `gcloud compute instances create` | `az vm create` |
| Stop instance | `aws ec2 stop-instances` | `gcloud compute instances stop` | `az vm deallocate` |
| Start instance | `aws ec2 start-instances` | `gcloud compute instances start` | `az vm start` |
| Terminate | `aws ec2 terminate-instances` | `gcloud compute instances delete` | `az vm delete` |
| SSH | `ssh -i key.pem user@ip` | `gcloud compute ssh NAME` | `az ssh vm` |
| Run command | SSM send-command | `gcloud compute ssh --command` | `az vm run-command invoke` |

### Storage

| Task | AWS | GCP | Azure |
|------|-----|-----|-------|
| List buckets | `aws s3 ls` | `gsutil ls` | `az storage container list` |
| Create bucket | `aws s3 mb s3://B` | `gsutil mb gs://B` | `az storage container create --name C` |
| Upload file | `aws s3 cp F s3://B/` | `gsutil cp F gs://B/` | `az storage blob upload --container C --name N --file F` |
| Download | `aws s3 cp s3://B/F ./` | `gsutil cp gs://B/F ./` | `az storage blob download --container C --name N --file F` |
| Sync dir | `aws s3 sync D s3://B/` | `gsutil rsync -r D gs://B/` | `azcopy sync D "https://A.blob.core.windows.net/C"` |
| Presigned URL | `aws s3 presign s3://B/F --expires-in 3600` | `gsutil signurl -d 1h KEY gs://B/F` | `az storage blob generate-sas --container C --name N` |

### Networking

| Task | AWS | GCP | Azure |
|------|-----|-----|-------|
| Create VPC | `aws ec2 create-vpc --cidr 10.0.0.0/16` | `gcloud compute networks create NAME --subnet-mode=custom` | `az network vnet create --address-prefixes 10.0.0.0/16` |
| Create subnet | `aws ec2 create-subnet --vpc-id V --cidr 10.0.1.0/24` | `gcloud compute networks subnets create NAME --network=V --range=...` | `az network vnet subnet create --vnet-name V --address-prefixes 10.0.1.0/24` |
| Firewall | `aws ec2 authorize-security-group-ingress --group-id SG --protocol tcp --port 80 --cidr 0.0.0.0/0` | `gcloud compute firewall-rules create NAME --allow=tcp:80 --source-ranges=0.0.0.0/0` | `az network nsg rule create --nsg-name N --name R --protocol Tcp --destination-port-ranges 80 --access Allow` |
| NAT Gateway | `aws ec2 create-nat-gateway --subnet-id S --allocation-id A` | `gcloud compute routers nats create NAME --router=R --nat-all-subnet-ip-ranges` | Azure Firewall or NAT Gateway |
| Internet Gateway | `aws ec2 create-internet-gateway` | Default route via Cloud Router with NAT | `az network public-ip create` + routing |
| Peering | `aws ec2 create-vpc-peering-connection --vpc-id A --peer-vpc-id B` | `gcloud compute networks peerings create --network=A --peer-network=B` | `az network vnet peering create --vnet-name A --remote-vnet B` |

### IAM

| Task | AWS | GCP | Azure |
|------|-----|-----|-------|
| Create user | `aws iam create-user` | Service accounts only | Microsoft Entra ID |
| Create role | `aws iam create-role --assume-role-policy-document F` | `gcloud iam roles create N --project P --permissions=X` | `az role definition create --role-definition F` |
| Attach policy | `aws iam attach-user-policy --user-name U --policy-arn P` | `gcloud projects add-iam-policy-binding P --member=M --role=R` | `az role assignment create --assignee U --role R --scope S` |
| Create service account | N/A (IAM user = service account) | `gcloud iam service-accounts create N` | `az ad sp create-for-rbac` |
| Generate key | `aws iam create-access-key` | `gcloud iam service-accounts keys create K --iam-account=S` | `az ad sp credential reset --name N` |

### Monitoring

| Task | AWS | GCP | Azure |
|------|-----|-----|-------|
| List instances | `aws ec2 describe-instances --query '...' --output table` | `gcloud compute instances list` | `az vm list -o table` |
| CPU utilization | CloudWatch | Cloud Monitoring | Azure Monitor |
| Logs | CloudWatch Logs | Cloud Logging | Log Analytics |
| Budgets | `aws budgets create-budget` | `gcloud billing budgets create` | `az consumption budget create` |

---

## 🚀 What's Coming in Part 51

**Part 51: Infrastructure as Code — Terraform**

You will learn:
- Terraform fundamentals — providers, resources, state
- HCL syntax — variables, outputs, data sources, modules
- Managing AWS, GCP, and Azure resources with Terraform
- State management — remote backends (S3, GCS, Azure Storage)
- Terraform workflows — init, plan, apply, destroy
- Module composition and the Terraform Registry
- CI/CD integration for infrastructure
- Best practices for production Terraform
- 15 hands-on practices covering multi-cloud IaC

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between IaaS, PaaS, and SaaS? Give an example of each from AWS.
2. What is an Availability Zone and how does it differ from a Region?
3. What command configures the AWS CLI with your credentials? Where are they stored?
4. How do you retrieve temporary credentials from an EC2 instance that has an IAM role?
5. What is the difference between `aws s3 cp` and `aws s3 sync`?
6. In AWS VPC, what is the difference between a Security Group and a NACL?
7. What does a NAT Gateway do and why would you put a NAT Gateway in a public subnet?
8. What is the GCP equivalent of AWS EC2? What is the Azure equivalent?
9. How do you pass a startup script to an EC2 instance? To a GCE instance? To an Azure VM?
10. What is a SAS token in Azure and how does it differ from a storage account key?
11. How does AWS IAM role trust policy work? What is the `Principal` field?
12. What is the difference between AWS IAM roles and GCP service accounts?
13. How do you connect to a private EC2 instance that has no public IP and no SSH key?
14. What is the difference between AWS S3 Standard-IA, S3 Glacier, and S3 Glacier Deep Archive?
15. What strategies can you use to reduce cloud costs across all three providers?

**Score:** 12/15 correct = ready for Part 51.

---

*Linux SysAdmin Course | Part 50 of ∞ | Reverse Engineering Approach*
*Previous → Part 49: Security Hardening and Auditing*
*Next → Part 51: Infrastructure as Code — Terraform*

[← Previous](part49.md) | [Next →](part51.md)
