## 1. What is eBPF — The Kernel's Programmable Engine

### The Big Picture

eBPF (extended Berkeley Packet Filter) lets you run **sandboxed programs inside the kernel** without modifying kernel source or loading modules.

```
┌──────────────────────────────────────────────────────────────────┐
│                        USER SPACE                                 │
│   bpftrace  │  bcc-tools  │  perf  │  iproute2  │  Custom Tool  │
│      └────────────┴───────────┴─────────┴──────────────┘          │
│                          bpf() syscall                             │
├──────────────────────────────────────────────────────────────────┤
│                        KERNEL SPACE                               │
│   ┌─────────────────────────────────────────────────────┐        │
│   │               eBPF Verifier                          │        │
│   │   (Validates program safety before loading)         │        │
│   └──────────────────┬──────────────────────────────────┘        │
│   ┌──────────────────▼──────────────────────────────────┐        │
│   │               eBPF Maps (shared data structures)    │        │
│   └──────────────────┬──────────────────────────────────┘        │
│   ┌──────────────────▼──────────────────────────────────┐        │
│   │               JIT Compiler (bytecode → native)      │        │
│   └──────────────────┬──────────────────────────────────┘        │
│   ┌──────────────────▼──────────────────────────────────┐        │
│   │   Hook Points: kprobe │ tracepoint │ XDP │ tc │ LSM │        │
│   └─────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

### eBPF Program Lifecycle

```
Write program (C/bpftrace) → Compile to bytecode → bpf() syscall
    → VERIFIER checks (no loops, no OOB, no null deref, bounded)
    → JIT compile to native x86_64/arm64
    → Attach to hook point → Execute on every event
    → Read results from eBPF maps → Detach and unload
```

### Kernel Version Requirements

```
┌─────────────────────────────────────────────────────────────┐
│  Feature              │  Minimum Kernel Version              │
├───────────────────────┼──────────────────────────────────────┤
│  Basic eBPF           │  3.18                               │
│  kprobes/uprobes      │  4.1                                │
│  BPF maps (hash/array)│  4.1                                │
│  Tracepoints          │  4.7                                │
│  BPF Type Format (BTF)│  4.18                               │
│  Ring buffers         │  5.8                                │
│  CO-RE (portable)     │  5.4                                │
└─────────────────────────────────────────────────────────────┘
```

### eBPF Maps — Shared Data Structures

```
┌─────────────────────────────────────────────────────────────┐
│  Map Type          │  Use Case            │  Key → Value    │
├────────────────────┼──────────────────────┼─────────────────┤
│  HASH              │  Counters, lookup    │  u32 → u64     │
│  ARRAY             │  Per-CPU stats       │  u32 → u64     │
│  RINGBUF           │  Streaming events    │  event → user  │
│  PERF_EVENT        │  Perf output         │  event → user  │
│  LRU_HASH          │  Bounded caches      │  u32 → u64     │
│  STACK_TRACE       │  Stack traces        │  tid → stack   │
└─────────────────────────────────────────────────────────────┘
```

```bash
sudo bpftool prog list          # List loaded eBPF programs
sudo bpftool map list           # List eBPF maps
sudo bpftool map dump id <ID>   # Show map contents
```

> 🔍 **Reverse Engineering Insight:** The eBPF verifier is the key innovation. It performs static analysis of your bytecode before it ever runs in the kernel. You can write custom tracing code and load it on production systems with confidence — the kernel guarantees it cannot crash or corrupt data.

⚠️ **Warning:** Most production tracing tools require kernel 4.15+ and ideally 5.4+. Check with `uname -r` first.

---



---

[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-2-bcc-tools-instant-production-observability.md)
