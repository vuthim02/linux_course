# 🐧 Linux System Administrator — Complete Course
## Part 28 of ∞: Network File System (NFS) — Remote File Sharing on Linux

---

> **Reverse Engineering Approach:** NFS is not "magic network folder sharing." It is a remote procedure call (RPC) protocol where your client sends structured function calls — `LOOKUP`, `READ`, `WRITE`, `GETATTR` — over the wire to a server. Every time you `ls` an NFS mount, your client sends an RPC. Every time you `cat` a file, the file data travels in RPC reply packets. Understanding NFS means understanding: the RPC layer, the portmapper, the mount protocol, the filehandle, the state machine for locks, and how the Linux VFS (Virtual File System) translates POSIX file operations into NFS RPCs. By the end of this part, you will know NFS from the wire up.

---

## 🎯 What You Will Achieve in Part 28

| Level | Focus | Skills Gained |
|-------|-------|--------------|
| **⭐ Level 1: Basic** | NFS Concepts & Installation | Understand RPC, XDR, protocol versions; install and verify NFS server |
| **⭐ Level 2: Intermediary** | Server/Client Configuration | Set up exports, mount shares, configure autofs, apply security (root_squash, Kerberos), troubleshoot |
| **⭐ Level 3: Advanced** | Performance & Internals | Tune rsize/wsize/RDMA, benchmark with nfsstat, understand pNFS, locking delegation, and deep protocol mechanics |

Complete **15 hands-on practices** across all levels.

---

## ⭐ Level 1: Basic — NFS Fundamentals and Installation

![NFS Protocol Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/NFS_Usage_Example.svg/220px-NFS_Usage_Example.svg.png)  
*NFS enables remote file sharing across a network. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand the NFS protocol — RPC, XDR, portmapper, and the differences between NFSv3, NFSv4, NFSv4.1, and pNFS. Install and verify the NFS server on your system.

## 🔍 Section 1: What Is NFS?

**Network File System (NFS)** is a distributed file system protocol originally developed by Sun Microsystems in 1984. It allows a client machine to access files over a network as if they were on local storage.

### Core Concepts

At its heart, NFS is built on three technologies:

1. **RPC (Remote Procedure Call)** — The client calls a function on the server: `LOOKUP("/home/user/file.txt")` → server returns a filehandle.
2. **XDR (External Data Representation)** — A standard way to serialize data so machines with different architectures (big-endian vs little-endian) can communicate.
3. **The Mount Protocol** — Before NFSv4, a separate `mountd` daemon handled the initial handshake: the client sends the path, server returns a filehandle.

```
Client                                Server
  |                                     |
  |--  RPC call: MOUNT("/export/data")  |
  |                                     |
  |<---- RPC reply: filehandle fh=0x--- |
  |                                     |
  |--  RPC call: LOOKUP(fh, "file.txt") |
  |                                     |
  |<---- RPC reply: fh=0x456 ----------- |
  |                                     |
  |--  RPC call: READ(fh, offset, len)  |
  |                                     |
  |<---- RPC reply: [file data] -------- |
```

### NFS Protocol Versions

| Version | Key Characteristics | Status |
|---------|-------------------|--------|
| **NFSv2** (1984) | UDP only, 32-bit file offsets, 2GB max file size | **Obsolete** |
| **NFSv3** (1995) | TCP+UDP, 64-bit offsets, async writes, 64-bit filesizes, separate mount+lock daemons | **Widely used** |
| **NFSv4** (2000) | TCP mandatory, single protocol port (2049), no separate mountd/lockd, stateful, compound RPCs, ACLs, UTF-8 | **Modern standard** |
| **NFSv4.1** (2010) | pNFS (parallel NFS), sessions (exactly-once semantics), referral support | **Latest major** |
| **NFSv4.2** (2016) | Server-side copy (copy_file_range), sparse files, space reservation | **Recent** |

### Stateless vs Stateful

**NFSv3 is mostly stateless:**
- The server does NOT track what files clients have open
- If the server reboots, clients reconnect and retry — no "open state" to lose
- Locks are handled by separate daemons (rpc.statd, rpc.lockd) — they are the *stateful* part
- Server crash recovery: client just retries RPCs until server comes back

**NFSv4 is stateful:**
- The server tracks open files, locks, and delegations
- Uses a **lease** system: clients must renew leases or server revokes state
- If server reboots, all state is lost and clients must re-establish
- The `OPEN` operation creates state on the server
- **Clients detect server reboot** via the `LEASE_MOVED` or `STALE_STATEID` error
- Recovery: clients use `OPEN_CONFIRM`, `LOCK` operations with special recovery flags

```bash
# Check which NFS version is in use
mount | grep nfs
# Output example:
# 192.168.1.100:/export/nfs on /mnt/nfs type nfs4 (rw,relatime,vers=4.2)
```

---

## ⭐ Level 2: Intermediary — NFS Server and Client Configuration

![NFS Server-Client Architecture](https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Client-server_model.svg/220px-Client-server_model.svg.png)  
*NFS follows a client-server model. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Set up an NFS server with /etc/exports configuration, mount shares on clients with optimal options, configure autofs for on-demand mounting, apply security settings (root_squash, sec=krb5), and troubleshoot common issues using rpcinfo, showmount, and nfsstat.

## 🔍 Section 2: NFS Server Setup

### Installing the NFS Server

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y nfs-kernel-server

# RHEL / CentOS / Fedora
sudo dnf install -y nfs-utils

# Verify installation
dpkg -l | grep nfs-kernel  # Debian
rpm -qa | grep nfs-utils   # RHEL
```

### The /etc/exports File

This is the core NFS server configuration. Every exported directory gets one line.

```bash
# Format:
# /path/to/export  client1(options)  client2(options)

# Examples:
# /etc/exports
/export/data        *(rw,sync,no_subtree_check,no_root_squash)
/export/backups     10.0.0.0/24(rw,sync,no_subtree_check)
/export/readonly    192.168.1.100(ro,sync,no_subtree_check)
/export/home        *.example.com(rw,sync,no_subtree_check,root_squash)
```

### Export Options Reference

| Option | Meaning |
|--------|---------|
| `ro` | Read-only access |
| `rw` | Read-write access |
| `sync` | Server replies only after data is written to disk (safe, slower) |
| `async` | Server replies before writing to disk (faster, data loss risk on crash) |
| `no_subtree_check` | Disable subtree checking (performance, recommended) |
| `subtree_check` | Verify file is in exported subtree (security, slower) |
| `root_squash` | Map root (uid 0) to anonymous user (nobody/nfsnobody) — **default** |
| `no_root_squash` | Root keeps root privileges — **dangerous** |
| `all_squash` | Map ALL users to anonymous |
| `anonuid=<uid>` | Set anonymous user UID |
| `anongid=<gid>` | Set anonymous user GID |
| `fsid=0` | Make this the NFSv4 pseudo-filesystem root |
| `fsid=<uuid>` | Set a unique filesystem ID |
| `insecure` | Allow connections from ports > 1024 |
| `secure` | Require connections from ports < 1024 (default) |
| `crossmnt` | Allow clients to access sub-mounts |
| `no_wdelay` | Disable write delay (synced with sync/async) |
| `wdelay` | Delay writes for batch commit |

### Applying Exports

```bash
# After editing /etc/exports, apply changes:
sudo exportfs -ra

# -r: re-export all directories
# -a: export all (or unexport all with -u)
# -v: verbose

# Show current exports
sudo exportfs -v

# Show what the server is currently exporting (from client perspective)
showmount -e localhost
```

### Exportfs Deep Dive

```bash
# Export a single directory without editing /etc/exports
sudo exportfs -o rw,sync,no_subtree_check 192.168.1.0/24:/export/data

# Unexport a directory
sudo exportfs -u 192.168.1.0/24:/export/data

# Unexport everything
sudo exportfs -ua
```

### The NFS Server Daemons

```bash
# NFSv3 requires multiple daemons:
#   nfsd        — the NFS server kernel threads
#   rpc.mountd  — handles mount requests
#   rpc.statd   — crash recovery / status monitoring
#   rpc.lockd   — file locking (can be in kernel)
#   rpc.rquotad — remote quota support
#   rpcbind     — portmapper (maps RPC programs to ports)

# NFSv4 ONLY needs:
#   nfsd        — kernel NFS server
#   rpcbind     — some versions still register with portmapper
# Everything else is optional

# Check status of all NFS-related services
sudo systemctl status nfs-server    # Main service
sudo systemctl status rpcbind       # Portmapper
sudo systemctl status nfs-mountd    # Mount daemon

# Start the NFS server
sudo systemctl enable --now nfs-server
```

### How rpcbind (portmapper) Works

NFSv3 does not use fixed ports for all its services. Instead, services register with rpcbind:

```bash
# Show RPC registrations
rpcinfo -p localhost

# Output:
#   program vers proto   port  service
#   100000    4   tcp    111  portmapper
#   100000    3   tcp    111  portmapper
#   100003    3   tcp   2049  nfs
#   100003    3   udp   2049  nfs
#   100003    4   tcp   2049  nfs
#   100005    1   tcp  40401  mountd
#   100005    1   udp  43881  mountd
#   100005    3   tcp  40401  mountd
#   100021    1   udp  41793  nlockmgr
#   100021    3   udp  41793  nlockmgr
#   ...
```

**The protocol flow for NFSv3 mount:**

```
1. Client asks rpcbind (port 111): "Where is program 100005 (mountd)?"
2. rpcbind replies: "mountd is on port 40401"
3. Client asks mountd (port 40401): "Mount /export/data please"
4. mountd replies with a root filehandle
5. Client uses the filehandle to make NFS calls (LOOKUP, READ, WRITE) on port 2049
```

### Fixing NFSv3 Ports (Firewall-Friendly)

Since mountd and lockd use random ports, you must fix them for firewalls:

```bash
# /etc/nfs.conf  (or /etc/default/nfs-kernel-server on Debian)
# Or /etc/sysconfig/nfs on RHEL

# Fix mountd port
RPCMOUNTDOPTS="-p 40001"

# Fix statd port
STATDOPTS="-p 40002 -o 40003"

# Fix lockd ports (kernel module parameters)
# /etc/modprobe.d/nfs.conf
options lockd nlm_tcpport=40004 nlm_udpport=40004
```

### showmount — Query the NFS Server

```bash
# Show all exported directories on a server
showmount -e 192.168.1.100

# Show all clients currently connected
showmount -a 192.168.1.100

# Show all exported directories (from server itself)
showmount -e localhost
```

---

## 🔍 Section 3: NFS Client Setup

### Installing the NFS Client

```bash
# Debian / Ubuntu
sudo apt install -y nfs-common

# RHEL / CentOS / Fedora
sudo dnf install -y nfs-utils
```

### Mounting an NFS Share

```bash
# Basic mount
sudo mount -t nfs 192.168.1.100:/export/data /mnt/data

# Specify NFS version
sudo mount -t nfs -o vers=4 192.168.1.100:/export/data /mnt/data
sudo mount -t nfs4 192.168.1.100:/export/data /mnt/data   # equivalent

sudo mount -t nfs -o vers=3 192.168.1.100:/export/data /mnt/data

# NFSv4 does NOT need the path — just the server (uses pseudo-filesystem)
sudo mount -t nfs4 192.168.1.100:/ /mnt/nfs4
# But typically you do specify a path:
sudo mount -t nfs4 192.168.1.100:/export/data /mnt/data
```

### Mount Options — Essential

```bash
# Hard vs Soft mounts
# hard (default): retry forever until server responds
# soft: return error after timeo retries — RISKY (data corruption possible)

# Example: soft mount with short timeout
sudo mount -t nfs -o soft,timeo=10,retrans=3 192.168.1.100:/export/data /mnt/data

# Hard mount (recommended for most cases — no data corruption)
sudo mount -t nfs -o hard,intr 192.168.1.100:/export/data /mnt/data
```

| Option | Description | Default |
|--------|-------------|---------|
| `hard` | Retry NFS requests forever until server responds | yes |
| `soft` | Return error after retrans retries | no |
| `intr` | Allow signals to interrupt a blocked NFS operation (deprecated in newer kernels) | no |
| `timeo=N` | Timeout in deciseconds (tenths of seconds) | 600 (60s) |
| `retrans=N` | Number of timeouts before major timeout (soft) or giving up | 3 |
| `rsize=N` | Read buffer size in bytes | 1048576 (1MB) |
| `wsize=N` | Write buffer size in bytes | 1048576 (1MB) |
| `noatime` | Don't update access times (performance) | off |
| `nodiratime` | Don't update directory access times | off |
| `noexec` | Prevent binary execution on this mount | off |
| `nosuid` | Ignore suid/sgid bits | off |
| `bg` | If mount fails, retry in background | no |
| `fg` | Mount in foreground (fail immediately) | yes |
| `lookupcache=N` | Cache lookup results: all, none, positive | all |
| `port=N` | NFS server port | 2049 |
| `proto=PROTO` | Transport protocol: tcp, udp | tcp |
| `sec=MODE` | Security flavor: sys, krb5, krb5i, krb5p | sys |
| `vers=N` | NFS version: 3, 4, 4.1, 4.2 | highest available |

### Hard vs Soft — The Critical Distinction

```bash
# HARD mount (default):
# Client keeps retrying — application blocks
# When server comes back, operation completes transparently
# NO data corruption — but applications hang
# USE: critical data services, databases

# SOFT mount:
# Client gives up after retrans retries
# Application gets EIO or EINTR error
# CAN cause file corruption — partial writes
# USE: read-only or non-critical data (if at all)
```

**The hard+intr compromise (older kernels):**
```bash
sudo mount -t nfs -o hard,intr,timeo=30 192.168.1.100:/export/data /mnt/data
```
Allows interrupt signal to break the hang. On modern kernels (2.6.25+), `intr` is deprecated — signals are handled differently.

### Performance Buffer Sizes

```bash
# Default is 1MB — often too large for slow networks
# Tune for your network:

# Fast LAN (1 GbE)
sudo mount -t nfs -o rsize=1048576,wsize=1048576 192.168.1.100:/export/data /mnt/data

# Slower network or high latency
sudo mount -t nfs -o rsize=32768,wsize=32768 192.168.1.100:/export/data /mnt/data

# Find optimal values (see Performance Tuning section)
```

### /etc/fstab for NFS Mounts

```bash
# Format: server:path  mountpoint  nfs  options  0 0

# NFSv4 mount
192.168.1.100:/export/data  /mnt/data  nfs4  rw,hard,intr,noatime,vers=4.2  0 0

# NFSv3 mount
192.168.1.100:/export/data  /mnt/data  nfs  rw,hard,intr,noatime,vers=3  0 0

# Mount all fstab entries
sudo mount -a
```

### /etc/fstab Options for NFS

```bash
# Recommended production NFSv4 fstab entry:
192.168.1.100:/export/data  /mnt/data  nfs4  rw,hard,noatime,vers=4.2,timeo=30,retrans=5  0 0

# With bg (background retry) — prevents boot hang if server is down:
192.168.1.100:/export/data  /mnt/data  nfs4  rw,hard,bg,noatime,vers=4.2  0 0

# With systemd automount (noauto, comment, then systemd handles it):
192.168.1.100:/export/data  /mnt/data  nfs4  noauto,noatime  0 0
```

### The _netdev Flag

```bash
# Critical for network filesystems — tells systemd to wait for network
192.168.1.100:/export/data  /mnt/data  nfs4  rw,hard,_netdev,noatime  0 0
```

Without `_netdev`, systemd might try to mount before the network is up.

### NFS and systemd Mount Units

Instead of fstab, you can create systemd mount units:

```bash
# /etc/systemd/system/mnt-data.mount
[Unit]
Description=NFS mount for /mnt/data
After=network-online.target
Wants=network-online.target

[Mount]
What=192.168.1.100:/export/data
Where=/mnt/data
Type=nfs4
Options=rw,hard,noatime,vers=4.2

[Install]
WantedBy=multi-user.target

# Enable
sudo systemctl enable mnt-data.mount
```

---

## 🔍 Section 4: NFSv4 Features

### The Pseudo-Filesystem

NFSv4 introduces the concept of a **pseudo-filesystem** — the server presents a single unified namespace, starting at the root `/` of the NFSv4 tree:

```bash
# On the server, you export multiple directories:
/export/data       *(rw)
/export/home       *(rw)
/export/backups    *(ro)

# With NFSv4, clients can see them all under the pseudo-root:
mount -t nfs4 server:/ /mnt/nfs4
ls /mnt/nfs4/
# data/  home/  backups/

# The pseudo-filesystem is NOT real — it's a virtual view
# It's defined by the server's NFSv4 "fsid" configuration

# Export with fsid=0 to mark the root:
/export  *(rw,fsid=0,no_subtree_check)
/export/data  *(rw,no_subtree_check)
/export/home  *(rw,no_subtree_check)
```

### ID Mapping — idmapd

NFSv4 uses string-based user/group identifiers (user@domain) instead of numeric UID/GIDs:

```bash
# /etc/idmapd.conf
[General]

# The domain MUST match on client and server
Domain = example.com

[Mapping]
Nobody-User = nobody
Nobody-Group = nogroup

# Restart after changes
sudo systemctl restart nfs-idmapd
```

**How ID mapping works:**
```
Server: uid=1000 (alice)  →  "alice@example.com"  →  sent over NFSv4
Client: receives "alice@example.com"  →  looks up local user  →  uid=1000
```

If domains don't match, all files appear owned by `nobody`.

```bash
# Check idmapd status
sudo systemctl status nfs-idmapd

# Debug idmapd
sudo rpc.idmapd -f -vvv
```

### Kerberos Authentication (sec=krb5)

NFSv4 supports Kerberos for strong authentication:

| Security Flavor | Description |
|----------------|-------------|
| `sec=sys` | Default — AUTH_SYS (trusts client's UID/GID claims) |
| `sec=krb5` | Kerberos authentication only |
| `sec=krb5i` | Kerberos authentication + integrity checking |
| `sec=krb5p` | Kerberos authentication + integrity + privacy (encryption) |

```bash
# Server: /etc/exports with Kerberos
/export/secure  *(rw,sec=krb5p)

# Client mount
sudo mount -t nfs4 -o sec=krb5p server:/export/secure /mnt/secure
```

**Kerberos setup (high-level):**
```bash
# 1. Install Kerberos packages
sudo apt install -y krb5-user krb5-config

# 2. Create NFS service principal
# On KDC:
kadmin.local -q "addprinc -randkey nfs/server.example.com"

# 3. Export keytab
kadmin.local -q "ktadd -k /etc/krb5.keytab nfs/server.example.com"

# 4. Set up /etc/exports with sec=krb5
/export/secure  *(rw,sec=krb5p)

# 5. On client, mount with Kerberos
kinit user@EXAMPLE.COM
sudo mount -t nfs4 -o sec=krb5p server:/export/secure /mnt/secure
```

### NFSv4 ACLs

NFSv4 supports rich ACLs (more granular than POSIX):

```bash
# View NFSv4 ACL
nfs4_getfacl /mnt/nfs4/file.txt

# Set NFSv4 ACL
nfs4_setfacl -a A::1000:RW /mnt/nfs4/file.txt  # Add RW for user 1000
nfs4_setfacl -a A:g:1001:RX /mnt/nfs4/file.txt  # Add RX for group 1001

# Remove ACL
nfs4_setfacl -x A::1000:RW /mnt/nfs4/file.txt
```

| ACL Permission | Meaning |
|----------------|---------|
| `R` | Read data |
| `W` | Write data |
| `X` | Execute |
| `D` | Delete |
| `a` | Append |
| `r` | Read attributes |
| `w` | Write attributes |
| `d` | Delete child |

### Compound RPC Operations

NFSv4 combines multiple operations into a single RPC:

```bash
# Instead of 4 RPC calls:
#   LOOKUP → OPEN → READ → CLOSE
# NFSv4 sends one compound:
#   PUTFH + OPEN + READ + CLOSE

# This dramatically reduces latency for metadata-heavy workloads
```

---

## ⭐ Level 3: Advanced — Performance, Internals, and Protocol Deep Dive

![pNFS Architecture](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/NFSv4.1_pNFS_Architecture.svg/220px-NFSv4.1_pNFS_Architecture.svg.png)  
*pNFS parallel data access — separating metadata from data. Image credit: Wikimedia Commons.*

> **Level 3 Goal:** Master NFS performance tuning with rsize/wsize, RDMA, and nfsstat benchmarking. Understand pNFS layout protocol, NFS locking delegation (v3 vs v4), and the deep internals of the NFS protocol stack. Compare NFS with other network filesystems.

## 🔍 Section 5: NFSv4.1 and pNFS

### What pNFS (Parallel NFS) Does

pNFS separates data and metadata paths:

```
Traditional NFS:
  Client <── ALL operations (metadata + data) ──> Server (single bottleneck)

pNFS:
  Client <── Metadata operations ──> Metadata Server (MDS)
  Client <── Data operations ──────> Data Servers (DS) in parallel
```

### pNFS Layout Types

| Layout | Description | Like |
|--------|-------------|------|
| `file` | File-level striping across DS | Traditional striping |
| `object` | Object-based storage devices (OSD) | Rare |
| `block` | Block-level access to SAN (iSCSI, FC) | Like direct disk access |
| `flexfiles` | Flexible files layout (NFSv4.2) | Most flexible |

### How pNFS Works (Protocol Flow)

```bash
# 1. Client sends OPEN to MDS
# 2. MDS returns filehandle + LAYOUT (describes where data is stored)
# 3. Client uses LAYOUT to read/write directly to Data Servers
# 4. All metadata operations still go through MDS
# 5. Client returns LAYOUT (scoped, timed, or revoked)

# The layout is a delegation — client caches it for parallel I/O
```

### Sessions (NFSv4.1)

NFSv4.1 introduces **sessions** — a transport-level mechanism for exactly-once semantics:

```bash
# Each session has:
#   - Session ID
#   - Slot table (for request ordering)
#   - Back channel (server can initiate RPCs to client)

# Sessions provide:
#   - Exactly-once RPC semantics (no duplicate operations)
#   - Trunking (multiple connections per session)
#   - Server-side recovery

# Check if session is active
cat /proc/self/mountstats | grep -A5 "nfs4"
```

### Checking pNFS Support

```bash
# Server: check if pNFS is enabled
cat /proc/fs/nfsd/threads

# Client: check if pNFS layout was granted
cat /proc/self/mountstats | grep "layouts:"

# Enable pNFS on server (kernel config)
sudo modprobe nfsd_layout_nfsv4_files
```

### NFSv4.1 Trunking

Multiple connections between client and server for better throughput:

```bash
# Multiple source ports → same NFS server
# Each TCP connection can use different paths (multi-path)

# Check trunking
cat /proc/net/rpc/use-gss-proxy 2>/dev/null
```

---

## 🔍 Section 6: Autofs — Automatic NFS Mounting

### Why Autofs?

- Mount NFS shares **on demand** (when accessed)
- Unmount after idle timeout (saves resources)
- No need for fstab entries for every share
- Handles server unavailability gracefully

### Installing Autofs

```bash
sudo apt install -y autofs    # Debian/Ubuntu
sudo dnf install -y autofs    # RHEL/Fedora
```

### Architecture of Autofs

```
                 /etc/auto.master
                       |
        ┌──────────────┼──────────────┐
        |              |              |
   /etc/auto.misc /etc/auto.net /etc/auto.home
        |              |              |
    Mount points   Dynamic NFS    Home dir
    defined in    browsing       mounts
    auto.misc
```

### The Master Map (/etc/auto.master)

```bash
# /etc/auto.master
# Format:  mount-point  map-file  [options]

/misc   /etc/auto.misc    --timeout=60
/net    /etc/auto.net     --timeout=300
/home   /etc/auto.home    --timeout=600

# Direct map (uses /- as mount point)
/-      /etc/auto.direct
```

### Indirect Map Example

```bash
# /etc/auto.home
# Format:  key  options  location
# When someone accesses /home/username, it mounts server:/export/home/username

*       -rw,hard,intr,noatime     server:/export/home/&

# The & substitutes the key (wildcard)

# Specific entries
data    -rw,hard,intr             192.168.1.100:/export/data
docs    -ro,hard,intr             192.168.1.100:/export/docs

# With multiple replicas (failover)
projects   -rw,hard,intr   server1:/export/projects server2:/export/projects
```

### Direct Map Example

```bash
# /etc/auto.direct
# Format:  /full/path  options  location

/projects/alpha    -rw,hard,intr    server1:/export/projects/alpha
/projects/beta     -rw,hard,intr    server1:/export/projects/beta
/opt/shared        -rw,hard,intr    192.168.1.100:/export/opt
```

### Executable Map (/etc/auto.net)

```bash
# /etc/auto.net — built-in script that scans the network
# Usage: In /etc/auto.master:
/net    /etc/auto.net    --timeout=60

# Then access:
ls /net/server1/
ls /net/192.168.1.100/export/data

# Custom executable map
# /etc/auto.custom.sh (must be executable)
#!/bin/bash
echo "data -rw,hard,intr 192.168.1.100:/export/data"
echo "docs -ro,hard,intr 192.168.1.100:/export/docs"

# Reference in auto.master:
/mycustom   /etc/auto.custom.sh   --timeout=60
```

### Wildcard and Key Substitution

```bash
# /etc/auto.share
# The & is replaced with the key being accessed
*       -rw,hard,intr    192.168.1.100:/export/&

# So "ls /share/backups" tries to mount 192.168.1.100:/export/backups
# And "ls /share/data" tries 192.168.1.100:/export/data
```

### Starting and Managing Autofs

```bash
# Start autofs
sudo systemctl enable --now autofs

# Restart after config changes
sudo systemctl restart autofs

# Check automount status
sudo automount --status

# Force unmount idle mounts
sudo umount -a -t autofs
```

### Autofs Options

| Option | Description |
|--------|-------------|
| `--timeout=N` | Unmount after N seconds of inactivity |
| `--ghost` | Show mount point directories even when not mounted |
| `--browse` | Allow browsing of directory (NFSv4) |
| `--negative-timeout=N` | Cache "no entry" for N seconds |

### Debugging Autofs

```bash
# Run in foreground with debug
sudo automount -f -v

# Check logs
journalctl -u autofs -f

# Show current mounts (autofs entries will appear)
mount | grep autofs
```

---

## 🔍 Section 7: Security

### Export Restrictions

```bash
# /etc/exports — restrict by IP, subnet, or domain

# Single host
/export/data  192.168.1.100(rw,sync)

# Subnet (CIDR)
/export/data  10.0.0.0/8(rw,sync)

# Domain wildcard
/export/data  *.example.com(rw,sync)

# Multiple clients
/export/data  192.168.1.0/24(rw) 10.0.0.5(rw)

# All (dangerous — avoid)
/export/data  *(rw,no_root_squash)
```

### root_squash — The Most Important Security Option

```bash
# root_squash (DEFAULT):
#   Client root (uid=0) is mapped to nobody/nfsnobody (uid=65534)
#   Prevents client root from writing to the export as root
#   Without root_squash, client root can:
#     - chown any file
#     - setuid anything
#     - delete protected files

# no_root_squash (DANGEROUS):
#   Client root keeps root privileges
#   Only use for dedicated NFS servers where you trust clients

# all_squash:
#   EVERY user is squashed to anonymous
#   Use for public read-only exports

# Example: secure configuration
/export/public   *(ro,all_squash,no_subtree_check)
/export/internal 192.168.1.0/24(rw,root_squash,no_subtree_check)
```

### Squash Behavior Matrix

| Export Option | Client root (uid=0) | Client user (uid=1000) |
|--------------|---------------------|----------------------|
| `no_root_squash` | Server root (uid=0) | Server user (uid=1000) |
| `root_squash` (default) | nobody (uid=65534) | Server user (uid=1000) |
| `all_squash` | nobody (uid=65534) | nobody (uid=65534) |

### sec= Options In Detail

```bash
# /etc/exports with different security flavors
/export/public    *(ro,sec=sys)
/export/internal  *(rw,sec=sys:krb5p)    # sys OR krb5p accepted
/export/secure    *(rw,sec=krb5i:krb5p)  # krb5i OR krb5p (no sys fallback)
/export/topsecret *(rw,sec=krb5p)        # krb5p only (encrypted)

# Mount with specific sec=
sudo mount -t nfs4 -o sec=krb5p server:/export/topsecret /mnt/secret
```

### NFS over TLS

Since Linux kernel 6.x, NFS can run over TLS for encryption without Kerberos complexity:

```bash
# Server side:
# Configure nfsd to use TLS
echo "1" | sudo tee /sys/module/sunrpc/parameters/enable_tls

# Generate certificates (or use Let's Encrypt)
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/nfs/nfsd-key.pem \
  -out /etc/nfs/nfsd-cert.pem -days 365 -nodes

# Client side:
sudo mount -t nfs4 -o xprtsec=tls server:/export/data /mnt/data
```

### Firewall Rules for NFS

```bash
# NFSv4 only (single port 2049)
iptables -A INPUT -p tcp --dport 2049 -s 192.168.1.0/24 -j ACCEPT

# NFSv3 needs more ports
iptables -A INPUT -p tcp --dport 111    -s 192.168.1.0/24 -j ACCEPT  # rpcbind
iptables -A INPUT -p tcp --dport 2049   -s 192.168.1.0/24 -j ACCEPT  # nfsd
iptables -A INPUT -p tcp --dport 40001  -s 192.168.1.0/24 -j ACCEPT  # mountd (fixed)
iptables -A INPUT -p tcp --dport 40002  -s 192.168.1.0/24 -j ACCEPT  # statd
iptables -A INPUT -p tcp --dport 40004  -s 192.168.1.0/24 -j ACCEPT  # lockd

# Using ufw
sudo ufw allow from 192.168.1.0/24 to any port 2049 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 111 proto tcp
```

### NFS Security Best Practices Checklist

```bash
# 1. Use root_squash (it's on by default — don't disable it)
# 2. Restrict exports to specific IPs/subnets, not *
# 3. Use ro for read-only exports
# 4. Use NFSv4 (simpler, fewer daemons, smaller attack surface)
# 5. Use Kerberos (sec=krb5p) for sensitive data
# 6. Run NFSv4 only (disable v3 if possible)
# 7. Fix mountd/statd ports for firewall rules
# 8. Mount with noexec, nosuid on the client
# 9. Use all_squash for anonymous/public exports
# 10. Monitor with auditd for suspicious access
```

---

## 🔍 Section 8: Performance Tuning

### rsize and wsize — The Buffer Size Tradeoff

```bash
# The read and write buffer size is the most impactful NFS tuning parameter

# Find your network MTU:
ip link show | grep mtu
# Typical: 1500 (Ethernet), 9000 (jumbo frames)

# For NFS, the maximum rsize/wsize should be:
#   rsize/wsize = (path MTU - IP header - TCP header - RPC header)
#   Practical max: 1048576 (1MB) for modern networks
```

### Testing rsize/wsize Performance

```bash
# Mount with different sizes and benchmark:
for size in 4096 8192 16384 32768 65536 131072 262144 524288 1048576; do
    sudo mount -t nfs -o rsize=$size,wsize=$size,noatime \
      192.168.1.100:/export/data /mnt/test

    echo "Testing rsize/wsize=$size:"
    dd if=/dev/zero of=/mnt/test/testfile bs=$size count=100 2>&1 | grep -E "copied|MB/s"

    sudo umount /mnt/test
done
```

### async vs sync Exports

```bash
# /etc/exports
/export/data  *(rw,sync)    # Safe — data written to disk before reply
/export/data  *(rw,async)   # Fast — reply before data hits disk

# sync: WRITE RPC → server writes to disk → sends reply (safe)
# async: WRITE RPC → server caches in RAM → sends reply (fast, risky)

# Performance difference:
#   sync:     ~50-200 MB/s (disk-bound)
#   async:    ~500-2000 MB/s (network-bound)

# Async data loss scenario:
# 1. Client writes file → server replies OK
# 2. Server crashes before writing to disk
# 3. File is gone — client thinks it was written
```

### NFS over RDMA (InfiniBand / RoCE)

RDMA (Remote Direct Memory Access) bypasses the kernel TCP stack:

```bash
# Check if RDMA is available
ibstat 2>/dev/null || echo "No InfiniBand"
rdma link show 2>/dev/null || echo "No RDMA"

# Mount with RDMA (if both sides support it)
sudo mount -t nfs4 -o rdma,port=20049 server:/export/data /mnt/data

# RDMA port is 20049 (not 2049)
```

### Read-Ahead and Write-Back Tuning

```bash
# Adjust read-ahead for NFS mounts
echo "1024" | sudo tee /sys/class/bdi/0:*/read_ahead_kb

# Adjust dirty page ratios for NFS writes
# Lower values = more synchronous, less data loss
echo "5" | sudo tee /proc/sys/vm/dirty_ratio
echo "3" | sudo tee /proc/sys/vm/dirty_background_ratio
```

### NFS Server Tuning

```bash
# Number of nfsd kernel threads
# Rule of thumb: 8 per CPU core
echo "256" | sudo tee /proc/fs/nfsd/threads

# Or set in /etc/nfs.conf:
[nfsd]
threads=256

# Increase max filehandles
ulimit -n 65536

# TCP backlog
echo "65536" | sudo tee /proc/sys/net/core/somaxconn

# Socket buffer sizes
echo "262144 524288 2097152" | sudo tee /proc/sys/net/ipv4/tcp_rmem
echo "262144 524288 2097152" | sudo tee /proc/sys/net/ipv4/tcp_wmem
```

### Cache Consistency

NFSv3 uses **close-to-open consistency**:

```
1. Client A opens file → gets fresh attributes from server
2. Client A writes data (cached locally)
3. Client A closes file → writes flushed to server
4. Client B opens file → sees Client A's changes
```

NFSv4 adds **delegations**:

```
The server can delegate file authority to a client:
  - READ delegation: client can cache reads without checking server
  - WRITE delegation: client can buffer writes without flushing to server
  - Server can recall delegations when another client needs access
```

### NFS Server Performance with nfsstat

```bash
# Server statistics
nfsstat -s

# Client statistics
nfsstat -c

# Show RPC statistics
nfsstat -r

# Show detailed NFSv4 operations
nfsstat -4
```

### Mountstats — Per-Mount Metrics

```bash
# Show detailed stats for all NFS mounts
cat /proc/self/mountstats

# Focus on a specific mount
grep -A100 "/mnt/data" /proc/self/mountstats | head -50

# The output includes:
#   bytes read/written
#   RPC count
#   retransmissions
#   major timeouts
#   read/write RTT (round-trip time)
```

---

## 🔍 Section 9: Troubleshooting

### rpcinfo — The First Tool for NFSv3 Diagnosis

```bash
# Check if the NFS server is reachable and what services it offers
rpcinfo -p 192.168.1.100

# Check a specific RPC program
rpcinfo -t 192.168.1.100 100003  # NFS (program 100003)
rpcinfo -u 192.168.1.100 100003  # NFS over UDP

# Check if rpcbind is alive
rpcinfo -p localhost

# Complete NFSv3 health check
SERVER=192.168.1.100
echo "portmapper:"
rpcinfo -t $SERVER 100000 && echo "OK" || echo "FAIL"
echo "NFS:"
rpcinfo -t $SERVER 100003 3 && echo "OK" || echo "FAIL"
echo "mountd:"
rpcinfo -t $SERVER 100005 3 && echo "OK" || echo "FAIL"
echo "statd:"
rpcinfo -t $SERVER 100024 1 && echo "OK" || echo "FAIL"
echo "lockd:"
rpcinfo -t $SERVER 100021 4 && echo "OK" || echo "FAIL"
```

### showmount — Check Exports

```bash
# What does the server advertise?
showmount -e 192.168.1.100

# Who is currently mounted?
showmount -a 192.168.1.100

# Common errors:
#   "mount clnt_program not registered" → rpcbind or mountd not running
#   "No such file or directory" → export path doesn't exist on server
#   "Permission denied" → export restriction or firewall
#   "RPC: Program not registered" → nfsd not running
```

### nfsstat — Statistics

```bash
# Server-side stats (run on server)
nfsstat -s
# Look for:
#   calls: total RPC calls received
#   badcalls: rejected calls (auth failures, etc.)
#   badclnt: bad client handles

# Client-side stats (run on client)
nfsstat -c
# Look for:
#   retrans: retransmitted requests (high = network issues)
#   authrefrsh: authentication refreshes

# NFSv4 specific
nfsstat -4
#   open: number of OPEN operations
#   close: number of CLOSE operations
#   deleg: delegation activity
```

### /proc/fs/nfsd/ — Kernel NFS Server Debug

```bash
# These files exist on the NFS server:
ls /proc/fs/nfsd/

# Threads — number of nfsd threads
cat /proc/fs/nfsd/threads

# File handles — current filehandle usage
cat /proc/fs/nfsd/filehandle

# Pool statistics (per-thread-pool stats)
cat /proc/fs/nfsd/pool_stats

# Export table (what's currently exported)
cat /proc/fs/nfsd/exports

# Client table (who's connected)
cat /proc/fs/nfsd/clients/*/info 2>/dev/null || echo "No clients"

# NFSv4 state (open files, locks, delegations)
cat /proc/fs/nfsd/nfsv4recovery
```

### mountstats — Client-Side Deep Dive

```bash
# The most detailed client debugging tool
cat /proc/self/mountstats

# Parse mountstats for specific fields
grep -A 10 "/mnt/data" /proc/self/mountstats

# Key metrics to watch:
#   RPC iostats:
#     - retrans: retransmitted requests (should be 0 or very low)
#     - sourcetimeouts: client timeouts
#     - xprt: TCP transport stats
#   NFS iostats:
#     - bytes: total bytes read/written
#     - ops: total operations
#     - rtt: round-trip time in microseconds
#     - execute: total execution time
```

### strace — Trace NFS System Calls

```bash
# Trace NFS operations on the client
strace -e trace=open,read,write,stat -f -o /tmp/nfs_trace.log \
  find /mnt/nfs -name "*.txt" 2>/dev/null

# Look for:
open("/mnt/nfs/file.txt", O_RDONLY) = 3
read(3, "data...", 65536) = 65536
# These are VFS calls that get turned into NFS RPCs

# Trace actual RPCs using rpcdebug
# Enable NFS debugging on client
echo "32767" | sudo tee /proc/sys/sunrpc/nfs_debug

# Watch kernel NFS debug
sudo dmesg -w | grep NFS
# WARNING: Very verbose — only for targeted debugging

# Disable debugging
echo "0" | sudo tee /proc/sys/sunrpc/nfs_debug
```

### Common NFS Problems and Solutions

```bash
# Problem: "mount.nfs: access denied by server"
# Solution: Check /etc/exports syntax, run exportfs -ra, check firewall

# Problem: "RPC: Program not registered"
# Solution: nfs-server not running, restart it
sudo systemctl restart nfs-server

# Problem: "Stale file handle"
# Solution: Directory was removed/renamed on server
sudo umount -f /mnt/nfs && sudo mount -a

# Problem: NFS mount hangs (server offline)
# Solution (hard mount):
sudo umount -f /mnt/nfs    # -f forces unmount

# Problem: "Permission denied" despite correct /etc/exports
# Solution: Check root_squash, file permissions, selinux/apparmor
getenforce                          # Check SELinux
sudo setenforce 0                   # Temporarily disable
sudo ausearch -m avc -ts recent     # Check SELinux denials

# Problem: Slow NFS performance
# Solution: Check rsize/wsize, network, server load
nfsstat -c | grep retrans
# If retrans > 0, you have network issues

# Problem: NFSv4 domain mismatch
# Solution: Set Domain in /etc/idmapd.conf on both sides
sudo rpc.idmapd -f -vvv > /tmp/idmapd.log &
```

### Debugging Specific NFSv4 Issues

```bash
# Check NFSv4 client ID
cat /proc/fs/nfsd/client_info/* 2>/dev/null

# Check NFSv4 lease duration
sudo cat /proc/fs/nfsd/lease_time

# Clear NFSv4 state on server (CAUTION: disrupts all clients)
sudo nfsdcltrack /proc/fs/nfsd/nfsv4recovery

# On client, check what NFSv4 state is active
cat /proc/net/rpc/nfs4.state
```

### SELinux and AppArmor for NFS

```bash
# SELinux: NFS-related booleans
getsebool -a | grep nfs
sudo setsebool -P nfs_export_all_rw on
sudo setsebool -P use_nfs_home_dirs on

# AppArmor: check if nfsd is confined
sudo aa-status | grep nfsd
sudo aa-complain /usr/sbin/rpc.mountd  # Set to complain mode
```

---

## 🔍 Section 10: NFS vs Other Network Filesystems

### Comparison Table

| Feature | NFSv4 | CIFS/SMB | GlusterFS | CephFS |
|---------|-------|----------|-----------|--------|
| **Protocol** | ONC RPC | SMB2/3 | Custom over TCP | CRUSH + librados |
| **Native to** | Linux/Unix | Windows | Linux | Linux |
| **POSIX compliance** | Full | Partial | Full | Mostly |
| **Locking** | Built-in (lease) | Oplocks/leases | POSIX locks | Distributed locks |
| **Kerberos** | Yes (sec=krb5) | Yes | No | No |
| **Encryption** | Kerberos/TLS | SMB3 encryption | SSL/TLS (TLS) | Encryption in-transit |
| **Parallel I/O** | pNFS (v4.1+) | SMB multi-channel | Yes (distributed) | Yes (distributed) |
| **Scalability** | Single server | Single server | Multi-server (distributed) | Multi-server (distributed) |
| **Clustering** | NFS-Ganesha + CTDB | Samba CTDB | Built-in | Built-in |
| **Snapshot** | No (filesystem dep.) | VSS (Windows) | Yes | Yes |
| **Ease of setup** | Easy | Moderate | Moderate | Complex |
| **Use case** | Linux-to-Linux file sharing | Windows interop | Scale-out NAS | Object + block + file |
| **Client in kernel?** | Yes | Yes | FUSE | FUSE (kclient experimental) |
| **License** | BSD (kernel) | GPL | GPLv2+ | LGPL |

### When to Use What

```bash
# NFS: Linux-to-Linux, simple shared storage, home directories
# CIFS/SMB: Windows clients, mixed environments, printers
# GlusterFS: Scale-out NAS, large media, high availability without SAN
# Ceph: Unified storage (block + object + file), cloud platforms, OpenStack

# Migration path: NFS → GlusterFS/Ceph for scaling
# Migration path: NFS → Samba for Windows clients
```

### Performance Comparison (Approximate)

```bash
# Single-stream throughput (1GbE):
#   NFSv4 sync:      ~112 MB/s
#   NFSv4 async:     ~112 MB/s (network-limited)
#   CIFS/SMB3:       ~110 MB/s
#   GlusterFS:       ~100-110 MB/s
#   CephFS (FUSE):   ~80-100 MB/s
#   CephFS (kclient): ~110 MB/s

# Metadata operations (creates/sec):
#   NFSv4:     ~5000
#   CIFS/SMB3: ~3000
#   GlusterFS: ~2000
#   CephFS:    ~1000-3000
```

---

## 🔍 Section 11: Locking in NFS

### NFSv3 — Separate Lock Daemons

NFSv3 uses **Network Lock Manager (NLM)** protocol, implemented by separate daemons:

```bash
# rpc.lockd — handles file locking
# rpc.statd — monitors server status for crash recovery

# On server:
sudo systemctl status nfs-lock    # lockd
sudo systemctl status nfs-statd   # statd

# Check that lock manager is registered
rpcinfo -p | grep nlockmgr
# 100021    1   tcp  41793  nlockmgr
# 100021    3   tcp  41793  nlockmgr
# 100021    4   tcp  41793  nlockmgr
```

**NFSv3 locking flow:**
```
1. Client A: LOCK(fh, range, type) via NLM
2. Server: checks if another client holds conflicting lock
3. If no conflict → grant lock, record state in rpc.statd
4. If conflict → deny or block (client can retry)
5. Client A: UNLOCK(fh, range) via NLM
```

**Crash recovery (NFSv3):**
```
1. Server crashes → all locks are lost
2. Server reboots → rpc.statd starts
3. Clients detect server reboot (SM_NOTIFY)
4. Clients re-establish locks via rpc.lockd
5. rpc.statd on client and server coordinate via /var/lib/nfs/statd/
```

### NFSv4 — Built-in Locking

NFSv4 integrates locking into the main protocol — no separate daemons:

```bash
# NFSv4 lock operations are part of the compound RPC:
# OPEN (with share access/deny modes)
# LOCK
# LOCKU (lock unlock)
# LOCKT (lock test)
# CLOSE

# NFSv4 uses LEASE-BASED locking:
# 1. Client requests lock
# 2. Server grants lock + sets a lease timer
# 3. Client sends RENEW before lease expires
# 4. If client doesn't renew → server revokes ALL client state

# Lease duration (default: 90 seconds)
cat /proc/fs/nfsd/lease_time
# Output: 90
```

### NFSv4 Delegations

A **delegation** gives a client exclusive control over a file:

```bash
# READ delegation:
#   Server guarantees no other client is writing
#   Client can cache reads without contacting server
#   Server RECALLS delegation if another client needs write access

# WRITE delegation:
#   Client can buffer writes locally
#   Server recalls before granting access to another client
#   Client flushes writes during recall

# Check delegations:
cat /proc/self/mountstats | grep "deleg"
#   delegations: current delegations held
#   delegations recalls: times server recalled delegations
```

### File Lock Commands

```bash
# Test locking with flock
flock /mnt/nfs/shared.lock -c "echo 'locked!'; sleep 10"

# Check locks on NFS mount
lslocks | grep NFS

# Check locks from server side
cat /proc/fs/nfsd/clients/*/states 2>/dev/null

# NFSv4 lock test
cat > /tmp/locktest.c << 'EOF'
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("/mnt/nfs/test.lock", O_RDWR | O_CREAT, 0644);
    struct flock fl = {F_WRLCK, SEEK_SET, 0, 0, 0};
    fl.l_pid = getpid();
    if (fcntl(fd, F_SETLK, &fl) == 0)
        printf("Lock acquired\n");
    else
        perror("Lock failed");
    close(fd);
    return 0;
}
EOF
gcc -o /tmp/locktest /tmp/locktest.c
/tmp/locktest
```

### Lock Compatibility Matrix

| Current \ Request | READ lock | WRITE lock |
|------------------|-----------|------------|
| None | Grant | Grant |
| READ lock | Grant | **Block** |
| WRITE lock | **Block** | **Block** |

### NFSv4 Lock Recovery

```bash
# On lock conflict or server reboot:
# 1. Client detects stale stateid (NFS4ERR_STALE_STATEID)
# 2. Client re-opens file
# 3. Client requests lock with reclaim flag
# 4. Server checks reclaim against /var/lib/nfs/v4recovery/

# Manual lock recovery (if automagic fails):
sudo umount /mnt/nfs
sudo mount -t nfs4 server:/export/data /mnt/nfs
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### 📘 Level 1 Practices: NFS Concepts and Installation

Install the NFS server, verify daemons, check RPC registrations, and export your first directory.

### ✅ Practice 1: Install and Verify NFS Server

```bash
mkdir -p ~/linux-course/part28
cd ~/linux-course/part28

# Install NFS server
sudo apt update && sudo apt install -y nfs-kernel-server nfs-common

# Verify the daemons are running
sudo systemctl status nfs-server --no-pager | head -20

# Check rpcbind registrations
rpcinfo -p localhost

# Identify which programs are registered:
#   100000 = portmapper
#   100003 = nfsd
#   100005 = mountd
#   100024 = statd

# Save output
rpcinfo -p localhost > rpcinfo_output.txt
cat rpcinfo_output.txt

echo "Practice 1 complete — NFS server is ready"
```

---

### ✅ Practice 2: Export a Directory via NFS

---

### 📘 Level 2 Practices: Client Setup, Autofs, Security, and Troubleshooting

Mount NFS shares with various options, configure autofs for on-demand mounting, apply security settings including root_squash and Kerberos, and practice troubleshooting with rpcinfo and showmount.

```bash
cd ~/linux-course/part28

# Create a directory to export
sudo mkdir -p /export/nfs/data
sudo chmod 777 /export/nfs/data

# Add an export entry
echo "/export/nfs/data *(rw,sync,no_subtree_check,no_root_squash)" | \
  sudo tee -a /etc/exports

# Apply exports
sudo exportfs -ra

# Verify export
sudo exportfs -v

# Check from client perspective (locally)
showmount -e localhost

echo "Practice 2 complete — directory exported"
```

---

### ✅ Practice 3: Mount NFS Share Locally (Loopback)

```bash
cd ~/linux-course/part28

# Create mount point
sudo mkdir -p /mnt/nfs_test

# Mount the local export (loopback NFS)
sudo mount -t nfs4 localhost:/export/nfs/data /mnt/nfs_test

# Verify mount
mount | grep nfs_test
df -h /mnt/nfs_test

# Test write access
echo "Hello from NFS client at $(date)" | sudo tee /mnt/nfs_test/testfile.txt
cat /mnt/nfs_test/testfile.txt

# Verify the file exists on the server side
ls -la /export/nfs/data/

# Unmount
sudo umount /mnt/nfs_test

echo "Practice 3 complete — loopback NFS mount works"
```

---

### ✅ Practice 4: NFS Mount Options Deep Dive

```bash
cd ~/linux-course/part28

# Mount with different options and compare
for opts in "hard,noatime" "soft,noatime,timeo=10,retrans=3" "hard,noatime,rsize=32768,wsize=32768"; do
    echo "=== Testing options: $opts ==="
    sudo mount -t nfs4 -o "$opts" localhost:/export/nfs/data /mnt/nfs_test

    # Run a quick benchmark
    dd if=/dev/zero of=/mnt/nfs_test/bench bs=1M count=100 2>&1 | tail -1
    dd of=/dev/null if=/mnt/nfs_test/bench bs=1M count=100 2>&1 | tail -1

    sudo umount /mnt/nfs_test
done

# Test hard mount behavior (must be run as root)
# Open a second terminal and run:
# sudo umount -f /mnt/nfs_test
# Meanwhile, in the first terminal:
sudo mount -t nfs4 -o hard localhost:/export/nfs/data /mnt/nfs_test
# Try: cat /mnt/nfs_test/testfile.txt (will block if server unavailable)

sudo umount /mnt/nfs_test

echo "Practice 4 complete — mount options explored"
```

---

### ✅ Practice 5: /etc/fstab NFS Mount

```bash
cd ~/linux-course/part28

# Create mount point
sudo mkdir -p /mnt/nfs_auto

# Add to /etc/fstab
echo "localhost:/export/nfs/data /mnt/nfs_auto nfs4 rw,hard,intr,noatime,_netdev 0 0" | \
  sudo tee -a /etc/fstab

# Mount all fstab entries (then unmount)
sudo mount /mnt/nfs_auto
mount | grep nfs_auto
sudo umount /mnt/nfs_auto

# Remove the fstab entry
# (backup fstab first)
sudo cp /etc/fstab /etc/fstab.backup
sudo sed -i '/nfs_auto/d' /etc/fstab

echo "Practice 5 complete — fstab NFS mount configured"
```

---

### ✅ Practice 6: Create a Systemd Mount Unit for NFS

```bash
cd ~/linux-course/part28

# Create a systemd mount unit
sudo tee /etc/systemd/system/mnt-nfs_systemd.mount << 'EOF'
[Unit]
Description=NFS mount for systemd practice
After=network-online.target
Wants=network-online.target

[Mount]
What=localhost:/export/nfs/data
Where=/mnt/nfs_systemd
Type=nfs4
Options=rw,hard,noatime,vers=4.2

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p /mnt/nfs_systemd
sudo systemctl daemon-reload

# Start and verify
sudo systemctl start mnt-nfs_systemd.mount
sudo systemctl status mnt-nfs_systemd.mount --no-pager | head -15
mount | grep nfs_systemd

# Test access
echo "Systemd mount unit test" | sudo tee /mnt/nfs_systemd/systemd_test.txt

# Stop and disable
sudo systemctl stop mnt-nfs_systemd.mount
sudo systemctl disable mnt-nfs_systemd.mount
sudo rm /etc/systemd/system/mnt-nfs_systemd.mount
sudo systemctl daemon-reload

echo "Practice 6 complete — systemd mount unit created"
```

---

### ✅ Practice 7: Configure Autofs for NFS

```bash
cd ~/linux-course/part28

# Install autofs
sudo apt install -y autofs

# Create an indirect autofs map
sudo tee /etc/auto.nfs << 'EOF'
# Auto-mount map for NFS shares
data    -rw,hard,intr,noatime    localhost:/export/nfs/data
EOF

# Add to auto.master
echo "/nfs  /etc/auto.nfs  --timeout=60 --ghost" | sudo tee -a /etc/auto.master

# Restart autofs
sudo systemctl restart autofs

# Test: access the mount point
ls -la /nfs/data

# Verify it's actually mounted
mount | grep /nfs/data
df -h /nfs/data

# Test auto-unmount (wait 60 seconds or force)
sudo systemctl status autofs --no-pager | head -10

# Show autofs statistics
automount --status 2>&1 | head -20

echo "Practice 7 complete — autofs configured"
```

---

### ✅ Practice 8: Wildcard Autofs Map

```bash
cd ~/linux-course/part28

# Create additional export for wildcard test
sudo mkdir -p /export/nfs/docs
sudo chmod 777 /export/nfs/docs
echo "/export/nfs/docs *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra

# Create a direct map with wildcard
sudo tee /etc/auto.nfs_direct << 'EOF'
# Wildcard indirect map — & substitutes the key
*       -rw,hard,intr,noatime   localhost:/export/nfs/&
EOF

# Add to auto.master
echo "/nfswild  /etc/auto.nfs_direct  --timeout=60" | sudo tee -a /etc/auto.master

sudo systemctl restart autofs

# Test wildcard: accessing /nfswild/data should mount /export/nfs/data
ls -la /nfswild/data
mount | grep nfswild

# Test wildcard: accessing /nfswild/docs should mount /export/nfs/docs
ls -la /nfswild/docs
mount | grep nfswild

echo "Practice 8 complete — wildcard autofs working"
```

---

### ✅ Practice 9: Export Security — root_squash

```bash
cd ~/linux-course/part28

# Create a separate export with root_squash (default behavior)
sudo mkdir -p /export/nfs/squashed
sudo chmod 777 /export/nfs/squashed

echo "/export/nfs/squashed *(rw,sync,no_subtree_check,root_squash)" | \
  sudo tee -a /etc/exports

# Create an export WITHOUT root_squash
sudo mkdir -p /export/nfs/nosquash
sudo chmod 777 /export/nfs/nosquash

echo "/export/nfs/nosquash *(rw,sync,no_subtree_check,no_root_squash)" | \
  sudo tee -a /etc/exports

sudo exportfs -ra

# Mount both and test root behavior
sudo mkdir -p /mnt/squashed /mnt/nosquash

sudo mount -t nfs4 localhost:/export/nfs/squashed /mnt/squashed
sudo mount -t nfs4 localhost:/export/nfs/nosquash /mnt/nosquash

# As root, create a file owned by root
sudo touch /mnt/squashed/rootfile.txt
sudo touch /mnt/nosquash/rootfile.txt

# Check ownership
echo "Squashed (root_squash) — root file owned by:"
ls -la /mnt/squashed/rootfile.txt

echo "No-squash (no_root_squash) — root file owned by:"
ls -la /mnt/nosquash/rootfile.txt

# The difference: squashed file should be owned by nobody/nfsnobody
# nosquash file should be owned by root

sudo umount /mnt/squashed /mnt/nosquash

echo "Practice 9 complete — root_squash behavior observed"
```

---

### ✅ Practice 10: Kerberos Preparation (Keytab Setup)

```bash
cd ~/linux-course/part28

# Install Kerberos client
sudo apt install -y krb5-user 2>&1 | tail -5 || echo "Kerberos installed or already present"

# Check if a KDC is running locally
sudo systemctl status krb5-kdc --no-pager 2>/dev/null | head -5 || echo "No KDC — will simulate"

# Create a Kerberos configuration for demo
sudo tee /etc/krb5.conf << 'EOF'
[libdefaults]
  default_realm = EXAMPLE.COM
  dns_lookup_realm = false
  dns_lookup_kdc = false
[realms]
  EXAMPLE.COM = {
    kdc = localhost
    admin_server = localhost
  }
EOF

# Test: export with Kerberos option in /etc/exports
echo "# Simulated Kerberos export (requires KDC for real use)" | \
  sudo tee -a /etc/exports
echo "# /export/secure *(rw,sec=krb5p)" | sudo tee -a /etc/exports

# Show the sec= option in the exports file
grep -n "sec=krb5" /etc/exports

# Re-export (ignores comments)
sudo exportfs -ra

echo "Practice 10 complete — Kerberos config structure in place"
echo "Real Kerberos NFS requires: KDC, service principal, keytab"
```

---

### ✅ Practice 11: Troubleshoot with rpcinfo and showmount

---

### 📘 Level 3 Practices: Performance Tuning and Protocol Internals

Benchmark NFS performance with dd and nfsstat, tune rsize/wsize for optimal throughput, test locking and delegation, and build a multi-client NFS deployment with autofs and security.

```bash
cd ~/linux-course/part28

# Create a troubleshooting test

# 1. Health check script
cat > nfs_health_check.sh << 'EOF'
#!/bin/bash
echo "=== NFS Health Check ==="
echo "Date: $(date)"
echo ""

# Check rpcbind
echo "1. rpcbind status:"
if rpcinfo -p localhost > /dev/null 2>&1; then
    echo "   ✓ rpcbind is responding"
    rpcinfo -p localhost | grep -E "nfs|mount|nlock|statd" | \
      awk '{printf "   %s (v%s) on port %s\n", $4, $3, $5}'
else
    echo "   ✗ rpcbind is NOT responding"
fi
echo ""

# Check exports
echo "2. Exported directories:"
showmount -e localhost 2>/dev/null | tail -n +2 | \
  while read line; do echo "   $line"; done
echo ""

# Check mount
echo "3. Active NFS mounts:"
mount -t nfs4,nfs 2>/dev/null | head -20
echo ""

# Check nfsd threads
echo "4. NFS server threads:"
cat /proc/fs/nfsd/threads 2>/dev/null || echo "   Not available"
echo ""

# Check NFS version
echo "5. NFS kernel module info:"
modinfo nfsd 2>/dev/null | grep -E "version|description" | head -3
echo ""

echo "=== End of Health Check ==="
EOF

chmod +x nfs_health_check.sh
./nfs_health_check.sh

echo "Practice 11 complete — troubleshooting tools explored"
```

---

### ✅ Practice 12: Performance Benchmarking with dd and nfsstat

```bash
cd ~/linux-course/part28

# Mount with default options
sudo mount -t nfs4 localhost:/export/nfs/data /mnt/nfs_test

# Collect baseline statistics
nfsstat -c > nfsstat_before.txt
cat nfsstat_before.txt

# Run a write benchmark
echo "=== Write Benchmark ==="
dd if=/dev/zero of=/mnt/nfs_test/perf_test bs=1M count=500 2>&1

# Run a read benchmark
echo "=== Read Benchmark ==="
echo 3 | sudo tee /proc/sys/vm/drop_caches  # Clear cache
dd if=/mnt/nfs_test/perf_test of=/dev/null bs=1M count=500 2>&1

# Check statistics after
nfsstat -c > nfsstat_after.txt
diff nfsstat_before.txt nfsstat_after.txt || true

# Check mountstats for detailed info
grep -A30 "/mnt/nfs_test" /proc/self/mountstats | head -30

# Clean up
sudo rm /mnt/nfs_test/perf_test
sudo umount /mnt/nfs_test

echo "Practice 12 complete — performance baseline captured"
```

---

### ✅ Practice 13: Tune rsize/wsize for Performance

```bash
cd ~/linux-course/part28

# Test different rsize/wsize values
for size in 16384 32768 65536 131072 262144 524288 1048576; do
    sudo mount -t nfs4 -o rsize=$size,wsize=$size,noatime \
      localhost:/export/nfs/data /mnt/nfs_test

    echo "Testing rsize/wsize = $size bytes:"
    echo -n "  Write: "
    dd if=/dev/zero of=/mnt/nfs_test/bench bs=$size count=200 2>&1 | \
      grep -o "[0-9.]\+ MB/s" || \
      dd if=/dev/zero of=/mnt/nfs_test/bench bs=$size count=200 2>&1 | \
      tail -1 | awk '{print $NF}'

    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    echo -n "  Read:  "
    dd if=/mnt/nfs_test/bench of=/dev/null bs=$size count=200 2>&1 | \
      grep -o "[0-9.]\+ MB/s" || \
      dd if=/mnt/nfs_test/bench of=/dev/null bs=$size count=200 2>&1 | \
      tail -1 | awk '{print $NF}'

    sudo rm /mnt/nfs_test/bench
    sudo umount /mnt/nfs_test
done

echo "Practice 13 complete — optimal buffer size determined"
```

---

### ✅ Practice 14: NFS Locking and Delegation Test

```bash
cd ~/linux-course/part28

# Mount for lock testing
sudo mount -t nfs4 localhost:/export/nfs/data /mnt/nfs_test

# Create a test file
echo "lock test content" | sudo tee /mnt/nfs_test/lockme.txt

# Test 1: flock exclusive lock
echo "=== Test 1: flock exclusive lock ==="
flock -x /mnt/nfs_test/lockme.txt -c "echo '  Acquired exclusive lock at $(date)'" 2>&1 || \
  echo "  flock may not be available, trying fallback"

# Test 2: Multiple concurrent locks (run in background)
echo "=== Test 2: Concurrent lock test ==="

# Create a lock helper script
cat > lock_test.sh << 'EOF'
#!/bin/bash
FILE="/mnt/nfs_test/lockme.txt"
echo "  Process $$ attempting lock on $FILE"
flock -x "$FILE" -c "
  echo \"  Process $$ acquired lock at \$(date)\"
  sleep 2
  echo \"  Process $$ releasing lock at \$(date)\"
" 2>&1
EOF

chmod +x lock_test.sh

# Run two lock processes in parallel
./lock_test.sh &
PID1=$!
./lock_test.sh &
PID2=$!
wait $PID1 $PID2

echo "=== Lock test complete ==="

# Check delegation statistics
echo "=== Delegation stats ==="
grep -E "deleg|open|close" /proc/self/mountstats | \
  grep -A5 "/mnt/nfs_test" || \
  echo "  Delegation stats available in mountstats"

sudo umount /mnt/nfs_test

echo "Practice 14 complete — NFS locking fundamentals explored"
```

---

### ✅ Practice 15: Real-World Integration — Multi-Client NFS with Autofs and Security

```bash
cd ~/linux-course/part28

# This practice simulates a real-world scenario:
#   - NFS server exports multiple directories
#   - Autofs mounts on demand
#   - Security restrictions are applied
#   - Performance is benchmarked
#   - Troubleshooting is demonstrated

echo "=== Real-World NFS Integration ==="

# ---- STEP 1: Server Setup ----
echo "[1/7] Setting up server exports..."

# Create structured exports
sudo mkdir -p /export/{homes,projects,public,backups}
sudo chmod 755 /export/homes /export/projects /export/backups
sudo chmod 777 /export/public

# Create test content
echo "Welcome to the public share" | sudo tee /export/public/README.txt
echo "Project Alpha data" | sudo tee /export/projects/alpha.txt
echo "Backup placeholder" | sudo tee /export/backups/daily.tar.gz

# Write comprehensive /etc/exports
sudo tee /etc/exports << 'EOF'
# Real-world NFS exports configuration
# Public read-only
/export/public          *(ro,all_squash,no_subtree_check)

# Internal projects (restricted subnet)
/export/projects        10.0.0.0/24(rw,root_squash,no_subtree_check)
/export/projects        192.168.1.0/24(ro,root_squash,no_subtree_check)

# Home directories (per-host access simulated)
/export/homes           127.0.0.1(rw,root_squash,no_subtree_check)

# Backups (write-only for backup server)
/export/backups         127.0.0.1(rw,root_squash,no_subtree_check)
EOF

sudo exportfs -ra
echo "  Exports active:"
showmount -e localhost

# ---- STEP 2: Autofs Configuration ----
echo "[2/7] Configuring autofs..."

# Create autofs maps
sudo tee /etc/auto.nfs_prod << 'EOF'
# Production NFS autofs map
public      -ro,hard,intr,noatime        localhost:/export/public
projects    -rw,hard,intr,noatime        localhost:/export/projects
homes       -rw,hard,intr,noatime        localhost:/export/homes
backups     -rw,hard,intr,noatime        localhost:/export/backups
EOF

# Add to auto.master (avoid duplicate entries)
grep -q "auto.nfs_prod" /etc/auto.master || \
  echo "/prod  /etc/auto.nfs_prod  --timeout=120 --ghost" | sudo tee -a /etc/auto.master

sudo systemctl restart autofs
echo "  Autofs restarted. Mount points: /prod/{public,projects,homes,backups}"

# ---- STEP 3: Test Access ----
echo "[3/7] Testing access to all exports..."

for share in public projects homes backups; do
    echo -n "  Accessing /prod/$share ... "
    timeout 5 ls /prod/$share/ > /dev/null 2>&1 && \
      echo "OK ($(ls /prod/$share/ | wc -l) items)" || \
      echo "FAIL"
done

# ---- STEP 4: Write Test ----
echo "[4/7] Testing read/write permissions..."

# Public should be read-only
echo -n "  Write to public (expect failure): "
echo "test" > /prod/public/test.txt 2>&1 && echo "FAIL (should be ro)" || echo "OK (read-only)"

# Projects should be writable
echo -n "  Write to projects: "
echo "test" | sudo tee /prod/projects/test.txt > /dev/null 2>&1 && \
  echo "OK" || echo "FAIL"

# ---- STEP 5: root_squash Verification ----
echo "[5/7] Verifying root_squash..."

sudo touch /prod/projects/root_test.txt
OWNER=$(ls -la /prod/projects/root_test.txt | awk '{print $3}')
if [ "$OWNER" = "nobody" ] || [ "$OWNER" = "nfsnobody" ]; then
    echo "  ✓ root_squash active: root file owned by $OWNER"
else
    echo "  Note: root file owned by $OWNER (root_squash may not apply locally)"
fi

# ---- STEP 6: Performance Test ----
echo "[6/7] Running performance benchmark..."

sudo mount -t nfs4 -o rw,hard,noatime localhost:/export/projects /mnt/nfs_test

echo -n "  Write speed: "
dd if=/dev/zero of=/mnt/nfs_test/perf bs=1M count=100 2>&1 | tail -1 | awk '{print $NF}'

echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

echo -n "  Read speed:  "
dd if=/mnt/nfs_test/perf of=/dev/null bs=1M count=100 2>&1 | tail -1 | awk '{print $NF}'

sudo rm /mnt/nfs_test/perf
sudo umount /mnt/nfs_test

# ---- STEP 7: Troubleshooting & Verification ----
echo "[7/7] Final verification..."

# Check all mounts
echo "  Active NFS mounts:"
mount -t nfs4,nfs 2>/dev/null | head -10

# Check exports
echo "  Current exports:"
sudo exportfs -v | head -20

# RPC health
echo "  RPC services:"
rpcinfo -p localhost 2>/dev/null | grep -E "nfs|mount|nlock|statd" | \
  awk '{printf "    %s (v%s)\n", $4, $3}'

echo ""
echo "=== Real-World Integration Complete ==="
echo "Scenario: Multi-export NFS server with autofs,"
echo "  read-only public share, restricted projects,"
echo "  root_squash security, and performance validation."
```

---

## 🧠 Deep Understanding — How NFS Really Works

### The ONC RPC Protocol

NFS is built on Open Network Computing Remote Procedure Calls (ONC RPC). Every NFS operation is an RPC call:

```
RPC Structure:
  +-----------------------+
  | RPC Header:           |
  |   xid (transaction)   |
  |   msg_type (call=0)   |
  |   rpcvers (2)         |
  |   prog (100003=NFS)   |
  |   vers (3 or 4)       |
  |   proc (LOOKUP=3)     |
  |   auth credentials    |
  |   auth verifier       |
  +-----------------------+
  | RPC Body (procedure   |
  | specific data)        |
  +-----------------------+

RPC Reply:
  +-----------------------+
  | RPC Header:           |
  |   xid (same)          |
  |   reply_stat          |
  |   accept_stat         |
  +-----------------------+
  | RPC Body (results)    |
  +-----------------------+
```

### XDR — External Data Representation

All RPC data is serialized using XDR — a binary format that handles:

- **Integer encoding**: Big-endian (network byte order)
- **Variable-length data**: Length prefix + data + padding to 4-byte boundary
- **Strings**: Length + UTF-8 data + null padding
- **Opaque data**: Raw bytes with padding

### XID — Transaction IDs

Each RPC has a unique **transaction ID (xid)** that correlates requests and responses:

```bash
# Client sends RPC with xid=0xABCD1234
# Server replies with xid=0xABCD1234
# Client matches reply to pending request

# If no reply arrives:
#   - Client retries with SAME xid
#   - Server sees duplicate xid → returns cached reply (idempotent operations)
#   - Non-idempotent operations (like MKDIR) may cause issues
#   - NFSv4.1 sessions solve this with exactly-once semantics
```

### The Portmapper (rpcbind) Protocol

For NFSv3, finding services uses the portmapper protocol:

```
Client → portmapper (port 111):
  CALL:  GETPORT(program=100005, version=3, proto=tcp)

Portmapper → Client:
  REPLY: port=40401

Client → mountd (port 40401):
  CALL:  MOUNT(path="/export/data", auth=UNIX(uid=0))

mountd → Client:
  REPLY: filehandle=0x...
```

**The portmapper maintains a table:**
```bash
# View the table
rpcinfo -p

# The table maps:
#   Program number → port
#   Version number → port
#   Protocol (TCP/UDP) → port

# Program numbers (IANA-assigned):
#   100000  portmapper (rpcbind)
#   100001  rstatd
#   100003  nfs
#   100005  mountd
#   100011  rquotad
#   100021  nlockmgr (lockd)
#   100024  statd
```

### How NFSv4 Eliminated Extra Daemons

NFSv4 is a **integrated protocol** — it replaced multiple separate protocols:

```
NFSv3:                   NFSv4:
  rpcbind                  [single port 2049]
  nfsd ─── port 2049       nfsd ─── port 2049 (compound RPCs)
  mountd ─── random port    │
  statd ─── random port      └── Everything is one protocol:
  lockd ─── random port          MOUNT (part of NFSv4)
  rquotad ─── random port        LOCK (part of NFSv4)
                                  STAT (part of NFSv4)
                                  ACL (part of NFSv4)
```

**NFSv4 compound RPCs** merge multiple operations:

```bash
# NFSv3 would need:
#   1. PORTMAP GETPORT(mountd)   → port 38429
#   2. MOUNT("/export/data")     → fh1
#   3. LOOKUP(fh1, "file.txt")   → fh2
#   4. OPEN(fh2, RDONLY)         → stateid
#   5. READ(stateid, 0, 4096)    → data
#   6. CLOSE(stateid)
#   7. PORTMAP GETPORT(statd)    → port 43987
#   8. LOCK(fh2, WRITE, ...)     (etc)

# NFSv4 sends ONE compound:
#   PUTFH(fh_root)
#   LOOKUP("export/data")
#   LOOKUP("file.txt")
#   OPEN(RDONLY)
#   READ(0, 4096)
#   CLOSE
# All in a SINGLE RPC call on port 2049
```

This is why NFSv4 is dramatically more efficient for metadata operations — one RTT instead of many.

### The Filehandle

The **filehandle** is the fundamental identifier in NFS — it's the server's internal reference to a file or directory:

```
NFSv3 filehandle (32 bytes):
  +------+------+------+------+
  | fsid | inode| gen  | pad  |
  +------+------+------+------+

  - fsid:  filesystem identifier
  - inode: inode number on disk
  - gen:   generation counter (changes on file deletion/recreation)

NFSv4 filehandle (variable, up to 128 bytes):
  +------+------+------+------+--------+
  | fsid | inode| gen  | type  | domain |
  +------+------+------+------+--------+

  - type: file, dir, symlink, etc.
  - domain: auth domain for NFSv4

```

**The filehandle is opaque to the client** — the client cannot interpret its contents. It just stores and presents the filehandle in subsequent RPCs.

### How close-to-open Consistency Works

NFSv3 provides **close-to-open consistency** — the most important behavioral guarantee:

```
Client A:
  1. OPEN("/file.txt")
  2. READ → caches data in page cache
  3. (no server contact for subsequent reads)
  4. WRITE → caches in page cache
  5. CLOSE → flushes ALL cached writes to server
            → sends GETATTR to verify timestamps

Client B (after Client A's close):
  1. OPEN("/file.txt")
     → Server has latest data
     → GETATTR returns fresh attributes
  2. Client B sees Client A's changes

The guarantee: after close(), subsequent open() by ANY client
sees the latest data — because close() flushed everything.
```

**Without CLOSE, there is NO guarantee:**

```
Client A opens file but never closes:
  - Writes stay in Client A's page cache
  - No flush has occurred
  - Client B sees old data
  - If Client A crashes: data loss
```

**This is why NFSv3 has no server-side byte-range locking guarantee** — there is no mandatory byte-range lock protocol in the NFS protocol itself. Separate lockd handles that.

### NFSv4 Delegations — Beyond close-to-open

NFSv4 adds **delegations** for better performance:

```
READ delegation:
  Server says: "Nobody else is writing this file — cache freely"
  Client benefits:
    - No GETATTR on every open
    - No close-to-open check
  Server can RECALL delegation when another client writes:
    Client A ← DELEGRECALL ← Server ← OPEN(write) ← Client B
    Client A flushes dirty pages → returns delegation

WRITE delegation:
  Server says: "You're the only writer — buffer locally"
  Client benefits:
    - No flush on every close
    - Local caching without server round trips
  Server recalls on conflict.

Delegation types:
  - READ delegation (any number of clients)
  - WRITE delegation (single client, exclusive)
  - No delegation (default for NFSv3 behavior)
```

### Attribute Caching

NFS clients cache file attributes (size, mtime, permissions) with a **timeout**:

```bash
# Kernel-side attribute cache parameters:
#   acregmin  = minimum attribute cache time for regular files (default 3s)
#   acregmax  = maximum attribute cache time for regular files (default 60s)
#   acdirmin  = minimum attribute cache time for directories (default 30s)
#   acdirmax  = maximum attribute cache time for directories (default 60s)

# Mount with noac to disable attribute caching entirely:
sudo mount -t nfs4 -o noac localhost:/export/nfs/data /mnt/nfs_test
# WARNING: Very slow — every stat() goes to the server
```

**The attribute cache state machine:**
```
1. Client caches attrs with timestamp
2. Time passes...
3. If cache is "young" (< acregmin): use cached (no RPC)
4. If cache is "medium" (acregmin - acregmax): check GETATTR (one RPC)
5. If cache is "expired" (> acregmax): treat as stale, GETATTR on next access
6. If another client modified → no notification in NFSv3
   NFSv4: delegations handle this better
```

### The Linux VFS-NFS Integration

The Linux Virtual File System (VFS) translates every POSIX call into NFS operations:

```
User: ls -l /mnt/nfs/file.txt
       |
POSIX calls:
  stat("/mnt/nfs/file.txt")
       |
VFS layer:
  Finds nfs4_file_inode_operations
       |
NFS client (kernel):
  nfs_getattr() → nfs4_proc_getattr()
       |
RPC layer (sunrpc):
  Encodes: PUTFH + GETATTR compound
  Sends to server:2049
       |
Network
       |
Server:
  nfsd_decode_args()
  nfsd_getattr()
  nfsd_encode_result()
       |
Reply
```

### NFS and the Page Cache

NFS integrates with the Linux page cache in a special way:

```bash
# Dirty pages on NFS are tracked differently than local filesystems
# NFS writes go through:
#   1. Page cache write (fast, local)
#   2. VM flushes dirty pages to NFS server (pdflush/flusher threads)
#   3. Server commits to disk (if sync export)

# Key difference from local filesystem:
#   - NFS write-back cache is time-based (not page-count-based)
#   - Default commit interval: ~5 seconds (or on close())
#   - sync/fsync forces immediate commit to server

# Check NFS writeback statistics
cat /proc/self/mountstats | grep -A5 "nfs"
```

### The RPC Layer: sunrpc

The Linux kernel's RPC implementation (`sunrpc.ko`) handles all NFS transport:

```
sunrpc layer components:
  - rpc_clnt: RPC client handle (per mount)
  - rpc_task: individual RPC operation
  - rpc_xprt: transport (TCP socket, RDMA, etc.)
  - rpc_wait_queue: request ordering

Flow:
  1. NFS operation → rpc_task created
  2. Task added to xprt's queue
  3. xprt sends RPC over TCP
  4. Reply received → task completed
  5. Callback to NFS layer with results

Transport states:
  - connected: TCP established
  - connecting: TCP handshake in progress
  - close_wait: TCP disconnection detected
  - bound: bound to port (after rpcbind)
```

### NFSv4 Lease and State Model

NFSv4 state management is lease-based:

```
Timeline:
  t=0:  Client opens file → server creates state (lease: 90s)
  t=10: Client reads
  t=20: Client writes
  t=30: Client renews lease (via RENEW or any operation)
  t=40: Client gets lock
  t=90: Deadline of original lease, but RENEW at t=30 extends it
  t=120: Client crashes (no more RENEW)
  t=210: Lease expires (120 + 90 = 210)
         Server revokes ALL state for this client:
           - Closes open files
           - Releases locks
           - Recalls delegations
  t=211: Client B can now lock the file that Client A had locked
```

**Lease types:**
```
open_owners: who has files open?
lock_owners: who holds locks?
delegations: who has delegated control?

Each has a stateid, and each stateid expires with the lease.
```

### NFSv4.1 Sessions — Solving Exactly-Once Semantics

Before sessions, NFSv4 had a problem with **non-idempotent operations**:

```
Problem (NFSv4.0):
  Client sends: CREATE(file)
  Server creates file, sends reply
  Reply LOST on network
  Client retries: CREATE(file)  ← which one is this?
  Server: "file already exists" → NFS4ERR_EXIST
  Client: "did my create succeed or not?" → AMBIGUOUS

Solution (NFSv4.1 sessions):
  1. Client creates a session with N slot table entries
  2. Each RPC gets a slot + sequence ID
  3. Server tracks: "I've seen slot 3, seq 5 — it was a CREATE, it succeeded"
  4. Reply cached in slot
  5. Client retries slot 3, seq 5 → server returns CACHED reply
  6. Client knows: "create succeeded!"

Session slot table:
  +-------+------+-----------+----------+
  | Slot  | Seq  | Operation | Cached?  |
  +-------+------+-----------+----------+
  | 0     | 42   | READ      | no (done)|
  | 1     | 7    | OPEN      | yes      |
  | 2     | 19   | WRITE     | no (done)|
  | 3     | 5    | CREATE    | yes      | ← reply cached for retransmit
  +-------+------+-----------+----------+
```

### What Happens During NFS Server Crash and Recovery

```
Server crash timeline:
  t=0: Server running
  t=10: Server crashes
         Clients see: "RPC: timed out" (TCP retransmits)
         Clients keep retrying with increasing intervals
  t=15: Server comes back
         nfsd starts, new boot verifier
  t=16: Client X sends: READ(fh, stateid)
         Server: "Unknown stateid" → NFS4ERR_STALE_STATEID
  t=17: Client X: OPEN file → new stateid → re-read
  t=20: All clients have re-established state

NFSv3 recovery (simpler, stateless):
  t=10: Server crashes
         Clients retry: READ(fh) — no stateid needed
  t=15: Server comes back
         Client X retries: READ(fh) ← it just works!
         (Server doesn't track anything — filehandle is enough)
         Only locks need recovery (via statd/lockd)
```

---

## 📋 Summary — Complete Command Reference for Part 28

### ⭐ Level 1 Commands: Basic NFS Operations

| Command | Action |
|---------|--------|
| `systemctl start nfs-server` | Start NFS server |
| `systemctl enable --now nfs-server` | Enable and start NFS server |
| `systemctl status nfs-server` | Check NFS server status |
| `rpcinfo -p HOST` | Show all RPC registrations |
| `showmount -e HOST` | Show exported directories |

### ⭐ Level 2 Commands: Server, Client, Autofs, and Troubleshooting

**Server Administration**

| Command | Action |
|---------|--------|
| `exportfs -ra` | Re-export all directories from /etc/exports |
| `exportfs -v` | Show current exports |
| `exportfs -ua` | Unexport everything |
| `exportfs -o OPTIONS CLIENT:DIR` | Export without editing /etc/exports |
| `showmount -a HOST` | Show connected clients |

**Client Mounting**

| Command | Action |
|---------|--------|
| `mount -t nfs4 SERVER:PATH /mnt` | Mount NFSv4 share |
| `mount -t nfs -o vers=3 SERVER:PATH /mnt` | Mount NFSv3 share |
| `mount -t nfs4 -o sec=krb5p SERVER:PATH /mnt` | Mount with Kerberos |
| `umount /mnt` | Unmount NFS share |
| `umount -f /mnt` | Force unmount (stale handle) |

**Autofs**

| Command | Action |
|---------|--------|
| `systemctl start autofs` | Start autofs |
| `systemctl restart autofs` | Restart after config change |
| `automount --status` | Show autofs status |
| `automount -f -v` | Run autofs in foreground (debug) |

**Key Files**

| File | Purpose |
|------|---------|
| `/etc/exports` | NFS server export configuration |
| `/etc/fstab` | Mount at boot (NFS entries) |
| `/etc/auto.master` | Autofs master map |
| `/etc/idmapd.conf` | NFSv4 ID mapping configuration |

### ⭐ Level 3 Commands: Performance Tuning and Deep Diagnostics

| Command | Action |
|---------|--------|
| `mount -t nfs4 -o rdma,port=20049 SERVER:PATH /mnt` | Mount with RDMA |
| `nfsstat -c` | Client NFS statistics |
| `nfsstat -s` | Server NFS statistics |
| `nfsstat -4` | NFSv4-specific statistics |
| `nfsstat -r` | RPC statistics |
| `cat /proc/self/mountstats` | Per-mount detailed statistics |
| `cat /proc/fs/nfsd/exports` | Kernel export table |
| `cat /proc/fs/nfsd/threads` | Number of nfsd threads |
| `cat /proc/fs/nfsd/lease_time` | Lease duration in seconds |
| `rpcinfo -t HOST PROG VERS` | Test specific RPC program |
| `strace -e trace=open,read,write,stat find /mnt/nfs ...` | Trace NFS syscalls |

| File | Purpose |
|------|---------|
| `/etc/krb5.conf` | Kerberos configuration |
| `/etc/nfs.conf` | NFS daemon configuration |
| `/proc/fs/nfsd/` | Kernel NFS server interface |
| `/proc/self/mountstats` | Per-mount client statistics |

---

## 🚀 What's Coming in Part 29

**Part 29: Samba and Windows Interop**

You will learn:
- Samba architecture — smbd, nmbd, winbindd
- Sharing Linux directories with Windows clients (CIFS/SMB)
- Joining a Linux machine to an Active Directory domain
- Configuring domain authentication with SSSD + Winbind
- File sharing permissions and ACL mapping
- Troubleshooting Samba with smbstatus, testparm, log level
- Printer sharing via Samba
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the three core technologies that NFS is built on?
2. What is the fundamental difference between NFSv3 (stateless) and NFSv4 (stateful) regarding server crash recovery?
3. What does `exportfs -ra` do and when would you run it?
4. What is the difference between `root_squash` and `no_root_squash` in /etc/exports?
5. Why would you choose a soft mount over a hard mount? What is the risk?
6. How does NFSv4 eliminate the need for separate mountd, statd, and lockd daemons?
7. What is the NFSv4 pseudo-filesystem and how is it configured?
8. What does the `&` symbol mean in an autofs map file?
9. How does close-to-open consistency work in NFSv3?
10. What is the difference between `sec=krb5`, `sec=krb5i`, and `sec=krb5p`?
11. What information does `rpcinfo -p` show, and why is it important for NFSv3 troubleshooting?
12. What do high `retrans` values in `nfsstat -c` indicate?
13. How does pNFS improve NFS performance by separating metadata and data paths?
14. What is an NFSv4 delegation and what happens when the server recalls it?
15. How do NFSv4.1 sessions solve the non-idempotent operation ambiguity problem?

**Score:** 12/15 correct = ready for Part 29.

---

*Linux SysAdmin Course | Part 28 of ∞ | Reverse Engineering Approach*
*Previous → Part 27: DNS and Name Resolution*
*Next → Part 29: Samba and Windows Interop*

[← Previous](part27.md) | [Next →](part29.md)
