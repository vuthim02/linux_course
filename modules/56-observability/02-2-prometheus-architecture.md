## 2. Prometheus Architecture

**Pull Model:** Prometheus scrapes HTTP `/metrics` endpoints. Benefits: dead target detection, central control over scrape frequency, federation, simple HA.

```
Prometheus ── scrape :9100/metrics ──→ node_exporter
           ── scrape :8080/metrics ──→ application
           ── scrape :9115/probe   ──→ blackbox_exporter
```

**TSDB (Time Series Database):** Stores data in 2-hour blocks. Each block: `chunks/` (XOR-compressed samples), `index` (inverted label→series mapping), `meta.json`, `tombstones`. WAL for crash recovery.

```
tsdb/
├── 01G7XYZ.../ {chunks/, index, meta.json, tombstone}
├── wal/ {000001, checkpoint.000002/}
└── chunks_head/
```

**Service Discovery:**

```yaml
# kubernetes_sd_configs
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

# ec2_sd_configs
  - job_name: aws-instances
    ec2_sd_configs:
      - region: us-east-1
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance

# file_sd_configs
  - job_name: custom
    file_sd_configs:
      - files: ['/etc/prometheus/targets/*.json']
        refresh_interval: 30s
```

**Target file (`targets/web.json`):**
```json
[{"targets": ["10.0.1.1:9100"], "labels": {"env": "prod", "team": "web"}}]
```

**Relabeling:** `relabel_configs` (pre-scrape, target labels) vs `metric_relabel_configs` (post-scrape, metric labels). Actions: `replace`, `keep`, `drop`, `hashmod`, `labelmap`, `labeldrop`, `keepequal`, `dropequal`.

**Target Status:** `up == 0` → targets that failed scrape.

---



---

[← Previous](01-1-three-pillars-of-observability.md) | [↑ Index](index.md) | [Next →](03-3-advanced-promql.md)
