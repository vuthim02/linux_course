# 🐧 Linux System Administrator — Complete Course
## Part 52 of ∞: Kubernetes Administration — Pods, Deployments, Services, RBAC

---

> **Reverse Engineering Approach:** You will not read theory for weeks before touching a cluster. You will tear apart a running Kubernetes system, inspect every wire, break things, fix them, and internalize how the orchestrator thinks. By the end, you will understand Kubernetes not as a list of YAML keys but as a distributed control system that converges desired state into actual state through relentless control loops.

---

## 1. Why Kubernetes?

You already run containers. You have a Docker Compose file on a single host. That works until:
- The host dies and your database goes with it.
- You need to scale the web tier to 50 replicas across 10 machines.
- You need to roll out a new version without dropping a single request.
- You need to discover services without hardcoded IPs.

Kubernetes solves all of these. It is a **container orchestrator** — a platform that automates deployment, scaling, and operations of application containers across clusters of machines.

### What Kubernetes Gives You

| Capability | What It Means |
|---|---|
| **Self-healing** | Containers that crash are restarted. Nodes that die have their workloads rescheduled elsewhere. |
| **Scaling** | Manual `kubectl scale` or automatic Horizontal Pod Autoscaler based on CPU/memory/custom metrics. |
| **Service discovery & load balancing** | Every pod gets a stable DNS name thru Services. Traffic is load-balanced across healthy pods. |
| **Rolling updates & rollbacks** | Deployments let you update pods incrementally with zero downtime. Failed rollouts roll back automatically (or manually). |
| **Portability** | Same manifests work on-prem, AWS EKS, GCP GKE, Azure AKS, minikube, kind, k3s, OpenShift. |
| **Declarative configuration** | You write YAML files describing desired state. Kubernetes reconciles actual state to match. |

### Cluster Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Control Plane                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐ │
│  │  etcd    │  │ API      │  │ Controller        │ │
│  │ (state)  │◄─►│ Server   │◄─►│ Manager           │ │
│  └──────────┘  └────┬─────┘  └───────────────────┘ │
│                     │                               │
│  ┌──────────────────▼────────────────────────────┐  │
│  │            kube-scheduler                      │  │
│  └───────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
┌───▼──────────┐  ┌─────▼────────┐  ┌───────▼────────┐
│  Worker 1    │  │  Worker 2    │  │  Worker N      │
│ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐   │
│ │ kubelet  │ │  │ │ kubelet  │ │  │ │ kubelet  │   │
│ │ kube-proxy│ │  │ │ kube-proxy│ │  │ │ kube-proxy│  │
│ │ containerd│ │  │ │ containerd│ │  │ │ containerd│  │
│ │ Pods ▲▼  │ │  │ │ Pods ▲▼  │ │  │ │ Pods ▲▼  │   │
│ └──────────┘ │  │ └──────────┘ │  │ └──────────┘   │
└───────────────┘  └──────────────┘  └────────────────┘
```

The **control plane** makes decisions. **Workers** run the actual workloads. All communication flows through the API server — nothing talks to etcd directly except the API server.

---

## 2. Architecture Deep Dive

### Control Plane Components

#### etcd — The Source of Truth

etcd is a **distributed key-value store** based on the Raft consensus algorithm. It stores the entire cluster state: pods, secrets, configmaps, deployments, service accounts, RBAC rules, everything.

```
Key layout (logical):
/registry/deployments/default/nginx
/registry/pods/default/nginx-7f8b9c6d9-abc12
/registry/secrets/default/my-secret
/registry/nodes/worker-1
```

- **Raft consensus**: A majority of etcd members (quorum) must agree on every write. A 3-node etcd cluster tolerates 1 failure. A 5-node cluster tolerates 2.
- **Watch mechanism**: Clients (API server, controllers) can `WATCH` keys. When a key changes, etcd pushes the event to all watchers. This is how the entire cluster reacts instantly.
- **etcdctl**: You can inspect etcd directly:

```bash
# List all keys
ETCDCTL_API=3 etcdctl get / --prefix --keys-only

# Get a specific key
ETCDCTL_API=3 etcdctl get /registry/deployments/default/nginx
```

#### kube-apiserver — The REST Gateway

The API server is the front door. Every CLI command (`kubectl`), every controller, every kubelet — they all talk to the API server over HTTPS.

- **Authentication**: TLS client certificates, bearer tokens, OpenID Connect, webhook token auth.
- **Authorization**: ABAC, RBAC, Webhook, Node authorizer.
- **Admission controllers**: MutatingAdmissionWebhook, ValidatingAdmissionWebhook, PodSecurity, ResourceQuota, LimitRanger, etc. Every request passes through admission before persistence.
- **API versioning**: `v1` (stable), `apps/v1` (Deployments, StatefulSets), `batch/v1` (Jobs, CronJobs), `networking.k8s.io/v1` (Ingress, NetworkPolicy), `autoscaling/v2` (HPA).

```bash
# API discovery
kubectl api-resources
kubectl api-versions

# Explain a resource
kubectl explain pod
kubectl explain pod.spec.containers
```

#### kube-controller-manager — The Control Loop Engine

This is the brain. It bundles dozens of controllers into a single binary. Each controller runs a **reconciliation loop**:

```
for {
    actual := getCurrentState()
    desired := getDesiredState()
    if actual != desired {
        makeChanges(desired - actual)
    }
    sleep(pollInterval)
}
```

Key controllers:

| Controller | What It Does |
|---|---|
| **Deployment Controller** | Watches Deployments, creates/updates ReplicaSets. |
| **ReplicaSet Controller** | Watches ReplicaSets, creates/deletes Pods to match replica count. |
| **StatefulSet Controller** | Manages StatefulSet pods with ordinal identity and stable storage. |
| **DaemonSet Controller** | Ensures every node (or select nodes) run one pod each. |
| **Job Controller** | Watches Jobs, creates pods to completion, handles retries. |
| **CronJob Controller** | Creates Job objects on a schedule (like cron). |
| **Node Controller** | Monitors node health, taints nodes that go offline, evicts pods. |
| **ServiceAccount Controller** | Ensures ServiceAccounts exist, creates tokens. |
| **Garbage Collector** | Deletes dependents when owners are deleted (e.g., pods when a deployment is deleted). |
| **Namespace Controller** | Manages namespace lifecycle. |
| **EndpointSlice Controller** | Creates EndpointSlice objects from Services and Pods. |
| **HPA Controller** | Calculates desired replicas based on metrics. |

#### kube-scheduler — The Pod Placer

The scheduler watches for **unassigned pods** (pods with `spec.nodeName` empty) and picks the best node.

Algorithm (two-phase):

1. **Predicates** (filtering): Eliminate nodes that cannot run the pod.
   - `PodFitsResources`: Node has enough CPU/memory.
   - `PodFitsHostPorts`: Requested host ports are free.
   - `PodMatchNodeSelector`: Node labels match pod `nodeSelector`.
   - `PodToleratesNodeTaints`: Pod tolerations cover node taints.
   - `CheckNodeDiskPressure`, `CheckNodeMemoryPressure`, `CheckNodePIDPressure`, `CheckNodeCondition`.
   - `CheckVolumeBinding`: Node has the PV the pod needs.
   - `NoVolumeZoneConflict`: Volume zones are satisfied.
   - `CheckNodeUnschedulable`: Node is not cordoned.

2. **Priorities** (scoring): Rank remaining nodes (0–100).
   - `LeastRequestedPriority`: Spreads pods across nodes.
   - `MostRequestedPriority`: Packs pods tightly.
   - `BalancedResourceAllocation`: Balance CPU vs memory.
   - `NodeAffinityPriority`, `TaintTolerationPriority`.
   - `SelectorSpreadPriority`: Spread pods from the same Deployment across nodes.
   - `InterPodAffinityPriority`: Co-locate or separate pods based on affinity rules.
   - `ImageLocalityPriority`: Prefer nodes that already have the container image.

3. **Binding**: The scheduler sends a `POST` to the API server binding the pod to the chosen node.

You can influence scheduling with:
- `nodeSelector`: Simple label matching.
- `nodeAffinity`: Required (`requiredDuringSchedulingIgnoredDuringExecution`) or preferred.
- `podAffinity` / `podAntiAffinity`: Co-locate or spread pods.
- `topologySpreadConstraints`: Even distribution across zones/nodes.
- `taints` and `tolerations`: Repel pods unless they explicitly tolerate.

### Worker Node Components

#### kubelet — The Node Agent

Every node runs kubelet. It registers the node with the API server and reports node status (capacity, conditions).

Its core job: **ensure the containers in the PodSpec are running and healthy**.

Workflow:
1. Watches the API server for Pods bound to its node (or reads from a local file/http source).
2. For each pod, calls the Container Runtime Interface (CRI) to create/start/stop containers.
3. Runs liveness, readiness, and startup probes against containers.
4. Reports pod status (phase, conditions, container states) back to the API server.
5. Garbage-collects unused images and dead containers.

```bash
# Check kubelet logs
journalctl -u kubelet -f

# Check kubelet config
kubectl get node worker-1 -o yaml
```

#### kube-proxy — The Network Rule Engine

kube-proxy maintains network rules on each node. It watches Services and EndpointSlices from the API server and translates them into network rules.

**Modes:**
- **iptables** (default): Creates iptables NAT rules. Each Service gets a chain of rules. `stateless`, `DNAT` to random backend pod.
- **IPVS**: Uses Linux IP Virtual Server kernel module. More scalable (O(1) lookup vs O(n) for iptables). Supports more load-balancing algorithms (round-robin, least-connection, etc.).
- **userspace** (deprecated): Old mode, proxies through a userspace daemon.

```
Packet flow (iptables mode):
Client → NodeIP:NodePort → PREROUTING → KUBE-SERVICES →
  KUBE-SVC-XXXXXX (load balance) → KUBE-SEP-YYYYYY (DNAT) → PodIP:containerPort
```

#### Container Runtime

The actual engine that runs containers. Kubernetes uses CRI (Container Runtime Interface):
- **containerd** (most common, used by Docker, kubeadm default)
- **CRI-O** (lightweight, Red Hat ecosystem)
- **Docker** (through cri-dockerd adapter, deprecated in 1.24+)

```bash
# List containers on a node (crictl)
crictl ps
crictl images
crictl logs <container-id>
crictl exec -it <container-id> sh
```

---

## 3. Installation

### kubeadm — Production-Grade Cluster Setup

kubeadm is the standard tool for bootstrapping Kubernetes clusters conforming to best practices.

**Prerequisites:**
- 2+ machines (Ubuntu 22.04+/Debian 12+/RHEL 9+) with 2+ CPU, 2+ GB RAM each
- Unique hostname, MAC address, product_uuid per machine
- Ports open: 6443 (API), 2379-2380 (etcd), 10250 (kubelet), 10259 (scheduler), 10257 (controller), 30000-32767 (NodePort)

**Install kubeadm, kubelet, kubectl (both nodes):**

```bash
# Ubuntu / Debian
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable containerd
sudo systemctl enable --now containerd
```

**Initialize the control plane (control-plane node only):**

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Output includes:
# kubeadm join 192.168.1.10:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx
# Copy the admin config
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Join worker nodes:**

```bash
# On each worker node
sudo kubeadm join 192.168.1.10:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx
```

**Regenerate join token if lost:**

```bash
kubeadm token create --print-join-command
```

### CNI Plugin — Pod Networking

After `kubeadm init`, no pods can communicate until a CNI plugin is installed.

**Calico (recommended for production):**

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27/manifests/calico.yaml

# Verify
kubectl get pods -n calico-system
kubectl get nodes   # should show Ready
```

**Flannel (simple overlay):**

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

**Cilium (advanced, eBPF-based):**

```bash
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system --set podNetwork=10.244.0.0/16
```

### kubeconfig and kubectl Context

```bash
# Default location
~/.kube/config

# Multiple clusters in one file
kubectl config get-contexts
kubectl config use-context my-cluster
kubectl config set-context my-cluster --namespace=production

# Merge kubeconfigs
export KUBECONFIG=~/.kube/config:/path/to/other-config
kubectl config view --flatten > merged-config
```

### minikube — Local Testing

```bash
minikube start --cpus=4 --memory=8g --driver=kvm2
minikube stop
minikube delete
```

### kind — Kubernetes in Docker (for CI)

```bash
kind create cluster --name test
kind get clusters
kind delete cluster --name test

# Multi-node cluster with config
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

---

## 4. kubectl Essentials

### Resource Inspection

```bash
# List resources
kubectl get pods
kubectl get pods -o wide          # with node and IP
kubectl get pods -o yaml          # full spec
kubectl get pods --watch          # stream changes
kubectl get deployments -A       # all namespaces
kubectl get all -n production    # everything in namespace

# Describe (detailed status, events, conditions)
kubectl describe pod nginx-7f8b9c6d9-abc12

# Logs
kubectl logs nginx-7f8b9c6d9-abc12
kubectl logs nginx-7f8b9c6d9-abc12 -c sidecar    # specific container
kubectl logs nginx-7f8b9c6d9-abc12 --previous    # previous crashed instance
kubectl logs -l app=nginx --tail=100 -f          # all pods matching label

# Execute command in container
kubectl exec -it nginx-7f8b9c6d9-abc12 -- sh
kubectl exec deploy/nginx -- env                 # run in a pod from deployment

# Copy files
kubectl cp nginx-7f8b9c6d9-abc12:/etc/nginx/nginx.conf ./nginx.conf

# Port forward (tunnel to a pod)
kubectl port-forward svc/nginx 8080:80           # localhost:8080 → service:80
kubectl port-forward pod/nginx-7f8b9c6d9-abc12 8080:80
```

### Resource Management

```bash
# Apply (create/update from file or stdin)
kubectl apply -f deployment.yaml
kubectl apply -f .                               # whole directory
kubectl apply -f https://example.com/manifest.yaml

# Delete
kubectl delete -f deployment.yaml
kubectl delete pod nginx-7f8b9c6d9-abc12
kubectl delete pod --all                         # delete all pods in namespace

# Diff (dry-run with server-side validation)
kubectl diff -f deployment.yaml
kubectl apply -f deployment.yaml --server-side --field-manager=my-cm
```

### Context and Namespace Switching

```bash
# Current context
kubectl config current-context

# Switch namespace (without installing kubens)
kubectl config set-context --current --namespace=production

# Using kubectx / kubens
kubectx                                    # list contexts
kubectx prod-cluster                       # switch
kubens                                     # list namespaces
kubens production                          # switch namespace
```

### API Resources

```bash
# List all available resources
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --api-group=apps

# Get API versions
kubectl api-versions

# Explain a resource field
kubectl explain deployment.spec.template.spec.containers.resources
```

### Cluster Health

```bash
kubectl get nodes
kubectl describe node worker-1
kubectl top nodes                          # requires metrics-server
kubectl top pods -A
kubectl cluster-info
kubectl get events -A --sort-by='.lastTimestamp'
```

---

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

---

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

## 7. Services and Networking

### Service Types

**ClusterIP** — internal cluster IP, reachable only from within the cluster. Default type.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80              # service port
    targetPort: 8080       # container port
    protocol: TCP
```

**NodePort** — exposes the service on a static port (30000-32767) on every node.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080        # optional, otherwise random
```

```bash
# Access via any node IP
curl http://192.168.1.10:30080
curl http://192.168.1.11:30080
```

**LoadBalancer** — provisions an external load balancer (cloud provider) that forwards traffic to NodePorts.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl get svc nginx-lb    # shows EXTERNAL-IP once provisioned
```

**ExternalName** — returns a CNAME record for the service. Used to reference external services by DNS.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
```

```bash
# Now pods can reach it as: external-db.production.svc.cluster.local
```

### DNS Inside the Cluster

CoreDNS runs as a Deployment in the kube-system namespace. Every service gets a DNS name:

```
<service>.<namespace>.svc.cluster.local
<service>.<namespace>.svc.<cluster-domain>
```

Pods also get DNS (based on `hostname` and `subdomain`):

```
<pod-ip-addr>.<service>.<namespace>.svc.cluster.local
```

```bash
# Test DNS resolution from a pod
kubectl run test --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local
```

### Endpoints and EndpointSlice

When a Service has a pod selector, Kubernetes creates Endpoints (or EndpointSlice, newer API) tracking the pod IPs.

```bash
kubectl get endpoints nginx
kubectl get endpointslices -l kubernetes.io/service-name=nginx
```

### Ingress and Ingress Controller

Ingress is an API object that manages external HTTP/HTTPS access to services. It provides virtual hosting, path-based routing, TLS termination.

An **Ingress Controller** (like nginx-ingress, Traefik, HAProxy, AWS ALB) must be installed in the cluster — the Ingress resource is just a config spec, inert without a controller.

```bash
# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### NetworkPolicy

NetworkPolicy controls traffic flow at the IP address or port level. It is **enforced by the CNI plugin** — plain Flannel does not enforce it, Calico and Cilium do.

By default, all pods can communicate with all pods. A NetworkPolicy changes that.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    ports:
    - port: 5432
      protocol: TCP
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - port: 443
      protocol: TCP
```

```bash
# Test network policy
kubectl run test --image=busybox --rm -it -- wget --timeout=2 http://postgres.production:5432
```

---

## 8. ConfigMaps and Secrets

### ConfigMaps

ConfigMaps store non-sensitive configuration data as key-value pairs.

**Creation:**

```bash
# From literal values
kubectl create configmap app-config --from-literal=log.level=info --from-literal=app.name=microservice

# From files (each file becomes a key)
kubectl create configmap nginx-config --from-file=nginx.conf

# From .env file
kubectl create configmap app-config --from-env-file=.env
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  log.level: info
  app.name: microservice
  app.debug: "false"
  nginx.conf: |
    server {
      listen 80;
      server_name example.com;
      location / {
        proxy_pass http://backend:8080;
      }
    }
immutable: true    # prevent modification, improves performance
```

**Consumption — As environment variables:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
    envFrom:
    - configMapRef:
        name: app-config
```

**Consumption — As a volume:**

```yaml
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: nginx-config
```

### Secrets

Secrets store sensitive data (passwords, tokens, TLS certs, SSH keys). Values are base64-encoded in YAML (not encrypted by default — enable encryption at rest).

**Creation:**

```bash
# From literal values
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=s3cret

# From files
kubectl create secret generic tls-secret --from-file=tls.crt=server.crt --from-file=tls.key=server.key

# From .docker/config.json (for image pull secrets)
kubectl create secret docker-registry regcred --docker-server=registry.example.com --docker-username=tim --docker-password=token --docker-email=tim@example.com

# TLS secret
kubectl create secret tls app-tls --cert=app.crt --key=app.key
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: production
type: Opaque                   # default, arbitrary key-value
data:
  username: YWRtaW4=           # base64(admin)
  password: czNjcmV0           # base64(s3cret)
---
apiVersion: v1
kind: Secret
metadata:
  name: app-tls
  namespace: production
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTiBD...   # base64 of PEM
  tls.key: LS0tLS1CRUdJTiBS...
---
apiVersion: v1
kind: Secret
metadata:
  name: regcred
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6...   # base64 of Docker config JSON
```

**Consumption — As environment variables:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    envFrom:
    - secretRef:
        name: db-secret
```

**Consumption — As a volume:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secrets
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secrets
    secret:
      secretName: db-secret
      defaultMode: 0400          # restrict permissions
```

**Image Pull Secrets — add to ServiceAccount:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: production
imagePullSecrets:
- name: regcred
```

**Immutable ConfigMaps and Secrets** (Kubernetes 1.21+):

```yaml
immutable: true
```

Immutable resources are not watched for changes (less API server load), and kubelet does not re-sync them. You must delete and recreate to change them.

---

## 9. Storage

### Volume Types

**emptyDir** — ephemeral, created when pod starts, deleted when pod is removed.

```yaml
volumes:
- name: scratch
  emptyDir:
    sizeLimit: 1Gi     # optional, default unlimited
```

**hostPath** — mounts a file or directory from the host node's filesystem. Use sparingly (mostly for DaemonSets).

```yaml
volumes:
- name: varlog
  hostPath:
    path: /var/log
    type: DirectoryOrCreate   # Directory, File, Socket, CharDevice, etc.
```

### PersistentVolume and PersistentVolumeClaim

PVs are cluster resources (like nodes). PVCs are requests for storage (like pods).

**Static Provisioning** — admin creates PVs manually.

```yaml
# admin/pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-1
spec:
  capacity:
    storage: 50Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain   # Retain, Delete, Recycle
  storageClassName: nfs
  nfs:
    server: nfs.example.com
    path: /exports/data
```

```yaml
# user/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
  namespace: production
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  storageClassName: nfs
```

```yaml
# pod using the PVC
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-claim
```

**Dynamic Provisioning** — PVC triggers automatic PV creation via a StorageClass.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs       # depends on cloud
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer  # or Immediate
allowVolumeExpansion: true
```

```yaml
# PVC that triggers dynamic provisioning
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: fast-ssd
```

### PersistentVolumeClaim in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: data-claim
```

### CSI Drivers

CSI (Container Storage Interface) allows any storage vendor to write a driver. Common CSI drivers:

- **AWS EBS**: `ebs.csi.aws.com`
- **GCP PD**: `pd.csi.storage.gke.io`
- **Azure Disk**: `disk.csi.azure.com`
- **NFS**: `nfs.csi.k8s.io`
- **Rook/Ceph**: `rook-ceph.rbd.csi.ceph.com`
- **Longhorn**: `driver.longhorn.io`

```bash
# Install AWS EBS CSI driver (via Helm)
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system
```

---

## 10. RBAC — Role-Based Access Control

### ServiceAccounts

A ServiceAccount provides an identity for pods. Each namespace has a `default` ServiceAccount automatically.

```bash
kubectl create serviceaccount my-sa -n production
kubectl get serviceaccounts -A
kubectl describe sa my-sa -n production
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: production
automountServiceAccountToken: true    # auto-mount API token in pods
---
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: my-sa
  containers:
  - name: app
    image: myapp:1.0
```

### Roles and ClusterRoles

**Role** — namespace-scoped permissions.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]              # core API group
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
```

**ClusterRole** — cluster-wide permissions (resources, non-resource URLs, namespaced resources across all namespaces).

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings"]
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/healthz", "/livez", "/readyz"]
  verbs: ["get"]
```

### RoleBindings and ClusterRoleBindings

**RoleBinding** — binds a Role to subjects (Users, Groups, ServiceAccounts) within a namespace.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: production
- kind: User
  name: alice@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**ClusterRoleBinding** — binds a ClusterRole to subjects cluster-wide.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-reader-binding
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: monitoring
- kind: User
  name: admin@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
```

**Combine ClusterRole + RoleBinding** — grants cluster-wide permissions (like read all pods) within a specific namespace:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cluster-reader-binding-ns
  namespace: production
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: production
roleRef:
  kind: ClusterRole
  name: cluster-reader             # references a ClusterRole
  apiGroup: rbac.authorization.k8s.io
```

### Default Cluster Roles

| ClusterRole | Purpose |
|---|---|
| `cluster-admin` | Full access to everything |
| `admin` | Full access within a namespace |
| `edit` | Read/write within a namespace (no RBAC) |
| `view` | Read-only within a namespace |

```bash
# Give a user admin access to a namespace
kubectl create rolebinding alice-admin -n production --clusterrole=admin --user=alice@example.com

# Give SA read-only access across all namespaces
kubectl create clusterrolebinding sa-reader --clusterrole=view --serviceaccount=production:my-sa
```

### RBAC Debugging

```bash
# Check what a user/SA can do
# Requires kubectl-sudo plugin or:
kubectl auth can-i create deployments --as system:serviceaccount:production:my-sa
kubectl auth can-i get pods --as alice@example.com

# For the current user
kubectl auth can-i delete pods

# Check binding
kubectl get rolebindings -n production -o wide
kubectl get clusterrolebindings -o wide

# What permissions does a role grant?
kubectl describe role pod-reader -n production
kubectl describe clusterrole cluster-admin
```

### RBAC Best Practices

- **Least privilege**: Grant only what is needed.
- **Use ServiceAccounts for pods, not user tokens.**
- **Use Groups** for managing teams (tied to your OIDC provider).
- **Regularly audit** with tools like `kubectl audit` or `kubectx` + `kubectl auth can-i`.
- **Enable RBAC** (it is on by default in 1.6+).
- **Never bind `cluster-admin` to a user unless absolutely necessary.**

---

## 11. Horizontal Pod Autoscaler (HPA)

The HPA automatically scales the number of pods in a deployment or statefulset based on observed metrics.

### Prerequisites: metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl top nodes
kubectl top pods
```

### HPA Resource

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: 1000
  - type: Object
    object:
      metric:
        name: request_count
      describedObject:
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        name: myapp-ingress
      target:
        type: Value
        value: 10000
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300    # wait 5 min before scaling down
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### How HPA Calculates Desired Replicas

```
desiredReplicas = ceil(currentReplicas * (currentMetricValue / desiredMetricValue))
```

Example:
- Current replicas: 3
- Current CPU utilization: 90%
- Target CPU: 70%
- desiredReplicas = ceil(3 * (90 / 70)) = ceil(3 * 1.29) = ceil(3.87) = 4

### Custom and External Metrics

- **Custom metrics** come from the pod itself (e.g., `requests_per_second` exposed by the app).
- **External metrics** come from outside the cluster (e.g., queue length from AWS SQS).
- Requires a metrics adapter (Prometheus Adapter, KEDA, etc.).

```bash
# Watch HPA status
kubectl get hpa -w
kubectl describe hpa nginx-hpa

# Generate load to test scaling
kubectl run load-generator --image=busybox --rm -it -- sh -c "while true; do wget -q -O- http://nginx.production; done"
```

### Scaling Behavior (autoscaling/v2)

- **stabilizationWindowSeconds**: Cooldown period before scaling in a direction.
- **policies**: Limits on how fast to scale (absolute pods or percentage per period).
- **selectPolicy**: `Max` (least restrictive), `Min` (most restrictive), `Disabled` (block direction).

---

## 12. Logging and Debugging

### kubectl logs

```bash
# Basic
kubectl logs nginx-7f8b9c6d9-abc12

# Previous instance (if container crashed and restarted)
kubectl logs nginx-7f8b9c6d9-abc12 --previous

# Tail and follow
kubectl logs nginx-7f8b9c6d9-abc12 --tail=50 -f

# Multi-container pod
kubectl logs nginx-7f8b9c6d9-abc12 -c sidecar

# All pods matching label
kubectl logs -l app=nginx --tail=20 -f

# Timestamps
kubectl logs nginx-7f8b9c6d9-abc12 --timestamps

# Max lines (avoid truncation)
kubectl logs nginx-7f8b9c6d9-abc12 --tail=500
```

### kubectl debug (Kubernetes 1.20+)

Creates a temporary container or pod with debugging tools.

```bash
# Debug a running pod (add ephemeral container)
kubectl debug nginx-7f8b9c6d9-abc12 -it --image=busybox -- sh

# Debug a node (creates a pod running on the node)
kubectl debug node/worker-1 -it --image=alpine -- sh

# Copy of a pod for debugging (matches pod spec)
kubectl debug nginx-7f8b9c6d9-abc12 -it --copy-to=debug-pod --image=nicolaka/netshoot
```

### Ephemeral Containers

Ephemeral containers are temporary debugging containers attached to a running pod. They have no resource guarantees, no ports, and are not restarted.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  ephemeralContainers:
  - name: debug
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
    targetContainerName: app
```

```bash
kubectl alpha debug -it myapp --image=nicolaka/netshoot
```

### Events

```bash
# Cluster events
kubectl get events -A --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -A -w

# Filter by resource
kubectl get events --field-selector involvedObject.name=nginx-deploy-7f8b9c6d9

# Describe includes events
kubectl describe pod nginx-7f8b9c6d9-abc12
```

### crictl — Debugging Container Runtime

On the node directly:

```bash
# List all containers
crictl ps -a

# Container logs (not truncated like docker)
crictl logs <container-id>

# Inspect
crictl inspect <container-id>

# Execute
crictl exec -it <container-id> sh

# List images
crictl images

# Pull image
crictl pull nginx:1.25-alpine
```

### Node Conditions

```bash
kubectl describe node worker-1
kubectl get node worker-1 -o yaml | grep -A10 conditions:
```

Common conditions:
- `Ready` (True/False/Unknown)
- `DiskPressure` (True/False)
- `MemoryPressure` (True/False)
- `PIDPressure` (True/False)
- `NetworkUnavailable` (True/False)

### Debugging a CrashLoopBackOff

1. Check logs of the previous (crashed) instance:
   ```bash
   kubectl logs pod-name --previous
   ```
2. Describe the pod for events and container status:
   ```bash
   kubectl describe pod pod-name
   ```
3. Check the exit code in container status (137 = SIGKILL from OOM, 1 = app error).
4. If OOM (exit 137), increase memory limits.
5. Check image name/pull policy — wrong image or registry auth.
6. Check liveness/readiness probe timing — too aggressive probes restart pods.

---

## 13. Upgrades

### kubeadm Upgrade Process

Upgrade one minor version at a time (1.29 → 1.30 → 1.31). Never skip.

**Step 1: Upgrade kubeadm on control plane**

```bash
# Check available versions
apt-cache madison kubeadm

# Drain the control plane node (optional, for multi-CP clusters)
kubectl drain control-plane-1 --ignore-daemonsets

# Upgrade kubeadm
apt-get update && apt-get install -y kubeadm=1.30.x-*
kubeadm upgrade plan
kubeadm upgrade apply v1.30.x

# Uncordon
kubectl uncordon control-plane-1
```

**Step 2: Upgrade kubelet and kubectl on control plane**

```bash
apt-get install -y kubelet=1.30.x-* kubectl=1.30.x-*
systemctl daemon-reload
systemctl restart kubelet
```

**Step 3: Upgrade worker nodes**

```bash
# Drain
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# On worker-1:
apt-get install -y kubeadm=1.30.x-* kubelet=1.30.x-* kubectl=1.30.x-*
kubeadm upgrade node
systemctl daemon-reload
systemctl restart kubelet

# Uncordon on control plane
kubectl uncordon worker-1
```

### Drain and Cordon

```bash
# Cordon (mark unschedulable, but running pods stay)
kubectl cordon worker-1

# Drain (evict all pods gracefully)
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data --force

# Uncordon (resume scheduling)
kubectl uncordon worker-1
```

`--ignore-daemonsets`: DaemonSet pods are ignored (they run on every node).
`--delete-emptydir-data`: Allow eviction of pods with emptyDir volumes.
`--force`: Force eviction even if not managed by a controller.

### Pod Disruption Budgets

PDB limits the number of voluntary disruptions a deployment can tolerate during maintenance.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: production
spec:
  minAvailable: 2           # or maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx
```

```bash
# Check PDB status
kubectl get pdb
kubectl describe pdb nginx-pdb
```

`drain` respects PDB: if draining would violate the PDB, it waits (or eventually times out with `--force`).

### Cluster Version Skew Policy

| Component | Allowed Skew |
|---|---|
| kube-apiserver | Latest version |
| kube-controller-manager, kube-scheduler | ≤ 1 minor version behind API server |
| kubelet | ≤ 2 minor versions behind API server |
| kube-proxy | ≤ 2 minor versions behind API server |
| kubectl | ±1 minor version from API server |

---

## 14. Deep Understanding

### How the Scheduler Works

Walk through scheduling a new pod:

1. **Observation**: The scheduler (via informer) watches `/api/v1/pods` and sees a pod with `spec.nodeName == ""`.
2. **Filtering (Predicates)**: For each node, run all predicate functions. If any fails, node is excluded.
   - `PodFitsResources`: Requested CPU/memory ≤ allocatable on node.
   - `PodFitsHostPorts`: No port conflict.
   - `PodMatchNodeSelector`: Node labels match pod `nodeSelector`.
   - `PodToleratesNodeTaints`: For each taint, pod must have matching toleration.
   - `CheckNodeCondition`: Node is healthy.
   - `CheckVolumeBinding`: Node can satisfy the pod's volume requirements.
3. **Scoring (Priorities)**: For each remaining node, run all priority functions. Each returns a score (0–10) multiplied by weight (default 1). Sum all scores.
   - `LeastRequestedPriority`: Prefers nodes with more free resources. score = (total - requested) / total * 10.
   - `BalancedResourceAllocation`: Prefers balanced CPU/memory usage.
   - `SelectorSpreadPriority`: Spreads pods of same Service/ReplicaSet across nodes.
   - `ImageLocalityPriority`: Node already pulled the image → higher score.
4. **Binding**: Pick the node with the highest score. `POST /api/v1/namespaces/{ns}/pods/{pod}/binding` to the API server.

### How kubelet Watches and Reconciles

1. kubelet's **pod informer** watches the API server for pods assigned to its node (`spec.nodeName == nodeName`).
2. On receiving a pod add/update, kubelet pushes it to its **sync queue**.
3. kubelet's **syncLoop** pops pods from the queue and calls `syncPod()`:
   - If the pod is new: Pull images, create containers, set up networking, mount volumes, run init containers, run app containers.
   - If the pod changed: Compare current containers vs desired spec → create/update/delete containers as needed.
   - If the pod is deleted: Gracefully stop containers, unmount volumes, clean up.
4. Every few seconds, kubelet runs **status updates** — probes (liveness, readiness, startup), resource usage, pod conditions → reports via API server.
5. If a container exits, kubelet restarts it based on `restartPolicy` (Always: restart always, OnFailure: if exit ≠ 0, Never: don't restart).

### How etcd Stores Cluster Data

- **Keys are organized as a hierarchical tree**: `/registry/<resource>/<namespace>/<name>`.
- **Values are serialized protobuf** (not JSON) for efficiency.
- **Watches**: Clients can create watchers on key prefixes. When a key changes, etcd pushes the new value to all watchers with the event type (CREATE, UPDATE, DELETE).
- **Raft consensus**: etcd uses the Raft protocol to maintain a consistent replicated log across cluster members.
  - **Leader election**: One node is the leader. Followers forward writes to the leader.
  - **Log replication**: Leader appends the write to its log, replicates to a majority of followers, then commits.
  - **Quorum**: For a 3-node cluster, 2 nodes must agree. For 5-node, 3 must agree.
- **MVCC**: Multi-version concurrency control — each key has a revision number. Watchers can resume from a specific revision.

### How kube-proxy Programs Network Rules

**iptables mode:**

1. kube-proxy watches Services and Endpoints from the API server.
2. For each Service, it creates:
   - `KUBE-SERVICES` chain (entry point for all service traffic).
   - `KUBE-SVC-XXXXX` chain (one per service, holds the load-balancing rules).
   - `KUBE-SEP-XXXXX` chain (one per endpoint pod, holds DNAT rules to pod IP).
3. `KUBE-SERVICES` matches destination IP:port and jumps to the appropriate `KUBE-SVC-XXXXX`.
4. `KUBE-SVC-XXXXX` uses `statistic mode random` to probabilistically select a backend `KUBE-SEP-XXXXX`.
5. `KUBE-SEP-XXXXX` has a single `DNAT` rule: `--to-destination <pod-ip>:<port>`.

**IPVS mode:**

- kube-proxy creates a virtual IPVS server on the node for each cluster IP.
- Backend servers (pod IPs) are added to the virtual server.
- IPVS kernel module does the actual load balancing with O(1) efficiency.
- Supports scheduling algorithms: `rr`, `wrr`, `lc`, `wlc`, `sh`, `dh`.

### How Controller Manager Runs Control Loops

Take the Deployment controller as the canonical example:

1. **List/Watch** Deployments from API server.
2. For each Deployment, ensure the corresponding ReplicaSet exists with the correct pod template hash.
   - The Deployment controller creates a ReplicaSet with `spec.replicas == deployment.replicas` and `spec.template.metadata.labels[pod-template-hash]`.
3. **Update** the ReplicaSet's owner reference to point to the Deployment.
4. On rolling update (changed `spec.template`):
   1. Create a new ReplicaSet with the new template.
   2. Scale up the new ReplicaSet by 1 (or `maxSurge`).
   3. Scale down the old ReplicaSet by 1 (or `maxUnavailable`).
   4. Wait for pods to be ready (based on readiness probes).
   5. Repeat until old ReplicaSet is at 0 and new is at desired replicas.
5. The ReplicaSet controller, separately, watches ReplicaSets and creates/deletes pods to match `spec.replicas`.

**Chain**: Deployment → creates/updates → ReplicaSet → creates/deletes → Pods.

### How HPA Calculates Desired Replicas

```python
desired_replicas = ceil(current_replicas * (current_value / desired_value))
```

For **Utilization** type (percentage):
- `current_value` = average utilization across all pods.
- `desired_value` = `targetAverageUtilization`.

For **AverageValue** type:
- `current_value` = average metric value per pod.
- `desired_value` = `targetAverageValue`.

For **Value** type:
- `current_value` = metric value from the object.
- `desired_value` = `targetValue`.

The HPA controller runs every 15 seconds. It rescales only if:
- `abs(desired_replicas - current_replicas) > 1` (to avoid flapping when close to target).
- Or `desired_replicas = 0` (scale to zero, requires special configuration).

---

## 15. Command Reference

### Context and Configuration

| Command | Purpose |
|---|---|
| `kubectl config get-contexts` | List contexts |
| `kubectl config use-context <name>` | Switch context |
| `kubectl config set-context --current --namespace=<ns>` | Set default namespace |
| `kubectl config view` | Show merged kubeconfig |
| `kubectl config current-context` | Show active context |

### Resource Management

| Command | Purpose |
|---|---|
| `kubectl apply -f <file>` | Create/update resources |
| `kubectl delete -f <file>` | Delete resources |
| `kubectl delete pod --all` | Delete all pods in ns |
| `kubectl diff -f <file>` | Show diff before applying |
| `kubectl edit deployment/nginx` | Edit live resource |

### Inspection

| Command | Purpose |
|---|---|
| `kubectl get pods -o wide` | List pods with node/IP |
| `kubectl get pods --watch` | Stream pod changes |
| `kubectl describe pod <name>` | Detailed pod status |
| `kubectl get events` | Show events |
| `kubectl api-resources` | List all resource types |
| `kubectl explain pod.spec` | Field documentation |

### Debugging

| Command | Purpose |
|---|---|
| `kubectl logs <pod>` | Container logs |
| `kubectl logs <pod> --previous` | Previous crash logs |
| `kubectl logs -l app=nginx -f` | Follow logs from multiple pods |
| `kubectl exec -it <pod> -- sh` | Shell into container |
| `kubectl cp <pod>:<src> <dest>` | Copy from pod |
| `kubectl port-forward svc/nginx 8080:80` | Tunnel to service |
| `kubectl debug <pod> -it --image=busybox` | Debug pod |
| `kubectl debug node/<name> -it --image=alpine` | Debug node |
| `kubectl top pod` | Show pod metrics |
| `kubectl top node` | Show node metrics |

### Workloads

| Command | Purpose |
|---|---|
| `kubectl scale deployment/nginx --replicas=5` | Scale deployment |
| `kubectl set image deployment/nginx nginx=nginx:1.26` | Update image |
| `kubectl rollout status deployment/nginx` | Check rollout |
| `kubectl rollout history deployment/nginx` | Show revisions |
| `kubectl rollout undo deployment/nginx` | Rollback to previous |
| `kubectl rollout undo deployment/nginx --to-revision=2` | Rollback to revision 2 |
| `kubectl rollout pause deployment/nginx` | Pause rollout |
| `kubectl rollout resume deployment/nginx` | Resume rollout |

### Cluster Administration

| Command | Purpose |
|---|---|
| `kubectl cordon <node>` | Mark unschedulable |
| `kubectl drain <node> --ignore-daemonsets` | Evict pods gracefully |
| `kubectl uncordon <node>` | Mark schedulable |
| `kubectl taint node <node> key=value:Effect` | Apply taint |
| `kubectl label node <node> key=value` | Add/update label |
| `kubectl cluster-info` | Show cluster info |
| `kubectl auth can-i <verb> <resource>` | Check permissions |

### Storage

| Command | Purpose |
|---|---|
| `kubectl get pv` | List persistent volumes |
| `kubectl get pvc` | List persistent volume claims |
| `kubectl get sc` | List storage classes |
| `kubectl describe pv <name>` | PV details |

### RBAC

| Command | Purpose |
|---|---|
| `kubectl create serviceaccount <name>` | Create SA |
| `kubectl create role <name> --verb=get,list --resource=pods` | Create Role |
| `kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa>` | Bind Role to SA |
| `kubectl create clusterrolebinding <name> --clusterrole=view --user=<user>` | Bind ClusterRole to user |
| `kubectl auth can-i get pods --as=system:serviceaccount:ns:sa` | Test permissions |

---

## 16. 15 Hands-On Practices

### Practice 1: Install kubeadm, kubelet, kubectl on 2 VMs

Set up two Ubuntu 22.04 VMs (control-plane and worker-1):

```bash
# Run on BOTH nodes
cat <<EOF | sudo bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl containerd
apt-mark hold kubelet kubeadm kubectl
EOF
```

Verify:
```bash
kubeadm version
kubectl version --client
kubelet --version
```

### Practice 2: Initialize Cluster and Join Worker

```bash
# On control-plane:
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes   # control-plane should be NotReady (no CNI yet)

# Copy the join command from init output
# On worker-1:
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# If token expired:
kubeadm token create --print-join-command
```

### Practice 3: Install Calico CNI

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27/manifests/calico.yaml

watch kubectl get pods -n calico-system
watch kubectl get nodes   # wait for Ready
```

### Practice 4: kubectl Basics

```bash
kubectl get nodes -o wide
kubectl describe node worker-1

# Run a test pod
kubectl run test --image=nginx --restart=Never --port=80

kubectl get pods -w
kubectl describe pod test
kubectl logs test
kubectl exec -it test -- sh -c "echo hello > /usr/share/nginx/html/index.html"
kubectl port-forward pod/test 8080:80

# Clean up
kubectl delete pod test
```

### Practice 5: Deployment with 3 Replicas and Service

```yaml
# nginx-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
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
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f nginx-deploy.yaml
kubectl get pods -l app=nginx
kubectl get svc nginx

# Access the service
kubectl run test --image=busybox --rm -it -- wget -qO- http://nginx
```

### Practice 6: Rolling Update and Rollback

```bash
# Update image
kubectl set image deployment/nginx nginx=nginx:1.26-alpine

# Watch rollout
kubectl rollout status deployment/nginx

# Check history
kubectl rollout history deployment/nginx

# Rollback
kubectl rollout undo deployment/nginx

# Verify rollback
kubectl rollout status deployment/nginx
kubectl describe deployment nginx | grep Image
```

### Practice 7: StatefulSet with PVC Template

```yaml
# postgres-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None       # headless service for stable DNS
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 2
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
        env:
        - name: POSTGRES_PASSWORD
          value: testpass
        ports:
        - containerPort: 5432
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
          storage: 1Gi
```

```bash
kubectl apply -f postgres-statefulset.yaml
kubectl get pods -l app=postgres -w
kubectl get pvc
kubectl exec -it postgres-0 -- psql -U postgres -c "CREATE DATABASE testdb;"
kubectl delete pod postgres-0    # pvc persists, data survives
# Verify data survives on new postgres-0
kubectl exec -it postgres-0 -- psql -U postgres -c "\l"
```

### Practice 8: DaemonSet for Logging

```yaml
# fluentbit-ds.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:2.1
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
```

```bash
kubectl apply -f fluentbit-ds.yaml
kubectl get daemonsets -n kube-system
kubectl get pods -n kube-system -l app=fluent-bit -o wide
```

### Practice 9: ConfigMaps and Secrets

```yaml
# config-and-secrets.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: production
  APP_DEBUG: "false"
  DB_HOST: postgres.production.svc.cluster.local
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  DB_USER: YWRtaW4=              # base64(admin)
  DB_PASSWORD: cDNjcjN0          # base64(p3cr3t)
---
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
spec:
  containers:
  - name: app
    image: alpine:3.19
    command: ["sleep", "3600"]
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-secret
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

```bash
kubectl apply -f config-and-secrets.yaml
kubectl exec config-demo -- env | sort
kubectl exec config-demo -- cat /etc/config/APP_ENV
kubectl exec config-demo -- ls -la /etc/config
```

### Practice 10: Ingress Resource with NGINX Ingress Controller

```bash
# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Wait for it
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
```

```yaml
# ingress-demo.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: demo.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

```bash
kubectl apply -f ingress-demo.yaml
kubectl get ingress

# Test (add to /etc/hosts or use curl --resolve)
kubectl get svc -n ingress-nginx ingress-nginx-controller
curl -H "Host: demo.local" http://<ingress-controller-external-ip>
```

### Practice 11: NetworkPolicy

```yaml
# network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx
    ports:
    - port: 5432
```

```bash
kubectl apply -f network-policies.yaml

# Test: run a pod without app=nginx label, try to reach postgres
kubectl run test1 --image=busybox --rm -it -- wget -qO- --timeout=2 http://postgres:5432 || echo "blocked"

# Test: run a pod with app=nginx label
kubectl run test2 --image=busybox --labels="app=nginx" --rm -it -- wget -qO- --timeout=2 http://postgres:5432 || echo "blocked"
```

### Practice 12: RBAC — ServiceAccount with Read-Only Access

```yaml
# rbac-demo.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: readonly-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: readonly-binding
subjects:
- kind: ServiceAccount
  name: readonly-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f rbac-demo.yaml

# Get the token
kubectl get secret $(kubectl get sa readonly-sa -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d

# Use the token
kubectl --token=<token> get pods          # works
kubectl --token=<token> delete pod test   # fails (forbidden)
```

### Practice 13: HPA with metrics-server

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait
kubectl wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=metrics-server --timeout=120s

kubectl top nodes
```

```yaml
# hpa-demo.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

```bash
kubectl apply -f hpa-demo.yaml
kubectl get hpa -w

# Generate load
kubectl run load-generator --image=busybox --rm -it -- sh -c "while true; do wget -q -O- http://nginx; done"

# Watch scale-up in another terminal
watch kubectl get pods -l app=nginx
```

### Practice 14: Drain and Cordon a Node

```bash
# Cordon
kubectl cordon worker-1
kubectl get nodes    # STATUS shows Ready,SchedulingDisabled

# Drain
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# Verify pods moved
kubectl get pods -o wide

# Perform maintenance (simulate)
sleep 10

# Uncordon
kubectl uncordon worker-1
kubectl get nodes
```

### Practice 15: Real-World Full Stack Application

Deploy a three-tier application: React frontend, Node.js backend, PostgreSQL database.

```yaml
# 01-db.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  POSTGRES_USER: app
  POSTGRES_PASSWORD: changeme
  POSTGRES_DB: myapp
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
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
        envFrom:
        - secretRef:
            name: db-secret
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
          storage: 5Gi
```

```yaml
# 02-backend.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  DB_HOST: postgres.default.svc.cluster.local
  DB_PORT: "5432"
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: api
        image: node:20-alpine
        command:
        - sh
        - -c
        - |
          npm init -y && npm install express pg && cat <<'SCRIPT' > server.js
          const express = require('express');
          const { Pool } = require('pg');
          const app = express();
          const pool = new Pool({
            host: process.env.DB_HOST,
            port: process.env.DB_PORT,
            user: process.env.POSTGRES_USER,
            password: process.env.POSTGRES_PASSWORD,
            database: process.env.POSTGRES_DB,
          });
          app.get('/health', (req, res) => res.json({ status: 'ok' }));
          app.get('/users', async (req, res) => {
            const { rows } = await pool.query('SELECT NOW() as time');
            res.json(rows);
          });
          app.listen(3000);
          SCRIPT
          node server.js
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: backend-config
        - secretRef:
            name: db-secret
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

```yaml
# 03-frontend.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  API_URL: http://backend.default.svc.cluster.local:3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: frontend-config
```

```yaml
# 04-ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

```yaml
# 05-rbac.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-role
rules:
- apiGroups: [""]
  resources: ["endpoints", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-rb
subjects:
- kind: ServiceAccount
  name: backend-sa
roleRef:
  kind: Role
  name: backend-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Deploy the full stack
kubectl apply -f 01-db.yaml
kubectl apply -f 02-backend.yaml
kubectl apply -f 03-frontend.yaml
kubectl apply -f 04-ingress.yaml
kubectl apply -f 05-rbac.yaml

# Watch everything come up
kubectl get all

# Test the backend
kubectl run test --image=curlimages/curl --rm -it -- curl http://backend:3000/health

# Test via ingress
curl -H "Host: myapp.example.com" http://<ingress-ip>/api/health

# Clean up entire stack
kubectl delete -f 01-db.yaml -f 02-backend.yaml -f 03-frontend.yaml -f 04-ingress.yaml -f 05-rbac.yaml
```

---

## What's Coming in Part 53

**Part 53: CI/CD Pipelines — GitHub Actions, GitLab CI, Jenkins**

We will automate all of the above. Save the YAML to a repo, push, and watch a pipeline build, test, containerize, and deploy to Kubernetes — every commit, automatically.

Topics: GitHub Actions workflows, GitLab CI runners, Jenkins pipelines, Helm charts for templating, ArgoCD/GitOps for declarative deployments, image scanning, secret management in CI.

---

## Self-Test

**Instructions:** Answer all 15 questions. Score 12/15 or higher before moving to Part 53.

**Question 1:** What is the role of etcd in a Kubernetes cluster?

**Question 2:** A pod is stuck in `CrashLoopBackOff`. What three debugging steps do you take?

**Question 3:** What is the difference between a `Role` and a `ClusterRole`?

**Question 4:** A Deployment has `replicas: 5`. You drain a node. What happens to the 2 pods running on that node?

**Question 5:** You want pods in `namespace-a` to NOT talk to pods in `namespace-b`. What Kubernetes resource do you use, and what must the CNI support?

**Question 6:** What is the difference between a `ConfigMap` and a `Secret`?

**Question 7:** An HPA is configured with `targetAverageUtilization: 80` for CPU. Current CPU usage is 60% across 4 pods. What is the desired replica count?

**Question 8:** A Service of type `ClusterIP` has a selector matching 3 pods. One pod is unhealthy (readiness probe failing). What happens when another pod tries to reach the Service DNS name?

**Question 9:** How does the `kube-scheduler` decide which node to place a pod on? Name the two phases.

**Question 10:** You need every node in the cluster to run a log-collection agent. What workload type do you use?

**Question 11:** A StatefulSet pod named `web-2` is deleted. What is the name of the replacement pod, and does it get the same PVC?

**Question 12:** What does `kubectl logs pod-name --previous` do?

**Question 13:** A pod mounts a `Secret` as a volume. A new key is added to the Secret. How does the pod see the update?

**Question 14:** What is the purpose of a `PodDisruptionBudget`?

**Question 15:** A user runs `kubectl auth can-i delete pods` and gets `no`. What does this mean?

---

### Answer Key

**Q1:** etcd is the distributed key-value store that holds all cluster state — pods, deployments, secrets, configs, RBAC rules, etc. The API server is the only component that talks to etcd directly.

**Q2:** 1) `kubectl logs pod-name --previous` to see the crash logs from the terminated container. 2) `kubectl describe pod pod-name` to check container exit code, events, and conditions. 3) If exit code 137 (SIGKILL), increase memory limits (OOM). If exit code 1, investigate app logs and configuration.

**Q3:** A `Role` is namespace-scoped and grants permissions only within that namespace. A `ClusterRole` is cluster-scoped and can grant permissions to cluster-level resources (nodes, PVs, namespaces) or namespaced resources across all namespaces.

**Q4:** The kube-controller-manager sees that the 2 pods are no longer running (their node is unschedulable). The ReplicaSet controller creates 2 replacement pods on healthy nodes, bringing the count back to 5.

**Q5:** `NetworkPolicy` with `podSelector` and `namespaceSelector`. The CNI plugin must support NetworkPolicy enforcement (Calico, Cilium — not Flannel without policy support).

**Q6:** Both store configuration data. `Secret` values are base64-encoded and can be restricted via RBAC. `ConfigMap` values are plaintext. Secrets support additional types (TLS, docker-registry). Secrets can be encrypted at rest.

**Q7:** `desiredReplicas = ceil(4 * (60 / 80)) = ceil(4 * 0.75) = ceil(3) = 3`. However, the HPA has a **hysteresis** threshold: it only scales if `|desired - current| > 1` OR if scaling to zero. Since 3 is within 1 of 4, the HPA does **not** scale down. Answer: 4 (no change).

**Q8:** The Service's EndpointSlice controller removes the unhealthy pod's IP from the endpoint list. Traffic goes only to the 2 healthy pods. The readiness probe determines whether a pod receives traffic.

**Q9:** Two phases: **Predicates** (filtering) eliminates nodes that cannot run the pod (resource fit, port conflicts, taints, node selector). **Priorities** (scoring) ranks remaining nodes by factors like resource availability, pod spreading, image locality, and affinity rules. The highest-scoring node is chosen.

**Q10:** `DaemonSet`. It runs exactly one pod on each node (or a subset, configurable with `nodeSelector` and tolerations).

**Q11:** The replacement pod is named `web-2` (same ordinal). It gets the **same** PVC that `web-2` had — the PVC persists independently of the pod. The data survives.

**Q12:** It shows the logs from the **previous** (terminated/crashed) instance of the container. Essential for debugging CrashLoopBackOff.

**Q13:** By default, the kubelet syncs Secret volumes periodically (based on the kubelet sync period, typically 10–60 seconds). The new key appears as a new file in the mounted directory. For env vars, the values are set at container start and **do not** update dynamically.

**Q14:** `PodDisruptionBudget` limits the number of voluntary disruptions (like node drains) that can affect a Deployment's pods simultaneously. It ensures a minimum number (`minAvailable`) or maximum number (`maxUnavailable`) of pods remain running during voluntary disruptions.

**Q15:** The current user/ServiceAccount does not have the `delete` verb on the `pods` resource. This is RBAC denying the action. The user needs a RoleBinding/ClusterRoleBinding granting `delete` on `pods`.

### Scoring

- **12–15 correct**: Ready for Part 53. You understand Kubernetes fundamentals.
- **9–11 correct**: Review the sections where you struggled. Focus on RBAC, HPA calculation, and scheduler logic.
- **0–8 correct**: Work through the 15 hands-on practices again. Break each practice into smaller steps.

**Score:** _____ / 15 correct = ready for Part 53.

---

## Reverse Engineering Challenge

You are given a Kubernetes cluster that is broken. Diagnose and fix it using only the command line. No documentation.

**Symptoms:**
- `kubectl get nodes` shows 2 of 3 nodes as `NotReady`.
- `kubectl get pods -A` shows several pods in `Pending` state.
- `kubectl get pods -n kube-system` shows `coredns` pods in `CrashLoopBackOff`.
- `kubectl describe node worker-2` shows `KubeletNotReady` with reason `PLEG is not healthy`.

**Your task (walk through this mentally or on a real cluster):**

1. Check kubelet logs on `worker-2`: `journalctl -u kubelet -n 100 --no-pager`.
2. Check container runtime: `crictl ps` and `crictl images`.
3. Check DNS resolution from the node: `nslookup kubernetes.default.svc.cluster.local <cluster-dns-ip>` (or check `/etc/resolv.conf`).
4. Verify the CNI plugin is running: `kubectl get pods -n kube-system -l k8s-app=calico-node` or `k8s-app=flannel`.
5. If `PLEG is not healthy`, restart containerd and kubelet: `systemctl restart containerd && systemctl restart kubelet`.
6. If CoreDNS CrashLoopBackOff: check logs (`kubectl logs -n kube-system coredns-xxx --previous`). Check CoreDNS ConfigMap. Check network policy or CNI configuration.

**What you should have learned:** Troubleshooting Kubernetes requires understanding the chain: API server → kubelet → container runtime → CNI. Break the chain at any point, and the cluster fails silently. The tools are `journalctl`, `crictl`, `kubectl`, and `systemctl`. No magic. Just systematic elimination.

---

```
*Linux SysAdmin Course | Part 52 of ∞ | Reverse Engineering Approach*
*Previous → Part 51: Infrastructure as Code — Terraform*
*Next → Part 53: CI/CD Pipelines — GitHub Actions, GitLab CI, Jenkins*
```

[← Previous](part51.md) | [Next →](part53.md)
