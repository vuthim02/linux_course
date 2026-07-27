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



---

[← Previous](09-section-8-iam-identity-and.md) | [↑ Index](index.md) | [Next →](11-section-10-cloud-cost-management.md)
