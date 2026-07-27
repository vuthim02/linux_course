## 11. LogQL

**Stream selector + pipeline:** `{label="value"} |= "search" != "exclude" | json | line_format "{{.msg}}"`

**Line filters:** `|=` (contains), `!=` (not contains), `|~` (regex match), `!~` (regex not match).

**Parsers:** `| json`, `| logfmt`, `| regexp "^(?P<name>\\S+)"`, `| unpack`.

**Label filter (after parsing):**
```
{job="nginx"} | json | path = "/api/login" | status >= 500
{job="app"} | logfmt | duration > 1000 | level = "error"
```

**Line format:**
```
{job="nginx"} | json | line_format "{{.status}} {{.path}} {{.duration}}ms"
{job="app"} | logfmt | line_format "[{{.level}}] {{.message}}"
```

**Metric queries:**

```logql
# Error count per 5m
sum(count_over_time({namespace="production"} |= "error" [5m])) by (level)

# Error rate
rate({job="nginx"} |= "error" [5m])

# Average duration
avg_over_time({job="nginx"} | json | unwrap duration_ms [5m]) by (path)

# p99 duration
quantile_over_time(0.99, {job="nginx"} | json | unwrap duration_ms [5m]) by (path)

# Error percentage
sum(rate({job="nginx"} | json | status >= 500 [5m])) by (method)
  / sum(rate({job="nginx"} | json [5m])) by (method) * 100

# Top 5 error paths
topk(5, sum(count_over_time({job="nginx"} |= "error" | json [1h])) by (path))

# Slow requests
{job="nginx"} | json | duration_ms > 5000

# Traces from logs
{namespace="production"} | logfmt | trace_id != "" | line_format "trace={{.trace_id}} {{.message}}"
```

---



---

[← Previous](10-10-loki.md) | [↑ Index](index.md) | [Next →](12-12-tempo.md)
