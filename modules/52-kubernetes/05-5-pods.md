## 5. Pods

A Pod is the smallest deployable unit in Kubernetes. It wraps one or more containers that share:
- Network namespace (same IP, same port space, can communicate via `localhost`)
- Storage volumes (emptyDir, hostPath, etc.)
- Lifecycle (started, stopped together)

### Pod Spec — Full Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: production
  labels:
    app: web
    tier: frontend
  annotations:
    prometheus.io/scrape: "true"
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
      protocol: TCP
    env:
    - name: DB_HOST
      value: "postgres.production.svc.cluster.local"
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 3
      periodSeconds: 5
    startupProbe:
      httpGet:
        path: /startup
        port: 80
      failureThreshold: 30
      periodSeconds: 10
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
      readOnly: true
    - name: data
      mountPath: /var/www/html
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: data
    emptyDir: {}
  restartPolicy: Always    # Always, OnFailure, Never
  terminationGracePeriodSeconds: 30
```

### Init Containers

Init containers run to completion before app containers start. They are ideal for setup tasks: waiting for a database, seeding data, permissions fixups.

```yaml
spec:
  initContainers:
  - name: init-db-wait
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      until nc -z postgres 5432; do
        echo "waiting for postgres..."
        sleep 2
      done
  - name: init-data-migrate
    image: myapp/migrate:1.0
    env:
    - name: DB_URL
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: url
```

### Sidecar Pattern

A sidecar is an additional container in the pod that enhances the main container — logging, metrics, proxy, sync.

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: sidecar-logger
    image: fluent/fluent-bit:2.1
    volumeMounts:
    - name: pod-logs
      mountPath: /var/log/app
  volumes:
  - name: pod-logs
    emptyDir: {}
```

### Pod Lifecycle

```
Pending ──► Running ──► Succeeded (for Jobs)
  │            │
  │            └────────► Failed
  │
  └──► CrashLoopBackOff (container exits repeatedly)
```

Phases:
- **Pending**: Pod accepted, images being pulled, waiting for scheduler.
- **Running**: At least one container running (or in the process of starting/restarting).
- **Succeeded**: All containers terminated with exit code 0 (for Jobs).
- **Failed**: All containers terminated with non-zero exit code.
- **CrashLoopBackOff**: Container exits repeatedly. Kubelet waits longer between restarts (10s, 20s, 40s, 80s, 160s, max 300s).

Conditions:
- **PodScheduled**: Pod assigned to a node.
- **ContainersReady**: All containers ready probes pass.
- **Initialized**: All init containers completed.
- **Ready**: Pod is ready to serve traffic (readiness probe passes).

```bash
# Debug lifecycle issues
kubectl describe pod failing-pod
kubectl logs failing-pod --previous
kubectl get events --field-selector involvedObject.name=failing-pod
```





[← Previous](04-4-kubectl-essentials.md) | [↑ Index](index.md) | [Next →](06-6-workloads.md)
