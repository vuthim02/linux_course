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





[← Previous](04-section-3-gcp-cli-gcloud.md) | [↑ Index](index.md) | [Next →](06-section-5-compute.md)
