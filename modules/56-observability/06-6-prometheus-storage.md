## 6. Prometheus Storage

**Local TSDB:** Data organized into 2-hour **blocks**. Each block: `chunks/` (Gorilla XOR compressed, ~1.3 bytes/sample), `index` (inverted label→series posting lists), `meta.json`, `tombstones` (soft deletes). **WAL** (write-ahead log) ensures crash recovery — samples written to WAL first, then in-memory head block, flushed every 2h. **Compaction** merges small blocks into larger ones, removes tombstones.

**Remote Write:** Forward samples to Thanos, Cortex, Mimir, VictoriaMetrics, or cloud-managed Prometheus.

```yaml
remote_write:
  - url: https://thanos-receiver.example.com/api/v1/receive
    basic_auth: {username: prometheus, password: secret}
    queue_config:
      max_shards: 200
      max_samples_per_send: 500
      batch_send_deadline: 5s
```

**Downsampling:** Thanos/Mimir downsample: raw (2h, 30d) → 5m (min/max/avg, 6mo) → 1h (min/max/avg, 5yr). Prometheus local TSDB does not downsample.

**Storage sizing:** ~2 bytes/sample compressed. 500K series × 1 sample/15s × 15d × 2 bytes ≈ 86 GB. 1M series @ 10s interval, 15d ≈ 260 GB.

### Key Takeaways

- **Gorilla XOR compression** is remarkably efficient (~1.3 bytes/sample) — Prometheus can store months of data locally
- **2-hour block windows** are a fundamental design choice — they balance write throughput with query performance
- **Remote write** is the escape hatch when local storage is not enough — pair with Thanos or Mimir for long-term retention
- **Downsampling** only works with remote backends; plan your retention strategy accordingly
- **Storage sizing** is often underestimated — profile your cardinality and scrape interval before committing to disk





[← Previous](05-5-prometheus-service-discovery-and.md) | [↑ Index](index.md) | [Next →](07-7-alertmanager.md)
