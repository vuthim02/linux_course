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





[← Previous](08-section-7-networking.md) | [↑ Index](index.md) | [Next →](10-section-9-cloud-ssh-access.md)
