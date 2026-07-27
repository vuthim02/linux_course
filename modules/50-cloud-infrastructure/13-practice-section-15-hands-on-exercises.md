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



---

[← Previous](12-section-11-multi-cloud-comparison.md) | [↑ Index](index.md) | [Next →](14-deep-understanding-how-cloud-infrastructure.md)
