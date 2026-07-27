## 4. strace Deep Dive — The Syscall Detective

### Filtering and Focus

```bash
# Trace only specific syscalls
strace -e trace=open,openat,read,write,close nginx

# Trace only network calls
strace -e trace=network curl https://example.com

# Trace only errors
strace -ef trace=open,openat command

# Exclude noisy syscalls
strace -e trace=!futex,!mmap,!mprotect,!brk command

# Show file descriptor paths
strace -y command
# openat(AT_FDCWD, "/etc/hosts", O_RDONLY) = 3</etc/hosts>
```

### Following Children and Timing

```bash
# Follow child processes (essential for forking daemons)
strace -f -T nginx
# [pid 1234] futex(..., FUTEX_WAIT_PRIVATE, ...) = 0 <0.000234>
# [pid 1235] epoll_wait(3, ...)                = 1 <0.001234>

# Summary with timing per syscall
strace -c -f command
# % time     seconds  usecs/call     calls    errors syscall
# ------ ----------- ----------- --------- --------- --------
#  45.00    0.002340         234        10           read
#  30.00    0.001560         156        10           write

# Absolute timestamps
strace -tt command
# 14:23:01.123456 execve("/bin/ls", ["ls"], ...) = 0

# Microsecond timing per syscall
strace -T command
# read(3, "\177ELF...", 832) = 832 <0.000045>
```

### Practical strace Recipes

```bash
# Find the slow syscall
strace -T command 2>&1 | sort -t'<' -k2 -rn | head -10

# What files does a program look for?
strace -e trace=file -f command 2>&1 | grep "no such file"

# What network connections does it make?
strace -e trace=connect,sendto,recvfrom -f command

# Find permission denied issues
strace -ef trace=file,connect command 2>&1 | grep EACCES

# Count total I/O bytes
strace -e trace=read,write -c command 2>&1

# Redirect to files (essential for long traces)
strace -o trace.log -ff -f command   # Creates trace.log.<pid> files
```

> 🔍 **Reverse Engineering Insight:** strace uses ptrace, causing 10-100x overhead — **3 context switches per syscall**. Use it for debugging, never in production for extended periods. For production, use bpftrace or perf.

⚠️ **Warning:** `strace -p <pid>` on a production process causes noticeable latency spikes. Use with time limits.

---



---

[← Previous](04-3-bpftrace-the-tracing-power.md) | [↑ Index](index.md) | [Next →](06-5-perf-the-profiling-powerhouse.md)
