## 🔍 Section 2: bpftrace

### What Is bpftrace?

bpftrace is a high-level tracing language for Linux built on top of eBPF. It is to eBPF what AWK is to C — a concise, interpreted language that compiles down to eBPF bytecode at runtime. It uses LLVM as a backend to compile bpftrace scripts into BPF programs.

### bpftrace Language Basics

```
probe /filter/ { action }
```

| Component | Description | Example |
|-----------|-------------|---------|
| **probe** | Attachment point | `kprobe:do_sys_open`, `tracepoint:syscalls:sys_enter_open` |
| **filter** | Boolean expression | `/pid == 12345/` |
| **action** | Code block executed on hit | `{ printf("%s\\n", comm); }` |

### Built-in Variables

| Variable | Description |
|----------|-------------|
| `pid` | Process ID |
| `tid` | Thread ID |
| `uid` | User ID |
| `comm` | Process name (16 bytes) |
| `nsecs` | Timestamp in nanoseconds |
| `kstack` | Kernel stack trace |
| `ustack` | User stack trace |
| `args` | Tracepoint/kprobe arguments |
| `curtask` | Current task_struct pointer |
| `cpu` | CPU ID |
| `cgroup` | Cgroup ID |

### One-Liners: System Tracing

```bash
# Install bpftrace
sudo apt install bpftrace
# On older kernels, you may need:
# sudo apt install linux-tools-$(uname -r) bpftrace

# 1. opensnoop — trace file opens (like strace but zero overhead)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\\n", comm, str(args->filename)); }'

# 2. execsnoop — trace new processes
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }'

# 3. biolatency — histogram of block I/O latency
sudo bpftrace -e 'kprobe:blk_account_io_done { @usecs = hist(nsecs / 1000); }'

# 4. tcptop — show TCP connections by bandwidth
sudo bpftrace -e 'kprobe:tcp_sendmsg { @bytes[pid, comm] += args->size; } interval:s:1 { print(@bytes); clear(@bytes); }'

# 5. runqlat — scheduler run queue latency
sudo bpftrace -e 'tracepoint:sched:sched_wakeup { @start[pid] = nsecs; } tracepoint:sched:sched_switch /@start[pid]/ { @usecs = hist((nsecs - @start[pid]) / 1000); delete(@start[pid]); }'

# 6. Count syscalls by process
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @syscalls[comm] = count(); }'

# 7. Count syscalls by syscall name
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_* { @[probe] = count(); }'

# 8. Show files opened by a specific process
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /pid == 1234/ { printf("%s\\n", str(args->filename)); }'

# 9. Read size histogram by process
sudo bpftrace -e 'tracepoint:syscalls:sys_exit_read /args->ret > 0/ { @bytes[comm] = hist(args->ret); }'

# 10. TCP retransmits
sudo bpftrace -e 'kprobe:tcp_retransmit_skb { printf("%-16s %-16s %d\\n", comm, str(args->sk->__sk_common.skc_daddr), pid); }'
```

### bpftrace Script Example

Save as `syscount.bt`:

```bpftrace
#!/usr/bin/env bpftrace

BEGIN
{
    printf("Tracing syscalls by process. Ctrl-C to exit.\\n");
}

tracepoint:raw_syscalls:sys_enter
{
    @syscalls[pid, comm] = count();
}

END
{
    printf("\\n%-10s %-16s %-10s\\n", "PID", "COMM", "COUNT");
    print(@syscalls);
    clear(@syscalls);
}
```

Run it:
```bash
sudo bpftrace syscount.bt
```

### Maps in bpftrace

bpftrace supports associative arrays (maps) similar to AWK:

| Operation | Description |
|-----------|-------------|
| `@name[key] = value` | Assign |
| `@name[key]++` | Increment |
| `@name[key] = count()` | Count occurrences |
| `@name[key] = hist(value)` | Log2 histogram |
| `@name[key] = lhist(value, min, max, step)` | Linear histogram |
| `@name[key] = sum(value)` | Sum |
| `@name[key] = avg(value)` | Average |
| `@name[key] = max(value)` | Maximum |
| `@name[key] = min(value)` | Minimum |
| `stats(@name)` | Print all stats |
| `print(@name)` | Print map |
| `clear(@name)` | Clear map |
| `delete(@name[key])` | Delete key |
| `zero(@name)` | Zero all values |

### Profiling Without Overhead

Because bpftrace compiles to eBPF bytecode that runs in the kernel (not in userspace), the overhead is minimal — typically microseconds per event. Compare this to `strace` which uses `ptrace()` and context-switches on every syscall (10-100x slowdown).

```bash
# Profile kernel functions (sampling at 99 Hz)
sudo bpftrace -e 'profile:hz:99 { @[kstack] = count(); }'

# Profile user functions for a PID
sudo bpftrace -e 'profile:hz:99 /pid == 1234/ { @[ustack] = count(); }'

# Count page faults by process
sudo bpftrace -e 'tracepoint:exceptions:page_fault_user { @faults[comm] = count(); }'

# Measure time spent in vfs_read
sudo bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; } kretprobe:vfs_read /@start[tid]/ { @latency = hist(nsecs - @start[tid]); delete(@start[tid]); }'
```





[← Previous](02-section-1-ebpf-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-3-xdp-express-data.md)
