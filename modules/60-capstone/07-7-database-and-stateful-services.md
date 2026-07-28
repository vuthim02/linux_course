## 7. Database and Stateful Services

### PostgreSQL Schema Migration (Alembic)

```bash
# Initialize Alembic
pip install alembic asyncpg
alembic init alembic

# Generate initial migration
alembic revision --autogenerate -m "initial_schema"
```

```python
# alembic/versions/0001_initial_schema.py
"""initial_schema

Revision ID: 0001
Revises:
Create Date: 2024-01-01
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "items",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_items_created_at", "items", ["created_at"], postgresql_using="brin")

def downgrade():
    op.drop_index("idx_items_created_at")
    op.drop_table("items")
```

### PgBouncer Connection Pooling

```yaml
# helm/pgbouncer/values.yaml
pgbouncer:
  image: edoburu/pgbouncer:1.22
  pool_mode: transaction
  default_pool_size: 25
  max_client_conn: 200
  reserve_pool_size: 5
  reserve_pool_timeout: 3
  query_timeout: 30
  idle_transaction_timeout: 60
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

```yaml
# helm/pgbouncer/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pgbouncer
  template:
    metadata:
      labels:
        app: pgbouncer
    spec:
      containers:
        - name: pgbouncer
          image: "{{ .Values.pgbouncer.image }}"
          ports:
            - containerPort: 5432
              name: postgres
          env:
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: password
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: host
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: capstone-api-db
                  key: dbname
          envFrom:
            - configMapRef:
                name: pgbouncer-config
          resources:
            {{- toYaml .Values.pgbouncer.resources | nindent 12 }}
```

### RDS Automated Backups

```bash
# Manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier capstone-cluster-database \
  --db-snapshot-identifier manual-snapshot-$(date +%Y-%m-%d-%H%M)

# Copy snapshot to another region for DR
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier arn:aws:rds:us-east-1:ACCOUNT_ID:snapshot:manual-snapshot-XXXX \
  --target-db-snapshot-identifier dr-snapshot-$(date +%Y-%m-%d) \
  --source-region us-east-1 \
  --region us-west-2

# Automated backup retention is set in Terraform (backup_retention_period)
```

### Database Backup Validation

```bash
#!/bin/bash
# scripts/validate-backup.sh
set -euo pipefail

SNAPSHOT_ID=$(aws rds describe-db-snapshots \
  --db-instance-identifier capstone-cluster-database \
  --query "DBSnapshots[-1].DBSnapshotIdentifier" \
  --output text)

echo "Validating snapshot: $SNAPSHOT_ID"

STATUS=$(aws rds describe-db-snapshots \
  --db-snapshot-identifier "$SNAPSHOT_ID" \
  --query "DBSnapshots[0].Status" \
  --output text)

if [ "$STATUS" = "available" ]; then
  echo "✅ Snapshot $SNAPSHOT_ID is available and valid"
  exit 0
else
  echo "❌ Snapshot $SNAPSHOT_ID status: $STATUS"
  exit 1
fi
```





[← Previous](06-6-cicd-pipeline.md) | [↑ Index](index.md) | [Next →](08-8-secrets-and-configuration.md)
