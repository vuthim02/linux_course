## 🔍 Section 1: eBPF Fundamentals

### What Is eBPF?

eBPF (extended Berkeley Packet Filter, originally "Berkeley Packet Filter") is a revolutionary kernel technology that allows sandboxed programs to run inside the Linux kernel without modifying kernel source or loading kernel modules. It began as a cleaner version of the classic BPF used by `tcpdump` and evolved into a general-purpose execution engine.

**Key insight:** eBPF turns the kernel into a programmable machine. Instead of adding features by writing kernel modules (risky, hard to maintain) or using fixed interfaces like `iptables`, you write small C programs that the kernel verifies for safety and JIT-compiles for performance.

### Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Userspace                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │ bpftool  │  │ bpftrace │  │ Cilium   │  │ Custom eBPF app │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬────────┘  │
│       │              │              │                 │           │
├───────┼──────────────┼──────────────┼─────────────────┼───────────┤
│       │              │              │                 │  Kernel   │
│  ┌────▼──────────────▼──────────────▼─────────────────▼──────┐   │
│  │                    bpf() syscall                          │   │
│  │  BPF_PROG_LOAD │ BPF_MAP_CREATE │ BPF_PROG_ATTACH        │   │
│  └───────────────────────────┬───────────────────────────────┘   │
│                              │                                    │
│  ┌───────────────────────────▼───────────────────────────────┐   │
│  │                    BPF Verifier                           │   │
│  │  ✓ No loops (until bounded loops in 5.3+)                │   │
│  │  ✓ No out-of-bounds access                               │   │
│  │  ✓ No null pointer dereference                           │   │
│  │  ✓ Maximum instruction count (4096, extended 1M)         │   │
│  │  ✓ Type-safe memory access                               │   │
│  └───────────────────────────┬───────────────────────────────┘   │
│                              │                                    │
│  ┌───────────────────────────▼───────────────────────────────┐   │
│  │                   JIT Compiler                            │   │
│  │  x86_64 │ ARM64 │ RISC-V │ s390x — native machine code   │   │
│  └───────────────────────────┬───────────────────────────────┘   │
│                              │                                    │
│  ┌───────────────────────────▼───────────────────────────────┐   │
│  │                   Hook Attachment                         │   │
│  │  ┌──────┐ ┌──────┐ ┌─────┐ ┌───┐ ┌──────┐ ┌───────────┐ │   │
│  │  │ XDP  │ │ tc   │ │kprobe│ │tp │ │cgroup│ │perf_events│ │   │
│  │  └──────┘ └──────┘ └─────┘ └───┘ └──────┘ └───────────┘ │   │
│  └───────────────────────────────────────────────────────────┘   │
│                              │                                    │
│  ┌───────────────────────────▼───────────────────────────────┐   │
│  │                    BPF Maps                                │   │
│  │  Hash │ Array │ LRU │ Ring Buffer │ Stack │ Queue         │   │
│  │  ── Shared data structures between kernel and userspace   │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### The eBPF Lifecycle: Step-by-Step

```
1. C Source Code (example.bpf.c)
   ──────────────────────────────
   int xdp_drop(struct xdp_md *ctx) {
       return XDP_DROP;
   }

2. Clang with BPF backend
   ─────────────────────────
   $ clang -O2 -target bpf -c xdp_drop.c -o xdp_drop.o
   Produces ELF file with .text section containing BPF bytecode

3. BPF Bytecode
   ─────────────
   Disassembly of section .text:
   0: (b7) r0 = 1        // XDP_DROP = 1
   1: (95) exit

4. bpf() syscall — BPF_PROG_LOAD
   ─────────────────────────────
   int fd = bpf(BPF_PROG_LOAD, &attr, sizeof(attr));

5. Verifier
   ─────────
   Kernel checks: no loops (or bounded), no null ptr deref,
   no stack out-of-bounds, no unreachable instructions,
   type matches for map access. Prints verifier log:
   
   0: (b7) r0 = 1
   1: (95) exit
   processed 2 insns (limit 1000000) max_states_per_insn 0
   total_states 0 peak_states 0 mark_read 0
   Verifier safe: program accepted

6. JIT Compilation
   ───────────────
   Bytecode → native x86_64 machine code:
   mov eax, 1    ; XDP_DROP
   ret

7. Attach to hook
   ──────────────
   $ ip link set dev eth0 xdp obj xdp_drop.o
   or
   int err = bpf(BPF_PROG_ATTACH, ...);

8. Maps (optional shared state)
   ────────────────────────────
   __section(".maps") struct {
       __uint(type, BPF_MAP_TYPE_HASH);
       __uint(max_entries, 1024);
       __type(key, u32);
       __type(value, u64);
   } packet_count SEC(".maps");
   
   Userspace reads/writes via:
   int key = 0; u64 value;
   bpf(BPF_MAP_LOOKUP_ELEM, map_fd, &key, &value);
```

### BPF Hooks

| Hook | Trigger | Context | Use Case |
|------|---------|---------|----------|
| **XDP** | Before `skb` allocation, at driver level | `xdp_md` (packet data, len) | DDoS mitigation, load balancing, packet filtering |
| **TC (traffic control)** | After `skb` allocation, ingress/egress | `__sk_buff` | Traffic shaping, NAT, load balancing |
| **kprobe/kretprobe** | Function entry/return | `pt_regs` | Dynamic tracing of any kernel function |
| **tracepoint** | Static kernel tracepoints | Tracepoint-specific struct | Stable tracing interface |
| **fentry/fexit** | Function entry/exit (5.5+) | Function args/return | Faster than kprobes, stable |
| **cgroup** | Per-cgroup operations | cgroup context | Network policy per cgroup |
| **perf_event** | Hardware/software events | `bpf_perf_event_data` | Profiling, PMC-based analysis |
| **socket** | Socket operations | `__sk_buff` | Socket filtering, sockops |

### bpftool

The primary CLI tool for inspecting eBPF objects:

```bash
# Install bpftool
sudo apt install linux-tools-common linux-tools-$(uname -r) bpftool
# Or build from source:
git clone https://github.com/libbpf/bpftool.git
cd bpftool && make && sudo make install

# List all loaded eBPF programs
sudo bpftool prog list

# List all eBPF maps
sudo bpftool map list

# Show details of a specific program
sudo bpftool prog show id 123

# Dump the JIT-compiled machine code
sudo bpftool prog dump jited id 123

# Dump the original BPF bytecode
sudo bpftool prog dump xlated id 123

# Pin a program to BPF filesystem
sudo mount -t bpf bpffs /sys/fs/bpf
sudo bpftool prog pin id 123 /sys/fs/bpf/my_prog

# Attach XDP program to interface
sudo bpftool net attach xdp id 123 dev eth0

# Show network-attached programs
sudo bpftool net list

# Show feature flags
sudo bpftool feature
```

### BPF Maps

Maps are the data structures that eBPF programs use to share state with userspace and between programs:

| Map Type | Description |
|----------|-------------|
| `BPF_MAP_TYPE_HASH` | Generic hash table (key-value store) |
| `BPF_MAP_TYPE_ARRAY` | Fixed-size array (fast, no deletion) |
| `BPF_MAP_TYPE_PERCPU_HASH` | Per-CPU hash (lock-free, high performance) |
| `BPF_MAP_TYPE_PERCPU_ARRAY` | Per-CPU array |
| `BPF_MAP_TYPE_LRU_HASH` | LRU-evicting hash for caching |
| `BPF_MAP_TYPE_RINGBUF` | Ring buffer (efficient data transfer, 5.8+) |
| `BPF_MAP_TYPE_STACK_TRACE` | Stack trace storage |
| `BPF_MAP_TYPE_DEVMAP` | Redirect target for XDP |
| `BPF_MAP_TYPE_CPUMAP` | CPU redirect for XDP |
| `BPF_MAP_TYPE_SOCKMAP` | Socket redirection for SK_MSG/SK_SKB |
| `BPF_MAP_TYPE_PROG_ARRAY` | Tail-call dispatch table |

```bash
# Create a map with bpftool
sudo bpftool map create /sys/fs/bpf/counters type hash key 4 value 8 entries 1024 name counters

# Show map contents
sudo bpftool map dump id <map_id>

# Update a map entry
sudo bpftool map update id <map_id> key 0x00 0x00 0x00 0x01 value 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x0a
```

---



---

[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-bpftrace.md)
