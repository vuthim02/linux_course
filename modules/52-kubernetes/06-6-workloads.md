## 6. Workloads

### Deployments

A Deployment manages a ReplicaSet, which in turn manages Pods. Use Deployments for stateless applications.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: production
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1        # max pods that can be unavailable during update
      maxSurge: 1              # max extra pods over desired count
  minReadySeconds: 5
  revisionHistoryLimit: 3      # keep 3 old ReplicaSets for rollback
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

**Rolling Update:**

```bash
# Update image
kubectl set image deployment/nginx nginx=nginx:1.26-alpine

# Or edit the deployment
kubectl edit deployment nginx

# Check rollout status
kubectl rollout status deployment nginx

# Pause/resume rollout (for canary testing)
kubectl rollout pause deployment nginx
kubectl rollout resume deployment nginx
```

**Rollback:**

```bash
# History
kubectl rollout history deployment nginx
kubectl rollout history deployment nginx --revision=2

# Rollback to previous
kubectl rollout undo deployment nginx

# Rollback to specific revision
kubectl rollout undo deployment nginx --to-revision=1
```

**Scaling:**

```bash
kubectl scale deployment nginx --replicas=10
kubectl autoscale deployment nginx --min=3 --max=10 --cpu-percent=80
```

### StatefulSets

StatefulSets manage stateful applications (databases, message queues, anything that needs stable identity or persistent storage).

Key attributes:
- **Ordinal pods**: `web-0`, `web-1`, `web-2` (stable, predictable naming).
- **Stable network identity**: Each pod gets a DNS name like `web-0.nginx.default.svc.cluster.local`.
- **Stable storage**: Each pod gets its own PV (not shared across replicas).
- **Ordered operations**: Pods are created/deleted/scaled in order (0, 1, 2...).

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
          name: pg
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg-secret
              key: password
        - name: POSTGRES_DB
          value: "appdb"
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
      storageClassName: fast-ssd
```

```bash
# Scale a StatefulSet
kubectl scale statefulset postgres --replicas=5

# Observe ordered creation
kubectl get pods -w -l app=postgres

# Pods have stable DNS
kubectl run dns-test --image=busybox --rm -it -- nslookup postgres-0.postgres.production.svc.cluster.local
```

### DaemonSets

DaemonSets ensure exactly one pod runs on each node (or a subset of nodes). Use cases: log collectors (Fluentd, Filebeat), monitoring agents (Prometheus node exporter, Datadog agent), CNI plugins, kube-proxy.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: logging
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      tolerations:
      - operator: Exists          # Run on all nodes, including control plane
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:2.1
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: dockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

```bash
# Schedule on specific nodes only
kubectl label node worker-2 disktype=ssd

# Then in DaemonSet spec:
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd
```

### Jobs and CronJobs

**Job** — runs one or more pods to completion.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  parallelism: 1              # max concurrent pods
  completions: 1              # total pods to complete
  backoffLimit: 3             # retries before marking failed
  ttlSecondsAfterFinished: 3600   # auto-clean up after 1 hour
  template:
    spec:
      containers:
      - name: migrate
        image: myapp/migrate:1.0
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
      restartPolicy: Never
```

```bash
# Check job status
kubectl get jobs
kubectl describe job db-migration

# Multiple completions (batch processing)
# Use: parallelism: 5, completions: 20
```

**CronJob** — runs Jobs on a schedule.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
spec:
  schedule: "0 2 * * *"       # every day at 2 AM
  concurrencyPolicy: Forbid    # don't start new if previous still running
  startingDeadlineSeconds: 100
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: myapp/backup:1.0
            command: ["pg_dump", "-U", "admin", "appdb"]
          restartPolicy: OnFailure
```

```bash
# Create a one-shot job from cronjob
kubectl create job --from=cronjob/backup manual-backup-1
```

---



---

[← Previous](05-5-pods.md) | [↑ Index](index.md) | [Next →](07-7-services-and-networking.md)
