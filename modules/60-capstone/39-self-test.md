## 📝 Self-Test

1. **Architecture**: Draw a system diagram for the capstone platform. Label all components and data flows. What happens when a user hits `https://api.capstone.example.com/health`?

2. **Terraform**: What Terraform resources are needed to create the VPC with public and private subnets across 2 AZs? How does the EKS cluster know which subnets to use?

3. **Kubernetes Networking**: Explain how Cilium replaces kube-proxy. What is Hubble and how does it help with network observability?

4. **Docker Multi-Stage**: Why does the Dockerfile use two stages? What is the benefit of the `slim` base image and the non-root user?

5. **Helm**: In the Helm chart, what does the `checksum/config` annotation on the pod template do? Why is it important?

6. **CI/CD**: Explain the OIDC authentication flow between GitHub Actions and AWS. Why is this better than using long-lived access keys?

7. **External Secrets**: How does the External Secrets Operator sync secrets from AWS Secrets Manager to Kubernetes? What prevents the Kubernetes Secret from being out of date?

8. **ServiceMonitor**: How does Prometheus discover which pods to scrape? What labels on the ServiceMonitor and Service must match?

9. **HPA Behavior**: The HPA has a scale-down stabilization window of 300 seconds. What problem does this solve? What happens during a rapid traffic spike?

10. **Network Policies**: After applying a default-deny ingress policy, can pods in the same namespace still communicate? What must be configured to allow specific traffic?

11. **PodDisruptionBudget**: If `minAvailable: 2` is set and there are 5 replicas, can a node drain proceed if it would terminate 2 pods simultaneously?

12. **Chaos Engineering**: During the pod-kill chaos experiment, what mechanisms ensure the application remains available? How does the self-healing work?

13. **SLOs**: If the monthly SLO target is 99.9% availability and the service has 2 minutes of downtime in a 30-day month, is the SLO met? Show the calculation.

14. **Cost Optimization**: List 5 ways to reduce the monthly infrastructure cost of this capstone platform below $500/month.

15. **Troubleshooting**: The application pods are in CrashLoopBackOff. Describe your systematic approach to diagnose and resolve the issue.

<details>
<summary>Answer Key</summary>

1. **Architecture**: DNS → CloudFront → ALB → Ingress-Nginx → API Pod → (PostgreSQL RDS + Redis). Health endpoint checks DB + Redis connectivity and returns 200.

2. **Terraform Resources**: `aws_vpc`, `aws_subnet` (public + private × 2 AZs), `aws_internet_gateway`, `aws_nat_gateway`, `aws_route_table`, `aws_route_table_association`. The EKS cluster uses `subnet_ids` in `vpc_config`.

3. **Cilium**: Uses eBPF to implement services, replaces iptables-based kube-proxy with efficient BPF programs. Hubble provides flow visibility — can see L3/L7 traffic between pods.

4. **Multi-stage**: Builder stage has gcc/libpq-dev for compilation; runtime stage is minimal with only runtime deps. Slim base + non-root reduces attack surface and image size.

5. **checksum/config**: Forces pod restart when ConfigMap changes. Without it, changing a ConfigMap doesn't trigger a new rollout — running pods would be out of sync.

6. **OIDC Flow**: GitHub Actions requests a JWT token, AWS STS exchanges it for temporary credentials via the OIDC identity provider. No static keys to rotate or leak.

7. **ESO Sync**: ExternalSecret CRD defines the mapping, SecretStore configures AWS auth. The operator polls `refreshInterval` (1h). Changes in AWS Secrets Manager are reflected in the K8s Secret within that interval.

8. **ServiceMonitor matches**: `spec.selector.matchLabels` must match Service labels. `namespaceSelector` must match the Service's namespace. The release label connects to the Prometheus instance.

9. **Stabilization window**: Prevents flapping — rapid scale-down when traffic drops briefly. During spikes, `scaleUp` has no stabilization (0s), so HPA responds immediately.

10. **Default deny**: Blocks all ingress. Pods in the same namespace cannot communicate. Must create allow policies that specify `podSelector` and `from` sources explicitly.

11. **PDB behavior**: Node drain evicts pods gradually. With `minAvailable: 2`, at most 3 of 5 pods can be unavailable simultaneously. If draining 2 pods at once would leave 3 (< 2 minAvailable), the eviction is delayed.

12. **Self-healing**: ReplicaSet controller creates replacement pods. Readiness probes prevent routing traffic to unready pods. Service load balancer distributes to healthy pods. HPA may scale up if needed.

13. **SLO calculation**: 30 days = 43,200 minutes; 99.9% = 43,200 × 0.001 = 43.2 minutes allowed downtime. 2 minutes < 43.2 minutes. ✅ SLO is met.

14. **Cost optimization**: (1) Spot instances for all workloads, (2) Single-AZ RDS with automated failover via RDS proxy, (3) Right-size nodes, (4) Use Graviton instances (20% cheaper), (5) Scale to 0 at night, (6) Use S3 lifecycle policies for backups, (7) Remove NAT gateways (use VPC endpoints).

15. **Troubleshooting approach**: (1) `kubectl describe pod` for events, (2) `kubectl logs --previous` for last crash, (3) Check resource limits vs. actual usage, (4) Verify ConfigMap/Secret values, (5) Check if image exists in registry, (6) Test DB connectivity from another pod, (7) Rollback to last working version.
</details>

---

*Linux SysAdmin Course | Part 60 of ∞ | Reverse Engineering Approach*
*Previous → Part 59: Site Reliability Engineering (SRE)*
*Next → This is the final part. Revisit any section or begin your production journey!*

[← Previous](part59.md) and [-> Reference](reference.md)


---

[← Previous](38-course-complete-what-youve-achieved.md) | [↑ Index](index.md)
