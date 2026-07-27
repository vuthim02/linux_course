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



---

[← Previous](12-section-8-performance-tuning.md) | [↑ Index](index.md) | [Next →](14-section-10-nfs-vs-other.md)
