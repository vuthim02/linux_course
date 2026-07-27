## 🔍 Section 7: Quorum

### What Is Quorum?

Quorum is a voting mechanism that prevents split-brain. A cluster can only operate when it has **more than half** of the votes.

```
Quorum = N/2 + 1

3-node cluster: quorum = 2 votes needed
4-node cluster: quorum = 3 votes needed
5-node cluster: quorum = 3 votes needed
```

### Quorum in Corosync

Corosync's `votequorum` provider handles quorum:

```
Node count: 3
Quorum:     2 votes
Node1: ✓      Node2: ✓      Node3: ✗ (dead)
Votes: 2/3   → Quorum met → Cluster operates

Node1: ✓      Node2: ✗      Node3: ✗
Votes: 1/3   → No quorum   → Cluster freezes
```

### Two-Node Quorum

For 2-node clusters, quorum is problematic:

```
Node count: 2
Quorum: 2 votes needed (N/2 + 1)
If one node dies: 1/2 = no quorum = cluster halts!
```

Solution — `two_node: 1` in corosync.conf:

With `two_node=1`, the surviving node retains quorum as long as it can reach the disk/heartbeat path.

### QDevice (Quorum Device)

A **quorum device** acts as an external tie-breaker:

```
Node1: 1 vote     Node2: 1 vote     QDevice: 1 vote
Total: 3 votes    Quorum: 2 votes

Node1 dies → Node2 (1) + QDevice (1) = 2 votes → quorum OK
```

Configure QDevice:

```bash
# On the quorum device server
pcs qdevice setup model net --enable

# On cluster nodes
pcs qdevice add model net host=192.168.1.50
```

### Quorum Policy

```bash
# Check quorum status
corosync-quorumtool -p

# In Pacemaker
crm configure property no-quorum-policy=stop
# Options: stop | freeze | ignore | suicide
```

| Policy | Behavior Without Quorum |
|--------|------------------------|
| `stop` | All resources are stopped |
| `freeze` | Resources continue but no new starts |
| `ignore` | Full operation without quorum (dangerous) |
| `suicide` | Node fences itself |

---



---

[← Previous](07-section-6-stonith-shoot-the.md) | [↑ Index](index.md) | [Next →](09-section-8-pacemaker-resources-deep.md)
