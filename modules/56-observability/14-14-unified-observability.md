## 14. Unified Observability

**Grafana workflow:**
1. Metric spike in Prometheus → click "Logs" → jump to Loki with same time range
2. Error logs → click trace ID (via derived field) → jump to Tempo trace
3. Full distributed trace with each span's timing

**Exemplars:** Metric samples carrying trace ID. Configured in Prometheus datasource:
```yaml
jsonData:
  exemplarTraceIdDestinations:
    - name: traceID
      url: http://tempo:3200/explore?traceId=$${__value.raw}
```

**Derived fields (Loki):**
```yaml
datasources:
  - name: Loki
    jsonData:
      derivedFields:
        - name: traceID
          matcherRegex: "trace_id=(\\w+)"
          url: "http://tempo:3200/explore?traceId=$${__value.raw}"
```

**Correlations (provisioning):**
```yaml
apiVersion: 1
correlations:
  - sourceUID: prometheus-uid
    targetUID: tempo-uid
    label: "View Trace"
    config:
      type: query
      field: "traceID"
      target: {expr: '{.traceID = "${traceID}"}'}
```

**Kubernetes observability (kube-prometheus-stack):**
```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi
```

Key K8s metrics: `kube_pod_status_phase`, `kube_node_status_condition`, `kube_deployment_status_replicas_available`.

**Cost of observability:**

| Factor | Impact | Mitigation |
|--------|--------|------------|
| High cardinality | More RAM, disk, network | Drop high-cardinality labels |
| Retention | Linear storage growth | Downsample, tiered storage |
| Scrape interval | 1s vs 30s = 30x more data | 15s critical, 60s non-critical |
| Log volume | 50 GB/day = $150/mo cloud | Filter debug at source |
| Trace volume | ~20 bytes/span, millions/s | Sample 1% → 100x reduction |

**Recommended for 10 hosts / 50 pods:** Prometheus 8GB RAM/30d, Loki 4GB/30d, Tempo 4GB/7d/10% sampling, OTEL Collector 512MB.





[← Previous](13-13-opentelemetry-otel.md) | [↑ Index](index.md) | [Next →](15-hands-on-practices.md)
