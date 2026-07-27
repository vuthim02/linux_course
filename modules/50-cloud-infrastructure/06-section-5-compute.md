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



---

[← Previous](05-section-4-azure-cli-az.md) | [↑ Index](index.md) | [Next →](07-section-6-storage.md)
