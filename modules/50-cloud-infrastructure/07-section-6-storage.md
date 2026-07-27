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



---

[← Previous](06-section-5-compute.md) | [↑ Index](index.md) | [Next →](08-section-7-networking.md)
