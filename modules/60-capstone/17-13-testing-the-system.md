## 13. Testing the System

### Load Test with k6

```javascript
// tests/load-test.js
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const latencyTrend = new Trend('latency');

export const options = {
  stages: [
    { duration: '2m', target: 50 },    // Ramp up to 50 users
    { duration: '5m', target: 200 },   // Ramp to 200 users
    { duration: '10m', target: 500 },  // Ramp to 500 users
    { duration: '5m', target: 1000 },  // Peak: 1000 users
    { duration: '5m', target: 500 },   // Scale down
    { duration: '2m', target: 0 },     // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    errors: ['rate<0.01'],
    http_reqs: ['rate>100'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8000';

export default function () {
  group('health check', () => {
    const res = http.get(`${BASE_URL}/health`);
    check(res, { 'health status is 200': (r) => r.status === 200 });
    latencyTrend.add(res.timings.duration);
  });

  group('list items', () => {
    const res = http.get(`${BASE_URL}/api/v1/items`);
    check(res, {
      'list items status is 200': (r) => r.status === 200,
      'response is array': (r) => Array.isArray(JSON.parse(r.body)),
    });
    errorRate.add(res.status >= 400);
    latencyTrend.add(res.timings.duration);
  });

  group('create item', () => {
    const payload = { name: `load-test-${__VU}-${__ITER}` };
    const res = http.post(`${BASE_URL}/api/v1/items?name=${payload.name}`);
    check(res, {
      'create item status is 200': (r) => r.status === 200,
      'has id': (r) => JSON.parse(r.body).id !== undefined,
    });
    errorRate.add(res.status >= 400);
  });

  sleep(1);
}
```

```bash
# Run load test
k6 run tests/load-test.js -e API_URL=https://api.capstone.example.com

# Run with output to Grafana
k6 run tests/load-test.js \
  -e API_URL=https://api.capstone.example.com \
  --out influxdb=http://influxdb.monitoring:8086/k6
```

### Chaos Experiment — LitmusChaos

```bash
# Install LitmusChaos
helm repo add litmus https://litmuschaos.github.io/litmus-helm/
helm repo update

helm upgrade --install litmus litmus/litmus \
  --namespace litmus \
  --create-namespace \
  --set portal.frontend.service.type=ClusterIP

# Access Litmus UI
kubectl port-forward -n litmus service/litmus-frontend 9091:9091
# Open http://localhost:9091
```

```yaml
# chaos/pod-kill.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-kill-chaos
  namespace: production
spec:
  engineState: active
  annotationCheck: false
  appinfo:
    appns: production
    applabel: app.kubernetes.io/name=capstone-api
    appkind: deployment
  chaosServiceAccount: litmus-sa
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "true"
            - name: RAMP_TIME
              value: "10"
        probe:
          - name: check-app-availability
            type: httpProbe
            httpProbe/inputs:
              url: http://capstone-api.production:80/health
              expectedStatusCode: 200
            mode: Continuous
            runProperties:
              probeTimeout: 5s
              interval: 2s
              retry: 1
---
# chaos/network-partition.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-partition
  namespace: production
spec:
  engineState: active
  annotationCheck: false
  appinfo:
    appns: production
    applabel: app.kubernetes.io/name=capstone-api
    appkind: deployment
  chaosServiceAccount: litmus-sa
  experiments:
    - name: pod-network-partition
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: TARGET_PODS
              value: "1"
---
# chaos/cpu-stress.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: cpu-stress
  namespace: production
spec:
  engineState: active
  annotationCheck: false
  appinfo:
    appns: production
    applabel: app.kubernetes.io/name=capstone-api
    appkind: deployment
  chaosServiceAccount: litmus-sa
  experiments:
    - name: pod-cpu-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: CPU_CORE
              value: "2"
            - name: TARGET_PODS
              value: "1"
```

### Observing Self-Healing

```bash
# Start watching HPA and pods in one window
watch -n 2 'kubectl get pods -n production -o wide && echo "---" && kubectl get hpa -n production'

# In another window, run chaos experiment
kubectl apply -f chaos/pod-kill.yaml

# Observe:
# 1. Pods get terminated
# 2. ReplicaSet creates replacements
# 3. HPA may scale up due to increased load
# 4. Cluster-autoscaler may add nodes
# 5. Everything recovers automatically

# Verify SLOs during chaos
# In Grafana, observe:
# - Request rate dips then recovers
# - Error rate spikes briefly
# - Latency increases during recovery
# - Error budget consumed slightly
```

### Rollback Verification

```bash
# Rollback to previous Helm revision
helm history capstone-api -n production
helm rollback capstone-api 1 -n production --wait --timeout 5m

# Verify
kubectl rollout status deployment/capstone-api -n production

# Git revert for permanent rollback
git revert HEAD --no-edit
git push origin main
```

---



---

[← Previous](16-resolution-log.md) | [↑ Index](index.md) | [Next →](18-14-documentation-and-handover.md)
