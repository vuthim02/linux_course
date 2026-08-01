## Section 11: Thanos, VictoriaMetrics, and Datadog

### Thanos — Prometheus High Availability and Long-Term Storage

Thanos extends Prometheus with global query, unlimited retention, and HA.

```yaml
# Thanos Sidecar (runs alongside Prometheus)
thanos sidecar \
  --tsdb.path /prometheus \
  --objstore.config-file bucket_config.yaml \
  --prometheus.url http://localhost:9090

# Thanos Querier (global view)
thanos query \
  --store 10.0.0.1:10901 \
  --store 10.0.0.2:10901

# Store config (S3)
# bucket_config.yaml
type: S3
config:
  bucket: thanos-metrics
  endpoint: s3.amazonaws.com
  access_key: ${AWS_ACCESS_KEY}
  secret_key: ${AWS_SECRET_KEY}
```

### VictoriaMetrics — Prometheus-Compatible TSDB

Single-node or cluster. 10x more efficient than Prometheus for storage.

```bash
# Single-node
./victoria-metrics-prod -storageDataPath ./data \
  -retentionPeriod 12

# Write with Prometheus remote write
# remote_write:
#   - url: http://victoria-metrics:8428/api/v1/write

# Query with PromQL at /api/v1/query
```

### Datadog — SaaS Observability Platform

```bash
# Install agent
DD_AGENT_MAJOR_VERSION=7 \
DD_API_KEY=<your_key> \
DD_SITE="datadoghq.com" \
bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

# Config: /etc/datadog-agent/datadog.yaml
# Integrations: /etc/datadog-agent/conf.d/
```

**Key integrations**: Docker, Kubernetes, AWS, GCP, custom metrics via DogStatsD and API.
