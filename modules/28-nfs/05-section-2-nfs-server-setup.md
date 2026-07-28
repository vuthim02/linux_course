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





[← Previous](04-level-2-intermediary-nfs-server.md) | [↑ Index](index.md) | [Next →](06-section-3-nfs-client-setup.md)
