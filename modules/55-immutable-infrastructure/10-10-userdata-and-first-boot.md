## 10. Userdata and First Boot

### When to Use Userdata

Userdata is for environment-specific configuration that should NOT be in the golden image:

| Baked in Image | Userdata (runtime) |
|---------------|-------------------|
| OS + kernel parameters | Environment (dev/staging/prod) |
| Middleware (nginx, node, python) | Database connection strings |
| Security patches | Feature flags |
| Hardening configs | Service discovery endpoints |
| Monitoring agents | TLS certificates (from ACM) |
| Logging daemons | Application config overrides |
| Systemd service files | Secrets from Vault/Secrets Manager |

### Userdata Script Example

```bash
#!/bin/bash
# userdata.sh — runs on first boot of each instance
set -euo pipefail

exec > /var/log/userdata.log 2>&1

echo "=== Userdata: Starting ==="

# Source environment variables from instance tags
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ENVIRONMENT=$(aws ec2 describe-tags \
  --region "$REGION" \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Environment" \
  --query 'Tags[0].Value' \
  --output text)

echo "Environment: $ENVIRONMENT"

# Fetch secrets from AWS Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "myapp/${ENVIRONMENT}/database" \
  --query SecretString \
  --output text)

DB_HOST=$(echo "$DB_SECRET" | jq -r '.host')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASS=$(echo "$DB_SECRET" | jq -r '.password')

# Write application config
cat > /opt/myapp/config.json <<CONFIG
{
  "environment": "${ENVIRONMENT}",
  "db_host": "${DB_HOST}",
  "db_port": ${DB_PORT},
  "db_name": "${DB_NAME}",
  "db_user": "${DB_USER}",
  "db_password": "${DB_PASS}",
  "log_level": "${LOG_LEVEL:-info}",
  "feature_flags": {
    "new_checkout": ${NEW_CHECKOUT:-false},
    "dark_mode": ${DARK_MODE:-true}
  }
}
CONFIG

# Start application
systemctl start myapp
systemctl enable myapp

# Register with service discovery
aws servicediscovery register-instance \
  --region "$REGION" \
  --service-id "srv-abcdef123" \
  --instance-id "$INSTANCE_ID" \
  --attributes "AWS_INSTANCE_IPV4=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4),AWS_INSTANCE_PORT=8080"

echo "=== Userdata: Complete ==="
```

### Hybrid Approach

Most teams use a hybrid: bake the OS, security hardening, and middleware into the image; use userdata for environment-specific application config and secrets.

```
Golden Image contains:
  ├── Ubuntu 22.04 + kernel tuning
  ├── CIS Level 1 hardening
  ├── Node.js 20.x runtime
  ├── Nginx with base config
  ├── Prometheus node exporter
  ├── CloudWatch agent
  ├── Systemd service file for myapp
  └── Trivy-scanned (no CRITICAL vulns)

Userdata (per-environment):
  ├── Environment name (dev/staging/prod)
  ├── DB connection details (from Secrets Manager)
  ├── Feature flags
  ├── Log levels
  └── Service discovery registration
```

### Packer + Cloud-Init + Userdata Together

```hcl
# In Packer: Reset cloud-init so userdata runs fresh
provisioner "shell" {
  inline = [
    "sudo cloud-init clean --logs",
    "sudo rm -rf /var/lib/cloud/instances/*"
  ]
}

# In the deployed ASG: Userdata is provided via launch template
# The userdata can be cloud-config YAML or a bash script
```





[← Previous](09-9-deployment-strategies-for-immutable.md) | [↑ Index](index.md) | [Next →](11-11-troubleshooting-immutable.md)
