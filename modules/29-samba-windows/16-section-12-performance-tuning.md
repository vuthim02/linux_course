## 🔍 Section 12: Performance Tuning

### Socket Options

```ini
[global]
   # TCP socket tuning
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_KEEPALIVE
   # TCP_NODELAY     — Disable Nagle's algorithm (send small packets immediately)
   # IPTOS_LOWDELAY  — Minimize delay (for interactive traffic)
   # SO_KEEPALIVE    — Detect dead connections

   # For high-throughput (bulk transfers)
   socket options = TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072
```

### Read/Write Size Tuning

```ini
[global]
   # Larger buffers = better throughput for large files
   read raw = yes               # Enable SMB read raw (large reads)
   write raw = yes              # Enable SMB write raw (large writes)

   # Read size limits
   min receivefile size = 16384 # Minimum size for sendfile path
   strict allocate = no         # Don't pre-allocate space (faster writes)
   use mmap = yes               # Use mmap for file I/O (if available)

   # Write cache
   write cache size = 262144    # Write cache per file (256KB)
```

### SMB3 Multichannel Configuration

```ini
[global]
   # Enable multichannel (SMB3)
   server multi channel support = yes

   # Optional: bind to specific interfaces
   interfaces = eth0 eth1 10.0.0.0/24
   bind interfaces only = yes
```

### Other Performance Settings

```ini
[global]
   # Number of smbd processes pre-forked
   max smbd processes = 100

   # Dead client detection
   deadtime = 15               # Disconnect idle connections after 15 min

   # Large directory optimization
   getwd cache = yes           # Cache current working directory
   directory name cache size = 100

   # Async I/O
   aio read size = 4096        # Async read for files > 4KB
   aio write size = 4096       # Async write for files > 4KB
   aio max threads = 100       # Max async I/O threads
```

### Benchmarking Samba Performance

```bash
# 1. Using smbclient with tar
time smbclient //server/share -U user%pass -c 'tar c .' > /dev/null

# 2. Using dd over CIFS mount
mount -t cifs //server/share /mnt/test -o ...
time dd if=/dev/zero of=/mnt/test/testfile bs=1M count=1000

# 3. Using iperf3 for network baseline
iperf3 -c 192.168.1.100

# 4. Check SMB version in use
smbstatus | grep -E "SMB|protocol"
```

---



---

[← Previous](15-section-11-security-hardening-samba.md) | [↑ Index](index.md) | [Next →](17-practice-section-15-hands-on-exercises.md)
