## Deep Understanding

### ptrace vs eBPF Performance

```
strace (ptrace):
  Process → Kernel (ptrace) → strace (read)
  = 3 context switches per syscall = 10-100x overhead

eBPF (bpftrace/bcc):
  Process → Kernel (eBPF runs in-line) → result in map
  = 0 context switches = <1% overhead
```

### When bpftrace Beats strace (and Vice Versa)

```
Use bpftrace when:
  - Tracing kernel functions (kprobes)
  - High-frequency events (>1000/sec)
  - Aggregation needed (histograms, counts)
  - Multiple processes simultaneously
  - Cannot attach to process (permissions)

Use strace when:
  - Need full syscall arguments and data buffers
  - Tracing a single short-lived process
  - Understanding a program's system interaction
  - Debugging a script (low frequency, low overhead acceptable)
```

### Probe Stability

```
┌────────────┬──────────────────┬────────────┬─────────────────┐
│ Probe Type │ Where Defined    │ Stability  │ Overhead        │
├────────────┼──────────────────┼────────────┼─────────────────┤
│ tracepoint │ Kernel (static)  │ STABLE ABI │ Very Low        │
│ kprobe     │ Any kernel fn    │ UNSTABLE   │ Very Low        │
│ uprobe     │ Userspace binary │ MODERATE   │ Low (breakpoint)│
│ profile    │ Timer interrupt  │ STABLE     │ Fixed (1-999Hz) │
│ software   │ Kernel counters  │ STABLE     │ Very Low        │
│ hardware   │ CPU PMU          │ HW-dependent│ Very Low       │
└────────────┴──────────────────┴────────────┴─────────────────┘

Production rule: ALWAYS prefer tracepoints when available.
Only use kprobes/uprobes when no tracepoint covers your need.
```

### Common Pitfalls and How to Avoid Them

```
Pitfall 1: Unfiltered bpftrace in production
  BAD:  bpftrace -e 'kprobe:* { @[kstack] = count(); }'
  GOOD: bpftrace -e 'kprobe:tcp_sendmsg /comm == "nginx"/ { @[kstack] = count(); }'

Pitfall 2: Using strace on long-running processes
  BAD:  strace -p $(pgrep postgres)  # hours
  GOOD: sudo timeout 10 strace -c -p $(pgrep postgres)

Pitfall 3: Forgetting -f with strace on forking processes
  BAD:  strace command  # misses child processes
  GOOD: strace -f command  # follows all children

Pitfall 4: Profiling too briefly
  BAD:  perf record -F 99 -- sleep 1  # too short
  GOOD: perf record -F 99 -- sleep 30  # capture full behavior

Pitfall 5: Ignoring perf report overhead percentages
  Always check "Overhead" column — the top 3-5 functions
  tell you 80% of the performance story.
```

> 🔍 **Reverse Engineering Insight:** Use tracepoints for production (stable, fast). Use kprobes for kernel functions without tracepoints. Use uprobes for userspace. Use profile for CPU sampling. Tracepoints are your safe default.

---



---

[← Previous](11-hands-on-practices.md) | [↑ Index](index.md) | [Next →](13-command-reference.md)
