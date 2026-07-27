## 🔍 Section 6: STONITH — Shoot The Other Node In The Head

### Why Fencing Is Needed

Without fencing, a split-brain scenario destroys data:

```
Timeline:
1. Network switch between node1 and node2 dies
2. Node1: "node2 is dead, I'll take the filesystem"
3. Node2: "node1 is dead, I'll take the filesystem"  
4. BOTH nodes mount the shared LVM/GFS2 filesystem
5. BOTH nodes write to the same blocks
6. FILESYSTEM CORRUPTION — data loss
```

Fencing ensures that one node physically removes or isolates the other before taking over resources.

### STONITH Types

| Type | Method | Examples |
|------|--------|---------|
| Power fencing | Cut power to the node | fence_ipmilan, fence_ilo, fence_apc |
| Storage fencing | Cut access to shared storage | fence_scsi, fence_san |
| VM fencing | Kill the VM | fence_virt, fence_xvm |
| Network fencing | Disable network port | fence_ifence (switch ACL) |

### Configuring a Fence Device

**fence_virt** (for VM labs):

```bash
crm configure primitive stonith-vm stonith:fence_virt \
    params hostmap="node1:vm-node1;node2:vm-node2" \
    op monitor interval=60s
```

**fence_ipmilan** (for physical servers):

```bash
crm configure primitive stonith-ipmi stonith:fence_ipmilan \
    params ip=192.168.1.200 user=admin passwd=secret \
           lanplus=1 pcmk_host_map="node1:1;node2:2" \
    op monitor interval=60s
```

### Testing Fencing

```bash
# Trigger STONITH on node2 from node1
stonith_admin --reboot node2

# Check if it worked
crm status

# Check fence history
crm history fencing

# If no STONITH is configured, you must disable it for testing:
crm configure property stonith-enabled=false
```

### Fencing Topologies

For critical clusters, use a fencing topology with multiple methods:

```bash
crm configure fencing_topology \
    node1: ipmi, apc \
    node2: ipmi, apc
```

If IPMI fails, APC PDU power-off is the backup.

---



---

[← Previous](06-section-5-resource-agents.md) | [↑ Index](index.md) | [Next →](08-section-7-quorum.md)
