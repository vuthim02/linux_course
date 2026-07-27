## 8. Real-World Debugging Scenarios

### Scenario 1: "The Server Is Slow" — Systematic Approach

```bash
# 1. Is it CPU, memory, I/O, or network?
uptime && vmstat 1 5 && iostat -xz 1 5

# 2. If CPU-bound → who's consuming?
sudo perf record -a -g -F 99 -- sleep 10 && sudo perf report --stdio | head -20

# 3. If I/O-bound → what's slow?
sudo biolatency-bpfcc -D && sudo ext4slower-bpfcc 10 && sudo filetop-bpfcc

# 4. If network-bound → what's happening?
sudo tcpretrans-bpfcc && sudo tcplife-bpfcc

# 5. If memory-bound → what's using it?
sudo cachestat-bpfcc 1 && sudo oomkill-bpfcc
```

### Scenario 2: Slow Disk I/O

```bash
sudo biolatency-bpfcc -D          # Overall I/O latency
sudo ext4slower-bpfcc 5           # Which files are slow
sudo biosnoop-bpfcc               # Per-I/O events
sudo cachestat-bpfcc 1            # Page cache effectiveness
# Low cache hit rate → need more RAM
# One slow file → fragmented or bad block
# High disk util → disk at capacity
```

### Scenario 3: Memory Leak Detection

```bash
sudo memleak-bpfcc -p $(pgrep myapp) -a
sudo perf record -e page-faults -a -g -F 99 -- sleep 30
sudo perf report
```

### Scenario 4: CPU Spike Investigation

```bash
top -b -d 1 | head -30                    # Who during spike
sudo perf record -a -g -F 99 -- sleep 30  # Profile it
sudo runqlat-bpfcc                         # Scheduling latency
```

### Scenario 5: Network Connection Issues

```bash
sudo tcpretrans-bpfcc              # Retransmits
sudo tcplife-bpfcc                 # Connection patterns
ss -ant | awk '{print $1}' | sort | uniq -c | sort -rn  # State counts

# Deep dive: DNS resolution issues
sudo gethostlatency-bpfcc

# Connection leak (too many TIME_WAIT)
ss -ant | awk '{print $1}' | sort | uniq -c | sort -rn
# If TIME_WAIT count is very high, check:
# - net.ipv4.tcp_tw_reuse
# - Connection pool sizing
# - Keep-alive configuration
```

### Scenario 6: Debugging a Hanging Process

```bash
# Process seems stuck — what's it doing?
PID=$(pgrep stuck_process)

# Option 1: perf top on the process
sudo perf top -p $PID

# Option 2: bpftrace — what syscall is it blocked in?
bpftrace -e '
tracepoint:raw_syscalls:sys_enter /pid == '$PID'/ {
    printf("%s syscall=%d args=%d %d %d\n", comm, args->id, args->args[0], args->args[1], args->args[2]);
}'

# Option 3: strace (use with caution on production)
sudo timeout 5 strace -p $PID -T

# Option 4: Check stack trace
cat /proc/$PID/stack

# Option 5: perf record for 3 seconds
sudo perf record -p $PID -g --call-graph dwarf -- sleep 3
sudo perf report --stdio | head -20
```

### Scenario 7: Container Performance Debugging

```bash
# Find the container's PID
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' my_container)

# Profile the container
sudo perf record -p $CONTAINER_PID -g -F 99 -- sleep 10
sudo perf report

# Trace syscalls inside container
sudo strace -p $CONTAINER_PID -c -T

# bcc-tools work on containerized processes too
sudo execsnoop-bpfcc    # Shows container processes by name
sudo opensnoop-bpfcc    # Shows file access inside containers
sudo biolatency-bpfcc   # Shows container I/O latency
```

---



---

[← Previous](08-7-filesystem-tracing-know-every.md) | [↑ Index](index.md) | [Next →](10-9-when-to-use-which.md)
