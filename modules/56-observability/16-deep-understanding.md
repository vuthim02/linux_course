## Deep Understanding

**Monitoring anti-patterns to avoid:**
- **Dashboard overload:** 50 panels per dashboard — no one reads it. Create focused dashboards (RED per service, USE per node, SLO compliance).
- **Alert fatigue:** 200 alerts per night — people ignore them. Tune thresholds, use `for:` to debounce, group by severity, inhibit noise.
- **Metric dumping:** Exposing every possible metric from an application. Choose cardinality-aware metrics. Use histograms, not summary + quantile label combinations.
- **Label abuse:** `method`, `path`, `status` as labels on a counter is fine. `url`, `user_agent`, `request_id` as labels will crash Prometheus.

**How Prometheus TSDB stores data:** Incoming samples go to WAL first (crash recovery), then in-memory head block. Every 2 hours, head is frozen into an immutable block: `chunks/` (Gorilla XOR compressed floats, ~1.3 bytes/sample), `index` (inverted label→series posting lists, delta-encoded and varint-compressed). Compaction merges smaller blocks into larger ones (removes tombstones, deduplicates). Query execution: parse PromQL → AST → look up posting lists → intersect/union → read chunk references → mmap decompress → decode samples → apply functions.

**Pull vs Push:** Pull (Prometheus) — server discovers and scrapes targets. Advantages: dead target detection, central control, federation, simple HA, targets don't need to know the monitoring system. Push (Graphite/InfluxDB/Datadog) — targets send to receiver. Better for short-lived jobs (batch/serverless), firewalled environments, high-frequency metrics.

**Prometheus vs VictoriaMetrics:** VictoriaMetrics is a drop-in Prometheus-compatible alternative that uses less RAM (no head block in RAM, uses mmap), has better disk compression (e.g., `ZSTD` instead of `gzip` for chunks), supports downsampling natively, and handles high cardinality better. It speaks both PromQL and MetricsQL (superset). Can be used as a remote write backend or a Prometheus replacement.

**Loki cost-effective storage:** Only labels (metadata) are indexed, not log content. Content is compressed (gzip/snappy) into chunks stored in object storage. Index is ~1% of data vs Elasticsearch's 50-100%. Queries scan compressed chunks in parallel — slower than full-text search but dramatically cheaper.

**OTEL Collector pipeline:** Receivers (OTLP, hostmetrics, filelog) → Processors (batch for efficiency, memory_limiter to prevent OOM, filter to drop data, attributes to add metadata, tail_sampling to keep important traces) → Exporters (OTLP to backends, Prometheus HTTP, debug). Connectors link pipelines (spanmetrics creates metrics from traces). Fan-out sends data to multiple exporters. Queued retry provides at-least-once delivery. Tail-based sampling decisions: wait 30s for all spans, then keep ALL errors + ALL slow traces + 10% of rest.

---



---

[← Previous](15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](17-observability-maturity-model.md)
