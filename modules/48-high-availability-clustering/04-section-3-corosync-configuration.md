## 🔍 Section 3: Corosync Configuration

### The Corosync Configuration File

The main configuration file is `/etc/corosync/corosync.conf`.

**Minimal 2-node configuration:**

```
totem {
    version: 2
    cluster_name: webcluster
    transport: knet
    crypto_cipher: aes256
    crypto_hash: sha256
}

nodelist {
    node {
        ring0_addr: 192.168.1.10
        name: node1
        nodeid: 1
    }
    node {
        ring0_addr: 192.168.1.11
        name: node2
        nodeid: 2
    }
}

quorum {
    provider: corosync_votequorum
    two_node: 1
}

logging {
    to_syslog: yes
    debug: off
}
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `transport: knet` | Kernel network transport (recommended) |
| `transport: udpu` | UDP unicast (older, stable) |
| `transport: udp` | UDP multicast (requires IGMP snooping) |
| `bindnetaddr` | Network address to bind to (e.g., `192.168.1.0`) |
| `mcastport` | Multicast/UDP port (default 5405) |
| `ring0_addr` / `ring1_addr` | Primary and secondary ring IPs |
| `nodeid` | Unique node identifier (1-255) |
| `two_node: 1` | Special quorum for 2-node clusters |

### Multi-Ring Configuration (Redundant Network)

```
totem {
    version: 2
    cluster_name: webcluster
    transport: knet
    crypto_cipher: aes256
    crypto_hash: sha256
    interface {
        ringnumber: 0
        bindnetaddr: 192.168.1.0
        mcastport: 5405
        ttl: 1
    }
    interface {
        ringnumber: 1
        bindnetaddr: 10.0.0.0
        mcastport: 5405
        ttl: 1
    }
}

nodelist {
    node {
        ring0_addr: 192.168.1.10
        ring1_addr: 10.0.0.10
        name: node1
        nodeid: 1
    }
    node {
        ring0_addr: 192.168.1.11
        ring1_addr: 10.0.0.11
        name: node2
        nodeid: 2
    }
}
```

With redundant rings, the cluster survives a network switch failure on one path.

### Verifying Corosync

```bash
# Check Corosync membership
corosync-cmapctl | grep members

# Show node list
corosync-quorumtool -p

# Check runtime status
corosync-cfgtool -s

# View logs
journalctl -u corosync -n 50
```

### The Totem Protocol

Corosync uses the Totem Single-Ring Ordering and Membership protocol:
1. A **token** circulates around the ring (node → node2 → node3 → ... → node)
2. Each node holds the token, sends any pending messages, then passes it
3. If a node misses the token (timeout), it's suspected dead
4. After **consensus** timeout, the node is expelled from membership
5. A new ring is formed with remaining nodes

```
Token flow in a 4-node ring:

node1 → node2 → node3 → node4 → node1
  ↑                              |
  └──────────────────────────────┘

Token lost = consensus protocol triggered:
"Has anyone seen node3?"
"No" × (N-1)
"Remove node3 from ring"
```





[← Previous](03-section-2-pacemaker-corosync-architecture.md) | [↑ Index](index.md) | [Next →](05-section-4-pacemaker-configuration.md)
