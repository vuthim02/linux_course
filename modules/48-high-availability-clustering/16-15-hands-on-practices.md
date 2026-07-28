## 🛠️ 15 Hands-On Practices

### Practice 1: Set Up Corosync on Two Nodes

**Goal:** Install and configure Corosync on node1 and node2.

```bash
# On both nodes
dnf install -y corosync pacemaker pcs

# Configure /etc/corosync/corosync.conf (see Section 3)

# Start Corosync
systemctl enable --now corosync

# Verify
corosync-cmapctl | grep members
```

### Practice 2: Start Pacemaker

**Goal:** Start Pacemaker and verify cluster communication.

```bash
# On both nodes
systemctl enable --now pacemaker

# Check status (from any node)
crm status

# Expected output:
# Last updated: ...
# 2 nodes configured
# 0 resources configured

# Check node list
crm node list
```

### Practice 3: Create a Virtual IP Resource

**Goal:** Add a virtual IP that floats between nodes.

```bash
crm configure primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=10s

crm status

# Test: VIP appears on one node
ip addr show | grep 192.168.1.100

# Move VIP to other node
crm resource move vip node2

# Verify
crm status
```

### Practice 4: Add an Apache Resource with Monitoring

**Goal:** Add Apache as a managed resource with health monitoring.

```bash
# Install Apache on both nodes
dnf install -y httpd

# Create a test page
echo "HA Cluster Test" > /var/www/html/index.html

# Add Apache resource
crm configure primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=10s timeout=20s \
    op start timeout=60s \
    op stop timeout=60s

# Group with VIP
crm configure group webservice vip apache
crm configure order ord-vip-apache inf: vip apache

# Test
curl http://192.168.1.100/
```

### Practice 5: Configure STONITH (fence_virt)

**Goal:** Enable fencing for a VM cluster.

```bash
# If using VMs, use fence_virt
crm configure primitive stonith-vm stonith:fence_virt \
    params hostmap="node1:vm-node1;node2:vm-node2" \
    op monitor interval=60s

# Enable STONITH
crm configure property stonith-enabled=true

# Test (from node1)
stonith_admin --reboot node2

# Verify node came back
crm status
```

### Practice 6: Set Quorum and Test Split-Brain

**Goal:** Understand quorum behavior by breaking cluster communication.

```bash
# Check current quorum
corosync-quorumtool -p

# Set no-quorum-policy
crm configure property no-quorum-policy=stop

# Simulate network failure (on node2)
iptables -A INPUT -s node1 -j DROP

# Observe node1 reaction (resources stop?)
crm status

# Restore connectivity
iptables -F
```

### Practice 7: Set Up Keepalived VRRP

**Goal:** Configure Keepalived with a floating IP on two nodes.

```bash
# Install
apt install -y keepalived
# OR dnf install -y keepalived

# On node1 (Master) — use config from Section 10
# On node2 (Backup) — use config from Section 10

# Start
systemctl enable --now keepalived

# Check VIP
ip addr show eth0 | grep 192.168.1.100

# Test failover
systemctl stop keepalived  # on master
# VIP moves to backup
```

### Practice 8: Test VRRP Failover

**Goal:** Verify VRRP failover and recovery behavior.

```bash
# From a client, continuously ping the VIP
ping 192.168.1.100

# In another terminal, stop keepalived on master
systemctl stop keepalived

# Observe: 1-3 lost pings during failover

# Restart master
systemctl start keepalived

# Check preemption behavior
tail -f /var/log/keepalived.log
```

### Practice 9: Configure HAProxy + Keepalived

**Goal:** Integrate HAProxy with Keepalived for a load-balanced web service.

```bash
# Install HAProxy on both load balancer nodes
dnf install -y haproxy

# Configure HAProxy (see Section 11)

# Configure Keepalived with track_script (see Section 11)

# Start on both nodes
systemctl enable --now haproxy keepalived

# Test from client
for i in {1..10}; do curl http://192.168.1.100/; done

# Simulate HAProxy failure on master
systemctl stop haproxy

# Watch failover
curl http://192.168.1.100/
```

### Practice 10: Configure a Basic DRBD Resource

**Goal:** Set up DRBD replication between two nodes.

```bash
# On both nodes (use separate disk/partition):
# /dev/sdb1 will be replicated

# Configure /etc/drbd.d/webdata.res (see Section 12)

# Create metadata
drbdadm create-md webdata

# Start DRBD
drbdadm up webdata

# Make node1 primary
drbdadm primary --force webdata

# Monitor sync
watch -n 1 cat /proc/drbd

# Create filesystem and use it
mkfs.ext4 /dev/drbd0
mount /dev/drbd0 /mnt/data
```

### Practice 11: Test DRBD Failover

**Goal:** Manually fail over a DRBD resource.

```bash
# On node1 (primary)
umount /mnt/data
drbdadm secondary webdata

# On node2
drbdadm primary webdata
mount /dev/drbd0 /mnt/data

# Verify data is identical
ls -la /mnt/data

# Fail back
umount /mnt/data
drbdadm secondary webdata
# On node1
drbdadm primary webdata
mount /dev/drbd0 /mnt/data
```

### Practice 12: DRBD + Pacemaker Integration

**Goal:** Let Pacemaker manage DRBD failover.

```bash
crm configure <<EOF
primitive drbd-webdata ocf:linbit:drbd \
    params drbd_resource=webdata \
    op monitor interval=30s

ms ms-drbd-webdata drbd-webdata \
    meta master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true

primitive webfs ocf:heartbeat:Filesystem \
    params device=/dev/drbd0 directory=/var/www \
           fstype=ext4 \
    op monitor interval=30s

primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=10s

primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=30s

group web vip webfs apache
order ord-drbd inf: ms-drbd-webdata:promote web
colocation col-web inf: web ms-drbd-webdata:Master
property stonith-enabled=false
property no-quorum-policy=ignore
EOF
```

### Practice 13: GFS2 on DRBD Dual-Primary

**Goal:** Create a shared GFS2 filesystem on DRBD dual-primary.

```bash
# Configure DRBD for dual-primary (see Section 12)

# Restart DRBD
drbdadm adjust webdata
drbdadm primary webdata  # on both nodes

# Install GFS2 tools
dnf install -y gfs2-utils dlm

# Start DLM via Pacemaker
crm configure primitive dlm ocf:pacemaker:controld \
    op monitor interval=30s
crm configure clone cl-dlm dlm \
    meta clone-max=2 clone-node-max=2 interleave=true

# Create GFS2 (run once from one node)
mkfs.gfs2 -p lock_dlm -j 2 -t webcluster:webdata /dev/drbd0

# Mount on both nodes
mkdir -p /var/www
mount /dev/drbd0 /var/www

# Write a file from node1, read it from node2
echo "GFS2 test" > /var/www/test.txt
cat /var/www/test.txt
```

### Practice 14: VRRP Notify Scripts

**Goal:** Execute custom actions on VRRP state changes.

```bash
# Create notify script
cat << 'EOF' > /etc/keepalived/scripts/vrrp-notify.sh
#!/bin/bash
case "$2" in
    MASTER)
        logger "VRRP: Became MASTER, starting services"
        systemctl start haproxy
        ;;
    BACKUP|FAULT)
        logger "VRRP: Became $2, stopping services"
        systemctl stop haproxy
        ;;
esac
EOF

chmod +x /etc/keepalived/scripts/vrrp-notify.sh

# Add to keepalived.conf:
vrrp_instance VI_1 {
    notify /etc/keepalived/scripts/vrrp-notify.sh
}

# Test by restarting keepalived
systemctl restart keepalived
```

### Practice 15: Real-World Integration — HA Web Server Cluster

**Goal:** Build a complete production-grade HA web server with Pacemaker + DRBD + VIP + Apache.

**Architecture:**

```
                     ┌──────────────────────┐
[ Users ] → VIP:     │ node1 OR node2       │
  192.168.1.100      │ ┌────────────────┐   │
                     │ │ Apache httpd   │   │
                     │ │ /var/www/      │   │
                     │ │ DRBD /dev/drbd0│   │
                     │ │ filesystem     │   │
                     │ └────────────────┘   │
                     └──────────────────────┘
                           ↕ DRBD sync
                     ┌──────────────────────┐
                     │ node2 (standby)      │
                     │ DRBD Secondary       │
                     └──────────────────────┘
```

**Full Configuration:**

```bash
# ==================== STAGE 1: DRBD Setup ====================

# /etc/drbd.d/global_common.conf
cat > /etc/drbd.d/global_common.conf << 'DRBDGLOBAL'
global {
    usage-count no;
}
common {
    net {
        protocol C;
    }
}
DRBDGLOBAL

# /etc/drbd.d/wwwdata.res
cat > /etc/drbd.d/wwwdata.res << 'DRBDRES'
resource wwwdata {
    device    /dev/drbd0;
    meta-disk internal;
    on node1 {
        address 192.168.1.10:7788;
        disk    /dev/sdb1;
    }
    on node2 {
        address 192.168.1.11:7788;
        disk    /dev/sdb1;
    }
}
DRBDRES

# Initialize
drbdadm create-md wwwdata
drbdadm up wwwdata
drbdadm primary --force wwwdata
mkfs.ext4 /dev/drbd0

# ==================== STAGE 2: Corosync + Pacemaker ====================

# /etc/corosync/corosync.conf — see Section 3

systemctl enable --now corosync pacemaker

# ==================== STAGE 3: Pacemaker Resources ====================

crm configure << 'PACEMAKER'
primitive drbd-wwwdata ocf:linbit:drbd \
    params drbd_resource=wwwdata \
    op monitor interval=30s

ms ms-drbd-wwwdata drbd-wwwdata \
    meta master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true

primitive wwwfs ocf:heartbeat:Filesystem \
    params device=/dev/drbd0 directory=/var/www \
           fstype=ext4 \
    op monitor interval=30s \
    op start timeout=60s \
    op stop timeout=60s

primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=10s

primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=10s timeout=20s \
    op start timeout=60s \
    op stop timeout=60s

group webservice vip wwwfs apache
order ord-drbd inf: ms-drbd-wwwdata:promote webservice
colocation col-drbd inf: webservice ms-drbd-wwwdata:Master

# STONITH (fence_virt for VMs, fence_ipmilan for physical)
primitive stonith-vm stonith:fence_virt \
    params hostmap="node1:vm-node1;node2:vm-node2" \
    op monitor interval=60s

property stonith-enabled=true
property no-quorum-policy=freeze
property resource-stickiness=100
PACEMAKER

# ==================== STAGE 4: Verify ====================

crm status
curl http://192.168.1.100/

# ==================== STAGE 5: Test Failover ====================

# Simulate node1 failure
crm node standby node1
crm status
curl http://192.168.1.100/   # Should still work, served by node2

# Bring node1 back
crm node online node1
crm status
```





[← Previous](15-section-14-disaster-recovery.md) | [↑ Index](index.md) | [Next →](17-deep-understanding.md)
