# 🐧 Linux System Administrator — Complete Course
## Part 48 of ∞: High Availability and Clustering — Pacemaker, Corosync, Keepalived

---

> **Course Philosophy:** We use **Reverse Engineering Tactics** — we start from *what you already see*, then dig down into *why it works that way*. Instead of memorizing theory first, you understand by taking things apart.

---

## 🎯 What You Will Achieve in Part 48

By the end of this part, you will:

- Understand **high availability** concepts: MTBF, MTTR, SLA, failover, split-brain, quorum
- Configure a **2-node Pacemaker + Corosync** cluster from scratch
- Set up **virtual IP**, **Apache**, and **filesystem** resources with monitoring
- Implement **STONITH** fencing to protect against split-brain
- Deploy **Keepalived + VRRP** for lightweight HA failover
- Integrate **HAProxy** with Keepalived for load-balanced HA web serving
- Configure **DRBD** replication and pair it with Pacemaker
- Understand **cluster filesystems** (GFS2, OCFS2) and **disaster recovery** patterns
- Complete **15 hands-on practices** building real high-availability clusters

---

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

---

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

---

## 🔍 Section 4: Pacemaker Configuration

### The crm Shell

Pacemaker management happens through the `crm` interactive shell or `pcs` (Red Hat style).

```bash
# Enter CRM shell
crm

# Interactive mode
crm(live) # configure
crm(live)configure # show
crm(live)configure # primitive webip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24
crm(live)configure # commit
crm(live)configure # exit
```

### Resources: Primitives, Groups, Clones, Multi-State

**Primitive** — a single resource:

```bash
crm configure primitive webip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=30s timeout=20s
```

**Group** — resources that must run together on the same node:

```bash
crm configure group webservice \
    webip \
    webserver \
    filesystem
```

**Clone** — a resource that runs on multiple nodes simultaneously:

```bash
crm configure clone cl-dlm dlm \
    meta clone-max=2 clone-node-max=2
```

**Multi-State (master/slave)** — a resource that runs as master on one node, slave on others:

```bash
crm configure ms ms-postgresql pgsqlms \
    meta master-max=1 master-node-max=1 \
    clone-max=2 clone-node-max=1 notify=true
```

### Constraints

**Colocation** — resources must run together (or apart):

```bash
# webip and webserver must be on the same node
crm configure colocation col-web inf: webip webserver

# Never run these on the same node
crm configure colocation col-anti neg: db1 db2
```

**Ordering** — resources must start in sequence:

```bash
# Start webip before webserver
crm configure order ord-web inf: webip webserver

# Stop in reverse order
crm configure order ord-web-stop inf: webserver webip
symmetrical=true
```

**Location** — prefer or avoid specific nodes:

```bash
# Prefer node1 for this resource
crm configure location loc-web webserver prefers node1=50

# Ban resource from node2
crm configure location loc-ban webserver rule -inf: #uname eq node2
```

### Resource Defaults

```bash
# Global resource defaults
crm configure rsc_defaults \
    resource-stickiness=100 \
    migration-threshold=3

# Global operation defaults
crm configure op_defaults \
    timeout=120s \
    record-pending=true
```

### Resource Operations

Each resource can define operations:

| Operation | Purpose |
|-----------|---------|
| `monitor` | Periodic health check |
| `start` | Start the resource |
| `stop` | Stop the resource |
| `reload` | Reload configuration |
| `migrate_to` / `migrate_from` | Live migration |

```bash
primitive webip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 \
    op start timeout=60s \
    op stop timeout=60s \
    op monitor interval=10s timeout=20s depth=0
```

### Viewing Cluster Status

```bash
# Summary
crm status

# Detailed
crm_mon -1 -r -f

# XML configuration
crm configure show

# Resource history
crm history

# Failcounts
crm resource failcount show
```

---

## 🔍 Section 5: Resource Agents

### OCF (Open Cluster Framework)

OCF scripts are the standard resource agents for Pacemaker. Located at `/usr/lib/ocf/resource.d/`.

```bash
# List available OCF providers
ls /usr/lib/ocf/resource.d/

# List agents for heartbeat provider
ls /usr/lib/ocf/resource.d/heartbeat/

# Get metadata for an agent
crm ra info ocf:heartbeat:IPaddr2

# List all agents
crm ra list ocf
```

**Common OCF agents:**

| Agent | Purpose |
|-------|---------|
| `IPaddr2` | Virtual IP address |
| `Filesystem` | Mount filesystem |
| `apache` | Apache httpd |
| `nginx` | Nginx web server |
| `postgresql` | PostgreSQL database |
| `pgsqlms` | PostgreSQL multi-state (master/slave) |
| `mysql` | MySQL/MariaDB |
| `Xen` | Xen virtual machine |
| `VirtualDomain` | libvirt/KVM VM |
| `LVM` | LVM volume group activation |
| `DRBD` | DRBD resource management |

### LSB (init.d) Scripts

Traditional init scripts work with Pacemaker via the `lsb` agent type:

```bash
crm configure primitive myapp lsb:myapp \
    op monitor interval=30s
```

Pacemaker calls `/etc/init.d/myapp start|stop|status`.

### systemd Resources

Systemd services can be managed directly:

```bash
crm configure primitive nginx systemd:nginx \
    op monitor interval=30s
```

### STONITH (Fence) Agents

```bash
# List fence agents
crm ra list stonith

# Get fence agent metadata
crm ra info stonith:fence_ipmilan
```

---

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

## 🔍 Section 8: Pacemaker Resources — Deep Dive

### Virtual IP — IPaddr2

```bash
crm configure primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
           nic=eth0:1 \
    op monitor interval=10s
```

When the active node fails, Pacemaker moves the VIP to the other node. The ARP table updates automatically (send_arp).

### Filesystem Resource

```bash
crm configure primitive fs ocf:heartbeat:Filesystem \
    params device=/dev/drbd/by-res/r0 \
           directory=/var/www \
           fstype=ext4 \
    op monitor interval=30s
```

### Apache Web Server

```bash
crm configure primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=30s \
    op start timeout=60s \
    op stop timeout=60s
```

### Nginx

```bash
crm configure primitive nginx ocf:heartbeat:nginx \
    params configfile=/etc/nginx/nginx.conf \
    op monitor interval=30s
```

### PostgreSQL (pgsqlms Multi-State)

```bash
crm configure primitive pgsql ocf:heartbeat:pgsqlms \
    params pgctl=/usr/bin/pg_ctl \
           pgdata=/var/lib/pgsql/data \
           repuser=replicator \
    op monitor interval=30s role=Master \
    op monitor interval=60s role=Slave \
    op start timeout=120s \
    op stop timeout=120s

crm configure ms ms-pgsql pgsql \
    meta master-max=1 master-node-max=1 \
           clone-max=2 clone-node-max=1 notify=true
```

### MySQL/MariaDB Replication

```bash
crm configure primitive mysql ocf:heartbeat:mysql \
    params binary=/usr/bin/mysqld_safe \
           datadir=/var/lib/mysql \
           socket=/var/lib/mysql/mysql.sock \
    op monitor interval=30s
```

### Xen/VM Resources

```bash
crm configure primitive vm-web ocf:heartbeat:Xen \
    params xmfile=/etc/xen/web-vm.cfg \
           name=web-vm \
    op monitor interval=30s \
    meta migration-threshold=1
```

### Complete Web Cluster Example

```bash
crm configure <<EOF
primitive vip ocf:heartbeat:IPaddr2 \
    params ip=192.168.1.100 cidr_netmask=24 \
    op monitor interval=10s

primitive fs ocf:heartbeat:Filesystem \
    params device=/dev/drbd/by-res/r0 \
           directory=/var/www fstype=ext4 \
    op monitor interval=30s

primitive apache ocf:heartbeat:apache \
    params configfile=/etc/httpd/conf/httpd.conf \
    op monitor interval=30s

primitive dlm ocf:pacemaker:controld \
    op monitor interval=30s

primitive clvmd ocf:heartbeat:clvm \
    op monitor interval=30s

group web-services vip fs apache

colocation col-web-services inf: web-services dlm clvmd
order ord-dlm inf: dlm clvmd web-services

property stonith-enabled=true
property no-quorum-policy=freeze
EOF
```

---

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

## 🔍 Section 10: Keepalived + VRRP

### What Is VRRP?

**Virtual Router Redundancy Protocol (VRRP)** is a standard (RFC 5798) that lets multiple routers share a virtual IP. One is master, the rest are backup.

Keepalived implements VRRP for Linux.

### Installation

```bash
# Debian/Ubuntu
apt update && apt install -y keepalived

# RHEL/CentOS/Fedora
dnf install -y keepalived

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

### Configuration: /etc/keepalived/keepalived.conf

**Master node (node1):**

```
global_defs {
    notification_email {
        admin@example.com
    }
    notification_email_from keepalived@example.com
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id LVS_MASTER
    vrrp_skip_check_adv_addr
    vrrp_strict
    vrrp_garp_interval 0
    vrrp_gna_interval 0
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 200
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Sup3rS3cr3t
    }
    virtual_ipaddress {
        192.168.1.100/24 dev eth0 label eth0:vip
    }
}
```

**Backup node (node2):**

```
global_defs {
    router_id LVS_BACKUP
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Sup3rS3cr3t
    }
    virtual_ipaddress {
        192.168.1.100/24 dev eth0 label eth0:vip
    }
}
```

### Key VRRP Parameters

| Parameter | Description |
|-----------|-------------|
| `state` | MASTER or BACKUP (determines startup role) |
| `virtual_router_id` | Unique VRID (0-255), must match on all nodes |
| `priority` | Higher = more likely to be master (0-255) |
| `advert_int` | Advertisement interval in seconds (default 1) |
| `auth_pass` | Simple password (max 8 chars in older versions) |
| `nopreempt` | Prevent preemption (non-preemptive mode) |
| `preempt_delay` | Delay before preempting (seconds) |

### Starting Keepalived

```bash
systemctl enable --now keepalived

# Check status
systemctl status keepalived

# Check VIP
ip addr show eth0

# Check logs
journalctl -u keepalived -f

# Test failover
systemctl stop keepalived  # VIP moves to backup
```

### How VRRP Works

1. **Master** sends VRRP multicast advertisements (`224.0.0.18`) every `advert_int` second
2. **Backup** listens for advertisements; if 3 × `advert_int` pass without hearing from master, it assumes master is dead
3. **Backup** transitions to MASTER and takes the VIP
4. **Gratuitous ARP** is sent to update switch ARP tables
5. When original master recovers, it sees a higher-priority master and stays BACKUP (or preempts if configured)

```
Normal state:
  [Client] → VIP (192.168.1.100) → Master (node1)
  
Master fails:
  [Client] → VIP (192.168.1.100) → Backup (node2)
  (transparent to client)

Master recovers:
  [Client] → VIP (192.168.1.100) → Master (node1) [with preemption]
  [Client] → VIP (192.168.1.100) → Backup (node2) [without preemption]
```

### Notify Scripts

```bash
vrrp_instance VI_1 {
    ...
    notify /etc/keepalived/notify.sh
    notify_master /etc/keepalived/master.sh
    notify_backup /etc/keepalived/backup.sh
    notify_fault /etc/keepalived/fault.sh
}
```

Example notify script:

```bash
#!/bin/bash
# /etc/keepalived/notify.sh
log_file="/var/log/keepalived-notify.log"

echo "$(date): State transition: $1 → $2 (VIP: $3)" >> $log_file

case "$2" in
    MASTER)
        systemctl start haproxy   # Start HAProxy when becoming master
        ;;
    BACKUP|FAULT)
        systemctl stop haproxy    # Stop HAProxy when backup
        ;;
esac
```

---

## 🔍 Section 11: Keepalived + HAProxy Integration

### Architecture

```
                        ┌─ [ Backend 1 :80 ]
                        │
[VIP: 192.168.1.100] → HAProxy (active) ──┼─ [ Backend 2 :80 ]
                        │          Keepalived│
                        └─ [ Backend 3 :80 ]
                                  │
                    ┌─ HAProxy (standby)
                    │   Keepalived
```

### HAProxy Configuration

```haproxy
# /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    maxconn 4096
    user haproxy
    group haproxy

defaults
    log global
    mode http
    option httplog
    option dontlognull
    retries 3
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend web_front
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk GET /health
    server web1 192.168.1.21:80 check inter 2000 rise 3 fall 3
    server web2 192.168.1.22:80 check inter 2000 rise 3 fall 3
    server web3 192.168.1.23:80 check inter 2000 rise 3 fall 3
```

### track_script — Health Monitoring

Keepalived can track a script's exit status:

```
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight -20
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    ...
    track_script {
        chk_haproxy
    }
}
```

If HAProxy dies, `killall -0 haproxy` returns non-zero. After 3 failures (6s), the instance weight drops by 20. If the other node has a higher effective priority, it becomes master.

### Complete HAProxy + Keepalived Configuration

```
global_defs {
    router_id HA_PROXY
}

vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight -50
    fall 2
    rise 2
}

vrrp_instance VI_WEB {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 200
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass mypass123
    }
    virtual_ipaddress {
        192.168.1.100/24
    }
    track_script {
        chk_haproxy
    }
    notify_master "/etc/keepalived/scripts/start-haproxy.sh"
    notify_backup "/etc/keepalived/scripts/stop-haproxy.sh"
    notify_fault "/etc/keepalived/scripts/stop-haproxy.sh"
}
```

### Testing the Integration

```bash
# Simulate HAProxy failure on master
systemctl stop haproxy

# Watch failover
tail -f /var/log/keepalived.log

# Verify VIP moved
ip addr show eth0 | grep 192.168.1.100

# Restore
systemctl start haproxy
```

---

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

## 🔍 Section 13: Load Balancing for HA

### DNS Round-Robin

Simplest load balancing — multiple A records for one hostname:

```
web.example.com. IN A 192.168.1.10
web.example.com. IN A 192.168.1.11
web.example.com. IN A 192.168.1.12
```

**Problems:**
- No health checking — clients get dead server IPs
- DNS caching defeats rotation
- Uneven load distribution

### IPVS (LVS — Linux Virtual Server)

Kernel-level load balancing built into Linux:

```bash
# Install ipvsadm
dnf install -y ipvsadm

# Add virtual service
ipvsadm -A -t 192.168.1.100:80 -s rr

# Add real servers
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.21:80 -g  # direct routing
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.22:80 -g
ipvsadm -a -t 192.168.1.100:80 -r 192.168.1.23:80 -g

# View status
ipvsadm -L -n
```

Scheduling algorithms: `rr` (round-robin), `wrr` (weighted), `lc` (least connection), `wlc` (weighted LC), `sh` (source hashing).

### HAProxy

Layer 7 load balancer with health checks:

```haproxy
global
    maxconn 4096
    user haproxy
    group haproxy
    daemon

defaults
    mode tcp
    retries 3
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend mysql_front
    bind *:3306
    default_backend mysql_back

backend mysql_back
    balance leastconn
    option mysql-check user haproxy_check
    server db1 192.168.1.31:3306 check
    server db2 192.168.1.32:3306 check backup
```

### Nginx Upstream

```nginx
upstream backend {
    server 192.168.1.21 weight=3;
    server 192.168.1.22;
    server 192.168.1.23 backup;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Active-Active vs Active-Passive

| Aspect | Active-Active | Active-Passive |
|--------|--------------|----------------|
| All nodes serve? | Yes | No (one standby) |
| Resource utilization | High | Low (wasted capacity) |
| Failover | Instant (other node already serving) | 10-60s |
| Complexity | Higher (session state, data sync) | Lower |
| Cost | Lower per-request (no idle hardware) | Higher (idle hardware) |

---

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

---

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

---

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

---

## 📋 Command Reference

| Command | Purpose |
|---------|---------|
| `crm status` | Show cluster status |
| `crm_mon -1 -r -f` | Real-time cluster monitor |
| `crm configure show` | Show full XML config |
| `crm configure primitive ...` | Create a resource |
| `crm configure group ...` | Create a resource group |
| `crm configure clone ...` | Create a cloned resource |
| `crm configure ms ...` | Create multi-state resource |
| `crm configure colocation ...` | Create colocation constraint |
| `crm configure order ...` | Create ordering constraint |
| `crm configure location ...` | Create location constraint |
| `crm resource move <rsc> <node>` | Move resource to node |
| `crm resource ban <rsc> <node>` | Ban resource from node |
| `crm node standby <node>` | Put node in standby |
| `crm node online <node>` | Bring node back online |
| `corosync-cmapctl` | Show Corosync cluster map |
| `corosync-quorumtool -p` | Show quorum status |
| `corosync-cfgtool -s` | Show Corosync transport status |
| `stonith_admin --reboot <node>` | Reboot node via fencing |
| `drbdadm create-md <res>` | Create DRBD metadata |
| `drbdadm up <res>` | Activate DRBD resource |
| `drbdadm down <res>` | Deactivate DRBD resource |
| `drbdadm primary <res>` | Set DRBD to primary |
| `drbdadm secondary <res>` | Set DRBD to secondary |
| `drbdadm status` | Show DRBD status |
| `cat /proc/drbd` | Detailed DRBD status |
| `mkfs.gfs2 -p lock_dlm -j 2 -t <cluster>:<data> <dev>` | Create GFS2 filesystem |
| `ipvsadm -L -n` | Show LVS table |
| `keepalived -t` | Test Keepalived config syntax |
| `journalctl -u keepalived -f` | Follow Keepalived logs |
| `pcs resource create` | Create resource (RHEL style) |
| `pcs cluster setup` | Set up cluster (RHEL style) |

---

## 📚 What's Coming in Part 49

**Part 49: Security Hardening and Auditing** — We'll cover:
- SELinux and AppArmor mandatory access control
- Firewalld, iptables, nftables
- OpenSCAP compliance scanning
- CIS benchmarks, hardening scripts
- Auditd, AIDE (file integrity)
- Fail2ban, SSH hardening
- Kernel hardening (sysctl, YAMA, KASLR)
- TLS certificate management
- Security auditing tools (Lynis, rkhunter, chkrootkit)
- Incident response fundamentals

---

## ✅ Self-Test: 15 Questions

**Score:** 12/15 correct = ready for Part 49.

**Question 1:** What is the minimum quorum needed for a 3-node cluster?
- A) 1
- B) 2
- C) 3
- D) 4

**Question 2:** What is the primary purpose of STONITH?
- A) Monitor cluster performance
- B) Forcefully remove a malfunctioning node
- C) Balance network traffic
- D) Provide virtual IP addressing

**Question 3:** Which DRBD protocol provides synchronous replication?
- A) Protocol A
- B) Protocol B
- C) Protocol C
- D) Protocol D

**Question 4:** In VRRP, what multicast address is used for advertisements?
- A) 224.0.0.1
- B) 224.0.0.18
- C) 239.255.255.250
- D) 224.0.0.5

**Question 5:** What is the formula for quorum in a cluster?
- A) N/2
- B) N/2 + 1
- C) (N-1)/2
- D) N - 1

**Question 6:** Which two layers make up the core of a Linux HA cluster stack?
- A) Docker + Kubernetes
- B) Corosync + Pacemaker
- C) Keepalived + HAProxy
- D) DRBD + LVM

**Question 7:** In Pacemaker, what does `resource-stickiness=100` do?
- A) Prevents resources from starting
- B) Makes resources prefer their current node
- C) Forces resources to run on all nodes
- D) Limits resources to 100MB memory

**Question 8:** What is the `track_script` option in Keepalived used for?
- A) Log all VRRP packets
- B) Monitor a service and adjust priority
- C) Track network throughput
- D) Audit configuration changes

**Question 9:** What is split-brain in a cluster context?
- A) A hardware failure in the CPU
- B) Nodes operate independently believing the other is dead
- C) A network split that doubles throughput
- D) A database partitioning scheme

**Question 10:** Which resource agent would you use for a virtual IP in Pacemaker?
- A) ocf:heartbeat:nginx
- B) ocf:heartbeat:IPaddr2
- C) ocf:heartbeat:Filesystem
- D) stonith:fence_ipmilan

**Question 11:** What filesystem allows multiple nodes to read/write simultaneously?
- A) ext4
- B) XFS
- C) GFS2
- D) NTFS

**Question 12:** What is the purpose of fencing_topology in Pacemaker?
- A) Define network topology for Corosync
- B) Provide fallback fencing methods
- C) Configure load balancing
- D) Set up storage replication

**Question 13:** In DRBD dual-primary mode, which additional component is required?
- A) A load balancer
- B) A cluster filesystem (GFS2/OCFS2)
- C) A second network interface
- D) A quorum device

**Question 14:** What happens on a VRRP backup node when `3 × advert_int` passes without hearing from master?
- A) The backup shuts down
- B) The backup transitions to MASTER
- C) The backup sends an alert only
- D) The backup restarts keepalived

**Question 15:** What is the `no-quorum-policy=stop` behavior?
- A) Cluster continues without quorum
- B) All resources stop if quorum is lost
- C) The node with the most resources survives
- D) Quorum is recalculated every minute

---

**Answers:** 1-B, 2-B, 3-C, 4-B, 5-B, 6-B, 7-B, 8-B, 9-B, 10-B, 11-C, 12-B, 13-B, 14-B, 15-B

---

## 📝 Summary

High Availability and Clustering is what separates a hobbyist Linux setup from a production-grade infrastructure. In this part, you learned:

- **Corosync** provides cluster membership and messaging via the Totem protocol
- **Pacemaker** manages resources using a sophisticated score-based placement engine
- **STONITH** fencing protects against data corruption in split-brain scenarios
- **Keepalived + VRRP** provides simple, reliable virtual IP failover
- **HAProxy** adds health-checked load balancing to the HA stack
- **DRBD** replicates block devices synchronously for data redundancy
- **GFS2/OCFS2** enable shared-write cluster filesystems on shared storage
- **Disaster recovery** extends HA across data centers with sync/async replication

The key insight: *High availability is not about preventing failures—it's about recovering from them automatically and transparently.*

---

*Previous → Part 47: Performance Tuning*
*Next → Part 49: Security Hardening and Auditing*

[← Previous](part47.md) | [Next →](part49.md)
