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





[← Previous](14-deep-understanding-how-cloud-infrastructure.md) | [↑ Index](index.md) | [Next →](16-whats-coming-in-part-51.md)
