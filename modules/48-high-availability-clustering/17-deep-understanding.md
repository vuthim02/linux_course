## 🔍 Deep Understanding

### How Corosync Handles Cluster Membership

Corosync uses the **Totem Single-Ring Ordering and Membership Protocol**:

1. **Token Rotation**: A token packet circulates around the ring. Each node must hold the token and pass it to the next node within a configurable timeout (`token: 1000ms` default).

2. **Token Loss Detection**: If a node doesn't receive the token within `token + token_retransmit` time, it retransmits the token. After `token + token_retransmits_before_loss_consensus` (default 3 retransmits), it suspects the next node is dead.

3. **Consensus Protocol**: The suspecting node broadcasts a `gather` message to all nodes. Each node responds with its membership list. If `N/2 + 1` nodes agree that the node is dead, a new ring configuration is formed excluding the dead node.

4. **Ring Reconfiguration**: A new token is generated, and operation continues with the reduced membership.

```
Timeline (4 → 3 nodes):
T0: node1 → node2 → node3 → node4 → node1 (normal)
T1: node4 crashes
T2: node3 retransmits token (timeout)
T3: node3 broadcasts "gather" — "is node4 alive?"
T4: node1: "dead", node2: "dead", node3: "dead" (consensus)
T5: node1 → node2 → node3 → node1 (new ring, 3 nodes)
Total detection time: ~token × (retransmits + 1) = ~4000ms
```

**Configuration impact:**
```bash
# Faster detection (but more false positives)
totem {
    token: 500
    token_retransmits_before_loss_consensus: 2
}

# Slower detection (more tolerant of network issues)
totem {
    token: 5000
    token_retransmits_before_loss_consensus: 8
}
```

### How Pacemaker Calculates Resource Placement

Pacemaker uses a **score-based** system to decide where resources run:

1. **Scores are integers** (range: -INFINITY to +INFINITY)
2. **Scores accumulate** from all sources: location constraints, stickiness, resource state
3. **Highest score wins** — the node with the highest score for a resource gets to run it

**Score sources:**

| Source | Default Value | Description |
|--------|--------------|-------------|
| Location preference | User-defined | `prefers node1=100` |
| Location ban | -INFINITY | `rule -inf: #uname eq node2` |
| Resource stickiness | 1 (or configured) | Preference to stay on current node |
| Colocation dependency | INFINITY | Must run with another resource |
| Migration threshold | 3 failures | Node gets -INFINITY after N failures |

**Example score calculation:**

```
Resource: webserver
Node1: stickiness=100 + location=50 = 150
Node2: stickiness=0 + location=0 = 0

→ webserver runs on node1

If node1 fails migration-threshold times:
Node1: -INFINITY (banned due to failures)
Node2: 0
→ webserver moves to node2
```

**Stickiness prevents unnecessary moves:**

Without stickiness, if both nodes have equal scores, the resource bounces on every recheck. With `resource-stickiness=100`, the running node gets +100, preventing flapping.

### How VRRP Works

VRRP (Virtual Router Redundancy Protocol, RFC 5798):

1. **Master Election**: The node with the highest `priority` becomes master. If priorities are equal, the highest IP wins.

2. **Advertisements**: Master sends VRRP advertisements to multicast address `224.0.0.18` every `advert_int` seconds. These are IP protocol 112 packets.

3. **Master Down Interval**: If backup nodes don't receive an advertisement for `3 × advert_int + skew_time`, they declare master dead.

   `skew_time = (256 - priority) / 256` — ensures higher-priority backups don't wait unnecessarily.

4. **Preemption**: By default, when a higher-priority node comes back, it preempts the current master. This can be disabled with `nopreempt`.

5. **ARP Takeover**: When a backup becomes master, it sends **gratuitous ARP** packets to update the switch's MAC table. The virtual IP is now associated with the new master's MAC address.

```
VRRP Packet Structure:
┌─────────────────────────────────────────┐
│ Version=3 | Type=1 (Advertisement)     │
│ Virtual Rtr ID (VRID) = 51             │
│ Priority = 200                         │
│ Count IP Addrs = 1                     │
│ Auth Type = 1 (simple)                 │
│ Advert Interval = 1                    │
│ Checksum                               │
│ IP Address = 192.168.1.100             │
│ Authentication Data                    │
└─────────────────────────────────────────┘
```

### How DRBD Replicates Writes Synchronously (Protocol C)

DRBD Protocol C ensures **every write** is committed on both nodes before returning success:

```
Client writes to /dev/drbd0 on node1:

1. Application: write(fd, data, 4096)
2. Kernel: bio submitted to DRBD block device
3. DRBD (node1): 
   a. Write to local disk (/dev/sda3)
   b. Send data to node2 over TCP (port 7788)
4. DRBD (node2):
   a. Receive data over TCP
   b. Write to local disk (/dev/sdb1)
   c. Send acknowledgment back to node1
5. DRBD (node1):
   a. Receive acknowledgment from node2
   b. Return "write complete" to application
6. Application: write() returns 4096

Total latency = max(local_write_time, network_RTT + remote_write_time)
```

**Protocol C guarantees:**
- After `write()` returns, data exists on both nodes
- If node1 crashes after `write()`, node2 has the data
- Zero data loss in single-node failure

**Performance impact:**
- Each write waits for the slower node + network round trip
- Protocol C adds ~0.5-5ms per write on a local network
- For WAN (20-100ms RTT), Protocol C is too slow → use Protocol A or B

```
Async replication (Protocol A):
Application → DRBD → Local disk → Return immediately → Send to peer
Latency: local disk speed only
Risk: last few writes lost on crash

Sync replication (Protocol C):
Application → DRBD → Local disk + Remote disk → Return
Latency: max(local, remote) + RTT
Risk: zero data loss
```





[← Previous](16-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](18-command-reference.md)
