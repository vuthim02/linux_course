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



---

[← Previous](02-section-1-cloud-computing-models.md) | [↑ Index](index.md) | [Next →](04-section-3-gcp-cli-gcloud.md)
