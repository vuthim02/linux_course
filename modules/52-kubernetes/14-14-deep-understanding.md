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



---

[← Previous](13-13-upgrades.md) | [↑ Index](index.md) | [Next →](15-15-command-reference.md)
