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





[← Previous](01-1-why-kubernetes.md) | [↑ Index](index.md) | [Next →](03-3-installation.md)
