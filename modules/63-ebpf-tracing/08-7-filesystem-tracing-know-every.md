## 7. Filesystem Tracing — Know Every I/O Operation

```bash
# Trace ext4 operations slower than 10ms
sudo ext4slower-bpfcc 10
# COMM       PID    T  BYTES   LAT(ms) FILENAME
# mysqld     1234   R  4096    23.45   users.ibd

# Trace XFS operations slower than 5ms
sudo xfsslower-bpfcc 5

# Which files are being read/written
sudo filetop-bpfcc
# TIME     COMM      T FILE        BYTES   READS  WRITES
# 10:23:01 mysqld    R users.ibd   1048576  256    0

# VFS operation counts
sudo vfsstat-bpfcc
# READ    WRITE   FSYNC   OPEN    CLOSE
# 12345   6789    234     567     567

# Trace fsync with latency
bpftrace -e '
kprobe:vfs_fsync_range { @start[tid] = nsecs; }
kretprobe:vfs_fsync_range /@start[tid]/ {
    $ms = (nsecs - @start[tid]) / 1000000;
    if ($ms > 10) printf("%s pid=%d latency=%d ms\n", comm, pid, $ms);
    delete(@start[tid]);
}'
```

> 🔍 **Reverse Engineering Insight:** When a database is "slow," the answer is almost always in the I/O path. ext4slower/xfsslower instantly show WHICH files are slow and by HOW MUCH — something `iostat` and `iotop` cannot tell you.





[← Previous](07-6-network-tracing-packets-connections.md) | [↑ Index](index.md) | [Next →](09-8-real-world-debugging-scenarios.md)
