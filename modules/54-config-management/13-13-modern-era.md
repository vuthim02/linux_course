## 13. Modern Era

### Shift to GitOps (ArgoCD, Flux)

Git repo as source of truth → operator continuously converges cluster. Natural evolution of CM principles. The operator is like a Puppet agent or Salt minion for Kubernetes.

### Push-Based Lightweight Config (Ansible)

Industry moving toward simpler, push-based approaches. Ansible dominates server-level config in cloud-native environments. No agent to maintain. Ephemeral infrastructure uses "patch on boot" via cloud-init + Ansible pull.

### Immutable Infrastructure (Packer)

Bake AMIs/VM images with everything pre-configured. No mutations at runtime. Change config → bake new image → redeploy. Reduces need for runtime CM.

### Containers Reducing CM Needs

- **Containers took over**: Application deployment, dependency management, environment config.
- **CM still does**: Base OS hardening (SSH, NTP, kernel params), compliance (CIS benchmarks), stateful services (databases), legacy systems, monitoring agents, log shippers.

### Where Traditional CM Still Shines

1. **Stateful servers**: Databases, message queues, monitoring infra
2. **Compliance**: CIS benchmarks, DISA STIGs, PCI-DSS — automated compliance checking
3. **Edge/IoT**: Small-footprint agents (Salt on Raspberry Pi)
4. **Bare metal**: PXE boot → CM applies full config
5. **Legacy systems**: Pre-container apps on RHEL 7 / Ubuntu 16.04
6. **Network devices**: Ansible has strongest network module ecosystem
7. **Hybrid cloud**: Same CM across on-prem, AWS, Azure, GCP

---



---

[← Previous](12-12-comparative-analysis.md) | [↑ Index](index.md) | [Next →](14-15-hands-on-practices.md)
