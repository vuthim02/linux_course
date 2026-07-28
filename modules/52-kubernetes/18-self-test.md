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





[← Previous](17-whats-coming-in-part-53.md) | [↑ Index](index.md) | [Next →](19-reverse-engineering-challenge.md)
