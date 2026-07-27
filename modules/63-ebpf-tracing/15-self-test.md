## Self-Test

1. What is eBPF and what problem does it solve?
2. What does the eBPF verifier check before allowing a program to load?
3. What is the difference between a kprobe and a tracepoint?
4. Why is strace considered high-overhead for production use?
5. What bcc-tool would you use to find slow disk I/O operations?
6. What does `perf stat -e cache-misses` tell you?
7. How do you generate a flame graph with perf?
8. What is the key advantage of XDP over iptables for packet filtering?
9. What bpftrace one-liner counts syscalls per process?
10. When would you use `uprobe` instead of `kprobe`?
11. What does `cachestat` show and why is it important?
12. How do you trace TCP retransmissions on a production server?
13. What does `biolatency -D` show that `iostat` does not?
14. How do you profile a specific process with perf record?
15. What is the recommended tracing tool hierarchy (least to most invasive)?

**Answers:**
1. eBPF = extended Berkeley Packet Filter; programmable sandboxed code running inside the kernel for safe, high-performance tracing and observability
2. No infinite loops, no out-of-bounds memory access, no null dereferences, bounded execution, valid helper calls, max 1M instructions
3. Tracepoint = static, stable kernel hook points defined in source code; kprobe = dynamic probes on any kernel function name (may change between versions)
4. strace uses ptrace which causes 3 context switches per syscall, adding 10-100x overhead on the traced process
5. `ext4slower-bpfcc` (or `xfsslower-bpfcc` for XFS) — shows filesystem operations slower than a threshold
6. Hardware cache miss count — high numbers indicate poor memory access patterns causing CPU stalls
7. `perf record -a -g -F 99 -- sleep N` then `perf script | stackcollapse-perf.pl | flamegraph.pl > out.svg`
8. XDP runs before kernel allocates sk_buff, processing packets at line rate; iptables processes after full stack allocation
9. `bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'`
10. uprobe traces userspace functions in binaries/libraries; kprobe traces kernel functions only
11. Page cache hit/miss ratio — low hit rate means working set exceeds RAM, causing excessive disk I/O
12. `sudo tcpretrans-bpfcc` — shows retransmit events with connection details and state
13. biolatency shows actual I/O latency distribution (histogram); iostat shows throughput and utilization averages
14. `sudo perf record -p <PID> -g --call-graph dwarf -- sleep 10` then `sudo perf report`
15. Standard tools → bcc-tools → perf → bpftrace → strace → ftrace → kernel modules

**Score:** 12/15 correct = ready for Part 64.

---

*Linux SysAdmin Course | Part 63 of ∞ | Reverse Engineering Approach*
*Previous → Part 62: Memory Management*
*Next → Part 64: Linux Namespaces*

[← Previous](part62.md) | [Next →](part64.md)


---

[← Previous](14-whats-coming-in-part-64.md) | [↑ Index](index.md)
