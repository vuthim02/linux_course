## 🔍 Section 1: What Is High Availability?

### Start Here — What Do You Actually See?

When a single server goes down, the service it provides disappears with it. Users get connection timeouts, 502 errors, or blank screens. The business loses money, reputation, and trust.

**Reverse Engineering Question:** *What would it take to make a service survive server failure?*

### The Math of Availability

Availability is expressed as **uptime percentage** over a year:

| Uptime % | Downtime/year | Common Name |
|----------|--------------|-------------|
| 90%      | 36.5 days    | "One nine" — consumer grade |
| 99%      | 3.65 days    | "Two nines" — internal tools |
| 99.9%    | 8.76 hours   | "Three nines" — standard HA |
| 99.99%   | 52.56 minutes | "Four nines" — enterprise HA |
| 99.999%  | 5.26 minutes  | "Five nines" — carrier grade |

### MTBF, MTTR, SLA

- **MTBF (Mean Time Between Failures)** — how long the system runs on average before failing. Measured in hours or days.
- **MTTR (Mean Time To Recover)** — how long it takes to restore service after failure.
- **SLA (Service Level Agreement)** — contractual guarantee of availability (e.g., "99.9% uptime").

Availability formula:
```
Availability = MTBF / (MTBF + MTTR) × 100%
```

**Reverse Engineering:** To improve availability, you either *increase MTBF* (build more reliable components) or *decrease MTTR* (recover faster). Clustering focuses on MTTR — when a node fails, another takes over in seconds.

### SPOF Elimination

A **Single Point of Failure (SPOF)** is any component whose failure brings down the entire service. Common SPOFs:

```
┌─ Internet ──→ [ Router ] ──→ [ Switch ] ──→ [ Server ] ──→ [ Storage ]
                                                                    ↑
                                                               SPOF: one disk
```

To eliminate SPOFs:
- Redundant power supplies (dual PSU)
- RAID for disk redundancy
- Multiple network paths (bonding, teaming)
- **Multiple servers** (clustering)

### Redundancy vs High Availability

- **Redundancy** = having spare capacity (an extra server doing nothing)
- **High Availability** = automatic detection + failover

A redundant system still fails if the switchover is manual. HA is redundant *and* automated.

### Failover Models

| Model | Description | Recovery Time |
|-------|-------------|---------------|
| Active-Passive | One node active, one standby | 10-60s |
| Active-Active | Both nodes serve traffic | <1s (no failover needed) |
| N+1 | N active nodes, 1 spare | 10-60s |
| N+M | N active nodes, M spares | 10-60s |

### The Split-Brain Problem

Split-brain occurs when cluster nodes lose communication with each other but remain operational. Each node believes the *other* is dead and tries to take over shared resources.

```
Node A: "Node B is dead, I'll mount the filesystem"
Node B: "Node A is dead, I'll mount the filesystem"
─── BOTH WRITE TO SAME DISK → CORRUPTION ───
```

The solution is **fencing** (STONITH) — forcibly removing a node from the cluster so it cannot corrupt shared data.





[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-pacemaker-corosync-architecture.md)
