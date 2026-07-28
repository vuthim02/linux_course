## 9. When to Use Which Tool — Decision Matrix

### Tool Comparison

```
┌────────────┬──────────┬────────────┬─────────────┬────────────────┐
│ Tool       │ Overhead │ Production │ Flexibility │ Learning Curve │
├────────────┼──────────┼────────────┼─────────────┼────────────────┤
│ bcc-tools  │ Very Low │ Safe       │ Low (fixed) │ Easy           │
│ bpftrace   │ Very Low │ Safe*      │ Very High   │ Medium         │
│ perf       │ Low      │ Safe       │ High        │ Medium         │
│ strace     │ HIGH     │ Unsafe**   │ Medium      │ Easy           │
│ XDP/bpf    │ Very Low │ Safe       │ Very High   │ Hard           │
└────────────┴──────────┴────────────┴─────────────┴────────────────┘
```

### Scenario → Tool Mapping

```
┌───────────────────────────────────┬─────────────────────────────┐
│ Scenario                          │ Best Tool                   │
├───────────────────────────────────┼─────────────────────────────┤
│ "What process just started?"      │ execsnoop (bcc)             │
│ "Who is opening /etc/shadow?"     │ opensnoop (bcc)             │
│ "Why is disk I/O slow?"           │ biolatency + ext4slower     │
│ "Why is CPU pegged at 100%?"      │ perf record + flame graph   │
│ "Where are cache misses?"         │ perf stat + perf record     │
│ "Are there TCP retransmits?"      │ tcpretrans (bcc)            │
│ "What syscall is slow?"           │ strace -T                    │
│ "What kernel function is slow?"   │ bpftrace + kprobe           │
│ "Trace my custom event"           │ bpftrace                    │
│ "Profile for flame graph"         │ perf record + FlameGraph    │
│ "How effective is page cache?"    │ cachestat (bcc)             │
│ "Why did OOM kill happen?"        │ oomkill (bcc)               │
│ "What is this process doing now?" │ perf top -p <PID>           │
└───────────────────────────────────┴─────────────────────────────┘
```

### The Tracing Hierarchy (Least → Most Invasive)

```
1. Standard tools: top, iostat, vmstat, ss     ← start here
2. bcc-tools: execsnoop, opensnoop, biolatency ← production-safe
3. perf: record, stat, top, flame graphs       ← CPU profiling
4. bpftrace: custom probes, scripts            ← when bcc-tools don't answer
5. strace: syscall tracing                     ← last resort, high overhead
6. ftrace/debugfs: raw kernel tracing          ← when all else fails
```

> 🔍 **Reverse Engineering Insight:** Golden rule: start with the least invasive tool. Don't use strace when top would do. Don't write a bpftrace script when a bcc-tool already exists. Each layer adds overhead — move down only when the previous layer fails.





[← Previous](09-8-real-world-debugging-scenarios.md) | [↑ Index](index.md) | [Next →](11-hands-on-practices.md)
