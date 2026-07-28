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





[← Previous](03-section-2-aws-cli.md) | [↑ Index](index.md) | [Next →](05-section-4-azure-cli-az.md)
