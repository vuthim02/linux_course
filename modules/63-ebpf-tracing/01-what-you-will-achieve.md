## 🎯 What You Will Achieve

Traditional debugging tools (strace, lsof, tcpdump) are invaluable, but they have limitations: strace slows every syscall, tcpdump captures every packet. eBPF changes the game — it lets you write safe, high-performance programs that run inside the kernel itself. This part teaches you to use eBPF-powered tools for real-time production observability without performance overhead.

You will:

- Understand the eBPF architecture, verifier, JIT compilation, and map data structures
- Use bcc-tools for instant production-safe observability (execsnoop, opensnoop, biolatency, cachestat)
- Write bpftrace one-liners and scripts for custom kernel tracing
- Master strace with filtering, timing, following children, and statistics
- Use perf for CPU profiling, cache miss analysis, branch prediction, and flame graphs
- Trace network packets with tcptrace, tc, and XDP basics
- Monitor filesystem I/O with ext4slower, xfsslower, and filetop
- Debug real-world production issues: slow I/O, memory leaks, CPU spikes
- Choose the right tracing tool for any debugging scenario





[↑ Index](index.md) | [Next →](02-1-what-is-ebpf-the.md)
