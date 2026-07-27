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



---

[← Previous](07-section-6-storage.md) | [↑ Index](index.md) | [Next →](09-section-8-iam-identity-and.md)
