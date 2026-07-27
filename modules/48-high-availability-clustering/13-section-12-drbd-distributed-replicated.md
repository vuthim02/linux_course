## 🔍 Section 12: DRBD — Distributed Replicated Block Device

### What Is DRBD?

DRBD mirrors block devices between servers over the network. It's like **RAID-1 over TCP/IP**.

```
node1: /dev/drbd0 ←→ network ←→ /dev/drbd0: node2
              ↕                          ↕
         /dev/sda3                   /dev/sdb1
         (local disk)               (local disk)
```

### DRBD Replication Modes

| Protocol | Description | Safety | Latency |
|----------|-------------|--------|---------|
| A | Write returns after local write | Low (async) | Lowest |
| B | Write returns after local + buffer on peer | Medium (semi-sync) | Medium |
| C | Write returns after local + write on peer | High (sync) | Highest |

### Installing DRBD

```bash
# RHEL/CentOS/Fedora
dnf install -y drbd-utils kmod-drbd

# Load module
modprobe drbd

# Verify
lsmod | grep drbd

# Debian/Ubuntu
apt update && apt install -y drbd-utils
```

### DRBD Resource Configuration

`/etc/drbd.d/global_common.conf`:

```
global {
    usage-count no;
}

common {
    net {
        protocol C;
    }
}
```

`/etc/drbd.d/webdata.res`:

```
resource webdata {
    device    /dev/drbd0;
    meta-disk internal;
    on node1 {
        address   192.168.1.10:7788;
        disk      /dev/sda3;
    }
    on node2 {
        address   192.168.1.11:7788;
        disk      /dev/sdb1;
    }
}
```

### Initializing DRBD

```bash
# On both nodes
drbdadm create-md webdata

# On both nodes
drbdadm up webdata

# Check status
drbdadm status
# → Both disks show Inconsistent/Inconsistent

# Make node1 primary (initial sync)
drbdadm primary --force webdata

# Create filesystem on the primary
mkfs.ext4 /dev/drbd0

# Mount
mount /dev/drbd0 /mnt/data

# Check sync status
cat /proc/drbd
```

### DRBD States

| State | Meaning |
|-------|---------|
| Primary | Node can read/write |
| Secondary | Node receives replication |
| UpToDate | Data is fully synchronized |
| Inconsistent | Data is not yet synced |
| WFConnection | Waiting for peer connection |
| StandAlone | No connection to peer |

### Switching Primary

```bash
# On current primary (node1)
umount /mnt/data
drbdadm secondary webdata

# On new primary (node2)
drbdadm primary webdata
mount /dev/drbd0 /mnt/data
```

### Dual-Primary (Active/Active)

For cluster filesystems (GFS2, OCFS2), both nodes can be primary simultaneously:

`/etc/drbd.d/webdata.res`:

```
resource webdata {
    device    /dev/drbd0;
    meta-disk internal;
    net {
        allow-two-primaries yes;
    }
    on node1 {
        address   192.168.1.10:7788;
        disk      /dev/sda3;
    }
    on node2 {
        address   192.168.1.11:7788;
        disk      /dev/sdb1;
    }
}
```

### DRBD + Pacemaker Integration

`/etc/drbd.d/webdata.res` with Pacemaker handler:

```
resource webdata {
    device    /dev/drbd0;
    meta-disk internal;
    on node1 {
        address   192.168.1.10:7788;
        disk      /dev/sda3;
    }
    on node2 {
        address   192.168.1.11:7788;
        disk      /dev/sdb1;
    }
}
```

Pacemaker configuration:

```bash
crm configure primitive drbd-webdata ocf:linbit:drbd \
    params drbd_resource=webdata \
    op monitor interval=30s

crm configure ms ms-drbd-webdata drbd-webdata \
    meta master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true

crm configure primitive webfs ocf:heartbeat:Filesystem \
    params device=/dev/drbd0 directory=/var/www fstype=ext4 \
    op monitor interval=30s

crm configure primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=10s

crm configure primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=30s

crm configure group web vip webfs apache

crm configure order ord-drbd inf: ms-drbd-webdata:promote web

crm configure colocation col-web inf: web ms-drbd-webdata:Master

crm configure property stonith-enabled=true
crm configure property no-quorum-policy=freeze
```

This creates a complete HA stack:
1. DRBD replicates `/dev/sda3` ↔ `/dev/sdb1` (Protocol C)
2. Pacemaker promotes DRBD to Primary on one node
3. Filesystem mounts on the primary
4. VIP moves with the filesystem
5. Apache starts on the VIP node
6. If node fails, STONITH kicks the failed node
7. DRBD promotes on the survivor
8. Everything restarts in correct order

---



---

[← Previous](12-section-11-keepalived-haproxy-integration.md) | [↑ Index](index.md) | [Next →](14-section-13-load-balancing-for.md)
