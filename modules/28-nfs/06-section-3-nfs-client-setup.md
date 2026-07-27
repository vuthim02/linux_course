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



---

[← Previous](05-section-2-nfs-server-setup.md) | [↑ Index](index.md) | [Next →](07-section-4-nfsv4-features.md)
