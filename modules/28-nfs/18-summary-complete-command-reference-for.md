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



---

[← Previous](17-deep-understanding-how-nfs-really.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-29.md)
