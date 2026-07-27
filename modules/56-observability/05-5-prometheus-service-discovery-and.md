## 5. Prometheus Service Discovery and Relabeling

**relabel_configs vs metric_relabel_configs:** `relabel_configs` applied before scrape (target discovery, `__address__`). `metric_relabel_configs` applied after scrape (series labels, drop/keep).

**Full action reference:**

| Action | Description |
|--------|-------------|
| `replace` | Set `target_label` from `source_labels` regex capture groups |
| `keep` | Drop target if source_labels don't match regex |
| `drop` | Drop target if source_labels match regex |
| `hashmod` | Hash source_labels mod `modulus`, store in `target_label` |
| `labelmap` | Rename labels matching regex |
| `labeldrop` | Delete labels matching regex |
| `keepequal` | Keep if source_labels == target_label value |
| `dropequal` | Drop if source_labels == target_label value |

**Complex Kubernetes relabeling:**
```yaml
relabel_configs:
  - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
    target_label: app
  - source_labels: [__meta_kubernetes_namespace]
    target_label: namespace
  - source_labels: [__meta_kubernetes_pod_node_name]
    target_label: node
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    action: keep
    regex: true
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    action: replace
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: $1:$2
    target_label: __address__
```

**Drop high-cardinality labels via metric_relabel_configs:**
```yaml
metric_relabel_configs:
  - source_labels: [user_id]
    regex: ".+"
    action: drop
```

---



---

[← Previous](04-4-prometheus-exporters.md) | [↑ Index](index.md) | [Next →](06-6-prometheus-storage.md)
