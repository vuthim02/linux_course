## 🔍 Section 2: Pacemaker + Corosync Architecture

### The Cluster Stack

A production HA cluster in Linux is built in layers:

```
┌──────────────────────────────────────────────┐
│         Application (Apache, Nginx, DB)       │
├──────────────────────────────────────────────┤
│         Resource Agents (OCF scripts)         │
├──────────────────────────────────────────────┤
│         Pacemaker (CRM / Policy Engine)       │ 
├──────────────────────────────────────────────┤
│         Corosync (Membership / Messaging)     │
├──────────────────────────────────────────────┤
│         Transport Layer (UDP / SCTP / knet)   │
├──────────────────────────────────────────────┤
│         Network (Ethernet / InfiniBand)       │
└──────────────────────────────────────────────┘
```

### Corosync — The Communication Layer

Corosync provides:
- **Cluster membership** — who is in the cluster? Uses the **Totem** protocol for agreement.
- **Messaging** — reliable ordered message passing between nodes.
- **Quorum** — does the cluster have enough nodes to operate?

Key characteristics:
- Totem single-ring or multi-ring configuration
- Token passing for membership verification (~expected token loss before declaring a node dead)
- UDP unicast (udpu) or multicast transport, or the newer **knet** (kernel net)

### Pacemaker — The Policy Engine

Pacemaker sits on top of Corosync and handles:
- **Resource management** — what services run where
- **Constraint evaluation** — ordering, colocation, anti-colocation
- **Score-based placement** — which node gets which resource
- **Fencing coordination** — trigger STONITH when needed

### Cluster Manager Comparison

| Feature | Pacemaker | Keepalived | Kubernetes |
|---------|-----------|------------|------------|
| Scope | General HA | VRRP + load balancing | Container orchestration |
| Resources | IP, FS, services, VMs | Virtual IP | Pods, services |
| Fencing | Full STONITH support | None | Pod eviction |
| Complexity | High | Low | High |
| State | Active/Passive, Active/Active | Active/Passive | Desired state |

### DLM, GFS2, OCFS2

For clustered filesystems:
- **DLM (Distributed Lock Manager)** — coordinates locks across nodes, required by GFS2
- **GFS2 (Global File System 2)** — shared-write filesystem using DLM
- **OCFS2 (Oracle Cluster File System)** — similar to GFS2, used with Oracle databases

### Fence Agents

Fence agents (STONITH) are scripts that power off or isolate a misbehaving node:

| Agent | Hardware | Mechanism |
|-------|----------|-----------|
| fence_ipmilan | Any IPMI-capable server | IPMI power off |
| fence_virt | Virtual machines | VM shutdown via hypervisor |
| fence_ilo | HP iLO | HP Lights-Out power control |
| fence_xvm | Xen virtual machines | Xen hypervisor shutdown |
| fence_drac | Dell DRAC | Dell Remote Access power |
| fence_apc | APC PDU | Power outlet power cycle |
| fence_amt | Intel AMT | Intel Active Management |

---



---

[← Previous](02-section-1-what-is-high.md) | [↑ Index](index.md) | [Next →](04-section-3-corosync-configuration.md)
