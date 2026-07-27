## 9. Capacity Planning

### Demand Forecasting

```python
#!/usr/bin/env python3
"""capacity_forecast.py — 6-month capacity planning"""
import requests
from datetime import datetime, timedelta

PROMETHEUS = "http://prometheus:9090"
end = datetime.now()
start = end - timedelta(days=180)

def get_metric(query, start, end, step="1d"):
    params = {"query": query, "start": start.isoformat(), "end": end.isoformat(), "step": step}
    r = requests.get(f"{PROMETHEUS}/api/v1/query_range", params=params)
    return r.json()["data"]["result"]

def forecast(values, days_ahead):
    n = len(values)
    xs = list(range(n))
    ys = values
    sum_x = sum(xs); sum_y = sum(ys)
    sum_xy = sum(x*y for x,y in zip(xs,ys)); sum_xx = sum(x*x for x in xs)
    slope = (n*sum_xy - sum_x*sum_y) / (n*sum_xx - sum_x*sum_x)
    intercept = (sum_y - slope*sum_x) / n
    return intercept + slope * (n + days_ahead - 1), slope

data = get_metric("avg_over_time(sum(rate(http_requests_total{job='checkout'}[1d]))[30d:])", start, end)
if data and data[0].get("values"):
    vals = [float(v[1]) for v in data[0]["values"]]
    fcast, slope = forecast(vals, 90)
    print(f"Current: {vals[-1]:.0f} req/s")
    print(f"Growth: {slope:.1f} req/s per day")
    print(f"90-day forecast: {fcast:.0f} req/s")
```

### Seasonal Patterns
```promql
sum(rate(http_requests_total[1w])) offset 1w
sum(rate(http_requests_total[1h])) by (hour_of_day)
```

### Load Testing

| Tool | Language | Best For |
|---|---|---|
| Locust | Python | HTTP, custom scenarios |
| k6 | JavaScript | CI/CD, thresholds |
| vegeta | Go | CLI load testing |
| wrk | C | Raw throughput |

### Locust Test
```python
from locust import HttpUser, task, between
import random

class CheckoutUser(HttpUser):
    wait_time = between(1, 5)
    @task(3)
    def browse(self): self.client.get("/api/products")
    @task(1)
    def view_cart(self): self.client.get("/api/cart")
    @task(2)
    def add_to_cart(self):
        self.client.post("/api/cart", json={"product_id": random.randint(1,1000), "quantity": 1})
    @task(1)
    def checkout(self):
        self.client.post("/api/checkout", json={
            "cart_id": "cart_12345", "payment_method": "card",
            "shipping_address": {"street": "123 Main St", "city": "Portland", "state": "OR", "zip": "97201"}
        })
```

### k6 Load Test
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 },
  ],
  thresholds: { http_req_duration: ['p(99)<200'], http_req_failed: ['rate<0.001'] },
};

export default function () {
  const res = http.get('https://api.example.com/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

### Right-Sizing & Scaling Triggers

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-api-hpa
spec:
  minReplicas: 3
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: { type: Utilization, averageUtilization: 70 }
```

```promql
avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) < 0.3
sum(rate(http_requests_total[5m])) > expected_capacity * 0.7
avg(rabbitmq_queue_messages_ready{queue="checkout"}[5m]) > 1000
```

---



---

[← Previous](09-8-blameless-postmortems.md) | [↑ Index](index.md) | [Next →](11-10-release-engineering.md)
