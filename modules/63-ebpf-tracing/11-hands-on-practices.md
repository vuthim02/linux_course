## 🛠️ Hands-On Practices

### Practice 1: Install and Verify Tracing Tools

```bash
# Install all tracing tools
sudo apt install bpfcc-tools bpftrace linux-tools-common linux-tools-$(uname -r)

# Verify installations
bpftrace --version
perf --version

# Check kernel eBPF support — all should show =y or =m
grep -E "CONFIG_BPF|CONFIG_BPF_SYSCALL|CONFIG_BPF_JIT|CONFIG_BPF_EVENTS" \
    /boot/config-$(uname -r)

# Count available bcc-tools
ls /usr/sbin/*-bpfcc | wc -l

# List current eBPF programs loaded on the system
sudo bpftool prog list | head -10
```

✅ **Expected**: All tools installed, kernel supports eBPF, bpftool shows existing programs

### Practice 2: execsnoop — Catch Every New Process

```bash
# Terminal 1: Start tracing
sudo execsnoop-bpfcc

# Terminal 2: Generate activity
sleep 1 &
ls /tmp &
python3 -c "print('hello')" &
for i in {1..5}; do sleep 0.1 & done

# Wait, then Ctrl+C in Terminal 1
```

✅ **Expected**: See all spawned processes with PID, PPID, and full command line

### Practice 3: opensnoop — Track File Access

```bash
# Start tracing file opens
sudo opensnoop-bpfcc

# In another terminal
cat /etc/hostname
python3 -c "open('/etc/hosts').read()"

# Filter by process name
sudo opensnoop-bpfcc -n python3

# Filter by path (find who reads a specific file)
sudo opensnoop-bpfcc -f /etc/shadow
```

✅ **Expected**: Every file open syscall with process name, PID, path, and error codes

### Practice 4: biolatency — Disk I/O Latency Profile

```bash
# Generate I/O
fio --name=test --directory=/tmp --rw=randread --bs=4k --size=100M --runtime=10 &
# Measure
sudo biolatency-bpfcc -D 10
```

✅ **Expected**: Latency histogram showing I/O distribution across devices

### Practice 5: bpftrace One-Liners

```bash
# Count syscalls per process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s opens %s\n", comm, str(args->filename)); }'

# Measure function latency
bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; } kretprobe:vfs_read /@start[tid]/ { @us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'
```

✅ **Expected**: Kernel visibility output showing syscall counts and file access patterns

### Practice 6: perf stat — Hardware Counter Analysis

```bash
perf stat sort -n /usr/share/dict/words > /dev/null
perf stat grep -c "the" /usr/share/dict/words
perf stat dd if=/dev/zero of=/dev/null bs=4k count=10000
```

✅ **Expected**: Hardware counter differences between CPU-bound, I/O-bound, and memory-bound workloads

### Practice 7: perf record + Flame Graph

```bash
git clone https://github.com/brendangregg/FlameGraph /tmp/FlameGraph
export PATH=$PATH:/tmp/FlameGraph
sudo perf record -a -g -F 99 -- sleep 10
sudo perf script | stackcollapse-perf.pl | flamegraph.pl > /tmp/flamegraph.svg
```

✅ **Expected**: Flame graph SVG showing CPU time distribution across call stacks

### Practice 8: strace Deep Dive

```bash
# Find what a process accesses
strace -e trace=file -f curl http://localhost 2>&1 | head -20

# Syscall summary
sudo timeout 10 strace -c -f -p $(pgrep nginx) 2>&1

# Find permission issues
strace -e trace=file command 2>&1 | grep EACCES
```

✅ **Expected**: Syscall tracing with timing, file access, and error details

### Practice 9: Network Tracing

```bash
sudo tcpretrans-bpfcc &
for i in {1..50}; do curl -s http://localhost > /dev/null 2>&1 &; done
wait; kill %1

sudo tcplife-bpfcc &
for i in {1..10}; do curl -s http://example.com > /dev/null 2>&1 &; done
wait; kill %1
```

✅ **Expected**: TCP retransmit events and connection lifetimes with byte counts

### Practice 10: Filesystem Tracing

```bash
sudo ext4slower-bpfcc 5 &
dd if=/dev/zero of=/tmp/slowfile bs=1M count=100 oflag=direct
cat /tmp/slowfile > /dev/null
sudo vfsstat-bpfcc &
ls /var/log/ && cat /etc/hosts
kill %1 %2 2>/dev/null
```

✅ **Expected**: Slow I/O events with filenames, latencies, and VFS operation counts

### Practice 11: bpftrace Script — Zombie Detector

```bash
cat > /tmp/zombies.bt << 'EOF'
#!/usr/bin/env bpftrace
tracepoint:sched:sched_process_exit /args->exit_state == 32/ {
    printf("ZOMBIE: PID=%d COMM=%s\n", pid, comm);
}
interval:s:5 { printf("--- check ---\n"); }
EOF
sudo bpftrace /tmp/zombies.bt
```

✅ **Expected**: Script detects zombie process creation events

### Practice 12: perf top — Live Function Profiling

```bash
sudo perf top -g &
# Let it run while you do work in other terminals
kill %1
```

✅ **Expected**: Live view of kernel and userspace functions consuming CPU

### Practice 13: Cache Miss Investigation

```bash
perf stat -e cache-references,cache-misses -r 3 python3 -c "
data = list(range(1000000))
sum(data[i] for i in range(0, len(data), 64))
"
```

✅ **Expected**: Sequential access shows low cache miss rate vs random access

### Practice 14: End-to-End Production Debugging

```bash
cat > /tmp/slow_app.py << 'PYEOF'
import os, time, random
while True:
    with open("/tmp/app_log.txt", "a") as f:
        f.write(f"entry {time.time()}\n")
    if random.random() < 0.1:
        os.system("dd if=/dev/zero of=/tmp/app_data bs=4K count=10 oflag=direct 2>/dev/null")
    time.sleep(0.01)
PYEOF
python3 /tmp/slow_app.py &
APP_PID=$!

sudo execsnoop-bpfcc &
sudo opensnoop-bpfcc -p $APP_PID &
perf stat -p $APP_PID -- sleep 3
sudo biolatency-bpfcc -D 3

kill $APP_PID 2>/dev/null
pkill -f "execsnoop\|opensnoop\|biolatency" 2>/dev/null
rm -f /tmp/app_log.txt /tmp/app_data /tmp/slow_app.py
```

✅ **Expected**: Complete investigation using multiple tools to understand the slow application

### Practice 15: Custom bpftrace Dashboard

```bash
cat > /tmp/dashboard.bt << 'EOF'
#!/usr/bin/env bpftrace
BEGIN { printf("=== System Tracing Dashboard ===\n"); }
tracepoint:raw_syscalls:sys_enter { @syscalls[comm] = count(); }
tracepoint:block:block_rq_complete { @disk[comm] = count(); }
tracepoint:sched:sched_process_exec {
    printf("[%s] New: %s (PID %d)\n", strftime("%H:%M:%S", nsecs), args->filename, pid);
}
interval:s:5 {
    printf("\n--- Syscalls ---\n"); print(@syscalls, 10);
    printf("\n--- Disk Ops ---\n"); print(@disk, 5);
    clear(@syscalls); clear(@disk);
}
EOF
sudo bpftrace /tmp/dashboard.bt
```

✅ **Expected**: Multi-probe dashboard showing syscalls, disk ops, and new processes





[← Previous](10-9-when-to-use-which.md) | [↑ Index](index.md) | [Next →](12-deep-understanding.md)
