## 🔍 Section 10: SystemTap and bpftrace

### bpftrace — Dynamic Tracing

`bpftrace` is a high-level tracing language for Linux eBPF. It can probe kernel functions, user-space functions, tracepoints, and hardware events.

**Installation:**

```bash
# Ubuntu/Debian
sudo apt install bpftrace

# RHEL/CentOS 8+
sudo dnf install bpftrace
```

**One-liners:**

```bash
# New processes with arguments
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s\n", str(args->filename)); }'

# Files opened per second
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); }'

# Block I/O latency histogram
bpftrace -e 'kprobe:blk_account_io_done { @usecs = hist(nsecs / 1000); }'

# Read distribution for a process
bpftrace -e 'tracepoint:syscalls:sys_exit_read /pid == 1234/ { @bytes = hist(args->ret); }'

# Disk I/O size distribution
bpftrace -e 'tracepoint:block:block_rq_issue { @bytes = hist(args->bytes); }'

# TCP connect by process
bpftrace -e 'kprobe:tcp_connect { @[comm] = count(); }'

# Count syscalls by process
bpftrace -e 'tracepoint:syscalls:sys_enter_read { @[comm] = count(); }'
```

**Latency histogram for block I/O:**

```bash
sudo bpftrace -e 'kprobe:blk_account_io_start { @start[tid] = nsecs; }
    kprobe:blk_account_io_done /@start[tid]/ {
        @usecs = hist((nsecs - @start[tid]) / 1000);
        delete(@start[tid]);
    }'
```

**Latency histogram for syscalls:**

```bash
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_read { @start[tid] = nsecs; }
    tracepoint:syscalls:sys_exit_read /@start[tid]/ {
        @usecs = hist((nsecs - @start[tid]) / 1000);
        delete(@start[tid]);
    }'
```

### SystemTap

SystemTap is an older tracing framework that compiles probe scripts into kernel modules:

```bash
# Install
sudo apt install systemtap systemtap-runtime

# Hello world probe
sudo stap -e 'probe begin { printf("Hello from SystemTap\n"); exit(); }'

# Count syscalls per process
sudo stap -e 'global c; probe syscall.read { c[pid(), execname()]++ }
    probe timer.s(10) { foreach([pid, name] in c) printf("%d %s %d\n", pid, name, c[pid, name]); exit() }'

# I/O latency histogram
sudo stap -e 'global iotime; probe ioblock.request { iotime[tid()] = gettimeofday_us() }
    probe ioblock.end { t = iotime[tid()]; if (t) { latency = gettimeofday_us() - t;
    printf("%d\n", latency); delete iotime[tid()]; } }'
```

**bpftrace vs SystemTap:**

| Feature | bpftrace | SystemTap |
|---------|----------|-----------|
| Kernel requirement | 4.9+ (BPF), 5.x+ recommended | Any (compiles module) |
| Safety | Safe by default (eBPF verifier) | Can crash kernel if misused |
| Overhead | Very low | Low to moderate |
| Ease of use | One-liners, simple syntax | More complex |
| Distribution | Limited (needs BTF or debuginfo) | Needs kernel debuginfo |

---



---

[← Previous](11-section-9-strace-and-ltrace.md) | [↑ Index](index.md) | [Next →](13-section-11-benchmarking.md)
