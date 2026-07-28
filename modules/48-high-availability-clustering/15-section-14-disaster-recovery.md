## 🔍 Section 14: Disaster Recovery

### Multi-Site Clustering

Extending HA across data centers:

```
Site A (Primary)          Site B (DR)
   ┌─────┐                  ┌─────┐
   │Node1│ ◄── DRBD sync ──► │Node2│
   └─────┘                  └─────┘
   VIP: 192.168.1.100       VIP: 192.168.2.100
```

### Stretched Clusters

A single cluster spanning two sites:

```
── Site A ──           ── Site B ──
Node1  Node2  ── WAN ── Node3  Node4
   ↕                    ↕
Shared storage (sync replication)
```

Challenges:
- Latency: sync replication over WAN is slow
- Split-brain: WAN link failure between sites
- Quorum: need an even number of nodes across sites + QDevice

### Synchronous vs Asynchronous Replication

| Type | How It Works | Use Case |
|------|-------------|----------|
| Sync | Write completes only after peer confirms | Local cluster, low latency |
| Async | Write returns immediately, peer catches up | DR across WAN, high latency |
| Semi-sync | Write completes after peer receives (not writes) | Balance of safety/speed |

### DRBD Replication Modes for DR

```bash
# Async replication (for WAN)
resource webdata {
    net {
        protocol A;
    }
    ...
}

# Semi-sync (for metro distance)
resource webdata {
    net {
        protocol B;
    }
    ...
}
```

### Failback Strategy

```bash
# Planned failback example
# 1. Sync data from current primary to original primary
drbdadm connect webdata

# 2. Wait for sync to complete
watch drbdadm status

# 3. Make original primary the new primary
drbdadm primary webdata

# 4. Move resources in Pacemaker
crm resource move web node1

# 5. Verify
crm status
```

### DR Testing

```bash
# DR test plan:

# 1. Isolate DR site from production network
iptables -A INPUT -s 192.168.1.0/24 -j DROP

# 2. Promote DRBD on DR node
drbdadm primary webdata

# 3. Mount filesystem
mount /dev/drbd0 /mnt/dr-test

# 4. Verify data integrity
find /mnt/dr-test -type f -exec md5sum {} \; > /tmp/dr-checksums

# 5. Test service startup
systemctl start httpd

# 6. Verify from test client
curl http://192.168.2.100/

# 7. Clean up and sync back
systemctl stop httpd
umount /mnt/dr-test
drbdadm secondary webdata
iptables -F
```





[← Previous](14-section-13-load-balancing-for.md) | [↑ Index](index.md) | [Next →](16-15-hands-on-practices.md)
