## 13. OpenTelemetry (OTEL)

**OTLP protocol:** Vendor-agnostic gRPC/HTTP-protobuf telemetry protocol.

```
Application (SDK) ──OTLP──→ OTEL Collector ──OTLP──→ Tempo (traces)
                                           ──OTLP──→ Prometheus (metrics)
                                           ──OTLP──→ Loki (logs)
```

**OTEL Collector pipeline:** Receivers → Processors → Exporters + Connectors (between pipelines).

**Full collector config (`/etc/otel/config.yml`):**
```yaml
receivers:
  otlp:
    protocols:
      grpc: {endpoint: 0.0.0.0:4317}
      http: {endpoint: 0.0.0.0:4318}
  hostmetrics:
    collection_interval: 60s
    scrapers: {cpu: {}, memory: {}, disk: {}, network: {}}
  filelog:
    include: [/var/log/**/*.log]

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512
    spike_limit_mib: 128
  attributes:
    actions:
      - key: environment
        value: production
        action: upsert
  filter:
    logs:
      include:
        match_type: strict
        record_attributes: [{Key: level, Value: error}]
  probabilistic_sampler:
    sampling_percentage: 15
  tail_sampling:
    decision_wait: 30s
    num_traces: 10000
    policies:
      - name: errors
        type: status_code
        config: {status_code: {status_codes: [ERROR]}}
      - name: slow
        type: latency
        config: {latency: {threshold_ms: 1000}}
      - name: probabilistic
        type: probabilistic
        config: {sampling_percentage: 10}

exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls: {insecure: true}
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: otel
  otlphttp/loki:
    endpoint: https://loki:3100/otlp
    tls: {insecure: true}
  debug:
    verbosity: detailed

connectors:
  spanmetrics:
    histogram:
      explicit:
        buckets: [5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s]
    dimensions:
      - name: http.method
      - name: http.status_code
    metrics_flush_interval: 30s

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes, tail_sampling]
      exporters: [otlp/tempo, debug, spanmetrics]
    metrics:
      receivers: [otlp, hostmetrics]
      processors: [memory_limiter, batch, filter]
      exporters: [prometheus, debug]
    logs:
      receivers: [otlp, filelog]
      processors: [memory_limiter, batch]
      exporters: [otlphttp/loki, debug]
    metrics/spanmetrics:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [prometheus]
```

**Auto-instrumentation:**

**Java:** `-javaagent:opentelemetry-javaagent.jar -Dotel.service.name=my-service -Dotel.exporter.otlp.endpoint=http://otel-collector:4317`

**Python:**
```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install
OTEL_SERVICE_NAME=my-service OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 \
  opentelemetry-instrument python myapp.py
```

**Go:**
```go
import "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"

exporter, _ := otlptracegrpc.New(ctx, otlptracegrpc.WithEndpoint("otel-collector:4317"),
    otlptracegrpc.WithInsecure())
tp := trace.NewTracerProvider(trace.WithBatcher(exporter))
otel.SetTracerProvider(tp)
```

**.NET:**
```csharp
builder.Services.AddOpenTelemetry().WithTracing(tracing => tracing
    .AddAspNetCoreInstrumentation()
    .AddOtlpExporter(o => o.Endpoint = new Uri("http://otel-collector:4317")));
```

**Node.js:**
```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
OTEL_SERVICE_NAME=my-service OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 \
  node --require @opentelemetry/auto-instrumentations-node/register app.js
```

**Manual instrumentation (Python):**
```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_payment") as span:
    span.set_attribute("payment.id", payment_id)
    span.set_attribute("payment.amount", 99.99)
    span.add_event("payment.authorized", {"provider": "stripe"})
    try:
        result = charge(payment_id)
        span.set_status(trace.StatusCode.OK)
    except Exception as e:
        span.record_exception(e)
        span.set_status(trace.StatusCode.ERROR, str(e))
```

**Sampling:** Head-based (decision at SDK per trace, propagates via W3C trace-context) vs tail-based (decision in collector after seeing all spans — keeps ALL errors, ALL slow, 10% of rest).

---



---

[← Previous](12-12-tempo.md) | [↑ Index](index.md) | [Next →](14-14-unified-observability.md)
