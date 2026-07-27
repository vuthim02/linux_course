## 3. bpftrace — The Tracing Power Tool

### Installation

```bash
sudo apt install bpftrace       # Debian/Ubuntu
sudo dnf install bpftrace       # RHEL/Fedora
bpftrace --version
```

### One-Liners — Instant Answers

```bash
# Count syscalls by process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-16s %-6d %s\n", comm, pid, str(args->filename)); }'

# Measure VFS read latency
bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; } kretprobe:vfs_read /@start[tid]/ { @us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'

# Count signals sent per process
bpftrace -e 'tracepoint:signal:signal_generate { @[comm, args->sig] = count(); }'

# Monitor OOM kills
bpftrace -e 'kprobe:oom_kill_process { printf("OOM KILL: %s (PID %d)\n", comm, pid); }'

# CPU profiling (100 Hz sampling)
bpftrace -e 'profile:hz:100 { @[kstack] = count(); }'

# Page faults per process
bpftrace -e 'software:page-faults:1000000 { @[comm] = count(); }'
```

### Writing bpftrace Scripts

```bash
#!/usr/bin/env bpftrace
/* slowio.bt — Find slow I/O operations (> 10ms) */

tracepoint:block:block_rq_issue {
    @start[args->dev, args->sector] = nsecs;
}

tracepoint:block:block_rq_complete /@start[args->dev, args->sector]/ {
    $latency_us = (nsecs - @start[args->dev, args->sector]) / 1000;
    if ($latency_us > 10000) {
        printf("%-8d %-16s %d usecs %s\n", pid, comm, $latency_us, args->rwbs);
    }
    delete(@start[args->dev, args->sector]);
}
```

### Probe Types

```bash
# tracepoint: stable kernel tracing points (recommended for production)
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s -> %s\n", comm, str(args->filename)); }'

# kprobe: kernel function entry (dynamic, use when no tracepoint exists)
bpftrace -e 'kprobe:tcp_connect { printf("tcp_connect by %s\n", comm); }'

# kretprobe: kernel function return
bpftrace -e 'kretprobe:tcp_connect { printf("returned %d\n", retval); }'

# uprobe: userspace function entry
bpftrace -e 'uprobe:/usr/bin/bash:readline { printf("bash readline: %s\n", str(arg0)); }'

# interval: periodic output
bpftrace -e 'interval:s:5 { print(@hits); }'
```

> 🔍 **Reverse Engineering Insight:** bpftrace follows the awk pattern: `probe /filter/ { action }`. The filter is critical for performance — without it, every event triggers your action. In production, always add filters to reduce overhead.

⚠️ **Warning:** Poorly written bpftrace programs can consume significant CPU. Start minimal, add complexity gradually, and monitor with `top`.

---



---

[← Previous](03-2-bcc-tools-instant-production-observability.md) | [↑ Index](index.md) | [Next →](05-4-strace-deep-dive-the.md)
