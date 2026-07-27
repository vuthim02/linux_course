## 🔍 Section 9: Cluster Filesystems

### GFS2 — Global File System 2

GFS2 allows multiple nodes to read/write the same filesystem simultaneously. It requires the **Distributed Lock Manager (DLM)**.

**Creating a GFS2 filesystem:**

```bash
# Install tools
dnf install -y gfs2-utils dlm

# Start DLM
crm configure primitive dlm ocf:pacemaker:controld \
    op monitor interval=30s
crm configure clone cl-dlm dlm \
    meta clone-max=2 clone-node-max=2 interleave=true

# Create GFS2 filesystem (run once from one node)
mkfs.gfs2 -p lock_dlm -j 2 -t webcluster:webdata /dev/drbd0

# Mount resource
crm configure primitive webfs ocf:heartbeat:Filesystem \
    params device=/dev/drbd0 directory=/var/www \
           fstype=gfs2 options="noatime,nodiratime" \
    op monitor interval=30s
```

### GFS2 Journals

Each node needs its own journal:

```bash
# Check journals
gfs2_edit -p journal /dev/drbd0

# Add a journal (if adding a node)
gfs2_jadd -j 3 /dev/drbd0
```

### OCFS2 — Oracle Cluster File System

Similar to GFS2 but optimized for Oracle databases:

```bash
# Install tools
dnf install -y ocfs2-tools

# Configure O2CB (Oracle Cluster manager)
o2cb init
o2cb register-cluster webcluster

# Create filesystem
mkfs.ocfs2 -L webdata -N 4 /dev/drbd0

# Mount with Pacemaker
crm configure primitive ocfs2fs ocf:heartbeat:Filesystem \
    params device=/dev/drbd0 directory=/var/www \
           fstype=ocfs2 \
    op monitor interval=30s
```

### Cluster Filesystem Comparison

| Feature | GFS2 | OCFS2 |
|---------|------|-------|
| Lock manager | DLM | DLM (via O2CB) |
| Max nodes | 256 | 256 |
| Journal | Per-node | Per-node |
| Performance | Good | Better for DB |
| Tools | gfs2-utils | ocfs2-tools |

### Shared Storage Requirements

- **Block-level shared storage**: SAN (FC/iSCSI), DRBD, or NBD
- **SCSI reservations**: Prevent concurrent access during failover
- **Clustered LVM (CLVM)**: Allow LVM operations from any node

```bash
crm configure primitive clvmd ocf:heartbeat:clvm \
    op monitor interval=30s

crm configure clone cl-clvmd clvmd \
    meta clone-max=2 clone-node-max=2 interleave=true
```

---



---

[← Previous](09-section-8-pacemaker-resources-deep.md) | [↑ Index](index.md) | [Next →](11-section-10-keepalived-vrrp.md)
