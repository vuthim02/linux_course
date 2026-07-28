## 12. Tempo

**Trace storage backend:** Stores traces in object storage (S3/GCS/MinIO), indexed by trace ID via bloom filters.

```yaml
# /etc/tempo/tempo.yml
server:
  http_listen_port: 3200
distributor:
  receivers:
    otlp:
      protocols:
        grpc: {endpoint: 0.0.0.0:4317}
        http: {endpoint: 0.0.0.0:4318}
    jaeger:
      protocols:
        grpc: {endpoint: 0.0.0.0:14250}
        thrift_compact: {endpoint: 0.0.0.0:6831}
    zipkin: {endpoint: 0.0.0.0:9411}
ingester:
  trace_idle_period: 30s
  max_block_duration: 30m
storage:
  trace:
    backend: s3
    s3:
      bucket: tempo-traces
      endpoint: s3.amazonaws.com
    wal: {path: /var/lib/tempo/wal}
overrides:
  max_bytes_per_trace: 5000000
```

**Jaeger/Zipkin compatibility:** Tempo accepts Jaeger (gRPC :14250, Thrift :6831) and Zipkin (:9411) formats. Drop-in replacement.

**Trace discovery:**
- **Service Graph:** Metrics from trace connections (request rate, error rate, latency) stored in Prometheus
- **TraceQL:** `{.service.name = "frontend" && .status = error}`, `{.duration > 1s}`, nested span conditions
- **Grafana Explore:** Search by trace ID, labels, or TraceQL

**Sampling:**
- **Head-based:** Decision at SDK. `OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=0.1`
- **Tail-based:** Decision in Tempo after seeing all spans. Policies: `status_code` (keep errors), `latency` (keep slow), `probabilistic`.





[← Previous](11-11-logql.md) | [↑ Index](index.md) | [Next →](13-13-opentelemetry-otel.md)
