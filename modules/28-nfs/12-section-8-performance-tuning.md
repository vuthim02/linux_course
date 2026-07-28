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





[← Previous](11-section-7-security.md) | [↑ Index](index.md) | [Next →](13-section-9-troubleshooting.md)
