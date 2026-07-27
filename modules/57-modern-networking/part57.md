# 🐧 Linux System Administrator — Complete Course
## Part 57 of ∞: Modern Linux Networking — eBPF, Cilium, WireGuard, VXLAN

---

> **Reverse Engineering Approach:** Every packet that enters or leaves a Linux system traverses code paths that have grown increasingly programmable. Thirty years ago the kernel's network stack was fixed — you could filter with `iptables` or route with `iproute2`, but you could never inject your own logic deep inside the kernel's fast path. eBPF changed that. It is a tiny, sandboxed virtual machine embedded in the kernel that lets you attach user-defined programs to hooks all the way from the NIC driver (XDP) up to the socket layer. Cilium builds a complete container networking platform on top of eBPF, replacing kube-proxy and iptables with a kernel-native datapath. WireGuard gives you a VPN that lives in just 4,000 lines of kernel code. VXLAN stretches Layer 2 across the datacenter. This part traces every packet through all four technologies — from the moment it hits the wire, through eBPF programs that decide its fate, across VXLAN tunnels that carry it between hosts, encrypted by WireGuard, and observed by Hubble — until it reaches its destination container.

---

## 🎯 What You Will Achieve in Part 57

By the end of this part, you will:

- Understand eBPF architecture: sandboxed programs, verifier, JIT compiler, maps, and hooks
- Write and run bpftrace one-liners for system tracing without overhead
- Grasp XDP (eXpress Data Path) — the earliest possible interception of network packets
- Deploy Cilium as a Kubernetes CNI with full eBPF dataplane replacing kube-proxy
- Write Cilium network policies at L3, L4, and L7 with real-world examples
- Use Hubble for observability — flow logs, service maps, and metrics
- Build WireGuard tunnels from scratch — point-to-point, site-to-site, and roaming clients
- Understand WireGuard kernel internals: Noise protocol, ChaCha20Poly1305, timers
- Create VXLAN overlay networks with Linux native interfaces
- Bridge VXLAN with Linux bridges for multi-tenant L2 extension
- Combine VXLAN + FRR (BGP) for EVPN-based overlays
- Tune and benchmark all four technologies for production performance
- Complete **15 hands-on practices** including a real-world multi-node Kubernetes integration

---

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

---

## 🔍 Section 3: XDP (eXpress Data Path)

### What Is XDP?

XDP is an eBPF hook that runs the earliest possible point in the kernel network stack — inside the NIC driver, before an `sk_buff` is even allocated. This gives it the lowest possible latency (as low as 10-20 nanoseconds per packet) and the highest throughput.

### XDP Hook Position

```
Packet arrives on wire
       │
       ▼
┌─────────────────────────┐
│ NIC Hardware            │
│ DMA to ring buffer      │
└─────────────────────────┘
       │
       ▼
┌─────────────────────────┐
│ ❗ XDP Hook             │ ← HERE — before any kernel processing
│ xdp_md context:         │
│   data, data_end        │
│   data_meta             │
│   ingress_ifindex       │
│   rx_queue_index        │
└─────────┬───────────────┘
          │
    ╔══════╧══════╗
    ║ XDP_ABORTED ║ ← Drop with tracepoint
    ║ XDP_DROP    ║ ← Silently drop
    ║ XDP_PASS    ║ ← Proceed to normal stack
    ║ XDP_TX      ║ ← Transmit back out same interface
    ║ XDP_REDIRECT║ ← Redirect to another NIC/CPU/peer
    ╚══════╤══════╝
          │  (XDP_PASS)
          ▼
┌─────────────────────────┐
│ sk_buff allocation      │
│ GRO (generic receive)   │
│ tc ingress hook         │
│ ...                     │
│ Socket delivery         │
└─────────────────────────┘
```

### XDP Actions

| Action | Value | Description |
|--------|-------|-------------|
| `XDP_ABORTED` | 0 | Drop packet and raise tracepoint `xdp:xdp_exception` for debugging |
| `XDP_DROP` | 1 | Drop packet silently (maximum performance for filtering) |
| `XDP_PASS` | 2 | Allow packet to continue to normal network stack |
| `XDP_TX` | 3 | Transmit packet back out the same interface (e.g., load balancer hairpin) |
| `XDP_REDIRECT` | 4 | Redirect to another interface, CPU, or AF_XDP socket |

### XDP Modes

| Mode | Description | Performance |
|------|-------------|-------------|
| **Native (driver)** | NIC driver supports XDP natively — runs before `skb` alloc | Highest: 10-20 ns/pkt |
| **Generic** | Runs in the kernel's generic RX path (any driver) | Low: simulates XDP after `skb` alloc |
| **Offloaded** | Runs on the NIC hardware itself (SmartNICs like Netronome) | Highest: wire speed, no CPU |

Check which drivers support native XDP:
```bash
sudo bpftool feature list | grep xdp
# Look for: xdp action XDP_DROP/XDP_PASS/XDP_TX/XDP_REDIRECT
```

### Writing an XDP Program

`xdp_drop_port.c`:

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>

#define ETH_P_IP 0x0800

SEC("xdp")
int xdp_drop_port(struct xdp_md *ctx)
{
    void *data_end = (void *)(unsigned long)ctx->data_end;
    void *data = (void *)(unsigned long)ctx->data;
    struct ethhdr *eth = data;

    if (eth + 1 > data_end)
        return XDP_PASS;

    // Only IPv4
    if (bpf_ntohs(eth->h_proto) != ETH_P_IP)
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(*eth);
    if (ip + 1 > data_end)
        return XDP_PASS;

    // Only TCP
    if (ip->protocol != IPPROTO_TCP)
        return XDP_PASS;

    struct tcphdr *tcp = (void *)ip + sizeof(*ip);
    if (tcp + 1 > data_end)
        return XDP_PASS;

    // Drop traffic to port 8080
    if (tcp->dest == bpf_htons(8080))
        return XDP_DROP;

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
```

Compile and load:
```bash
clang -O2 -target bpf -c xdp_drop_port.c -o xdp_drop_port.o
# Check the BPF bytecode
llvm-objdump -d xdp_drop_port.o
# Load onto interface
sudo ip link set dev eth0 xdp obj xdp_drop_port.o
# Verify
sudo ip link show dev eth0
# Look for: xdp/prog-id:123
# Remove
sudo ip link set dev eth0 xdp off
```

### XDP vs tc (Traffic Control)

| Aspect | XDP | tc |
|--------|-----|----|
| Hook location | NIC driver (pre-skb) | After skb allocation |
| Context | `xdp_md` (raw packet data) | `__sk_buff` (socket buffer) |
| Speed | 10-20x faster | Baseline |
| Use cases | DDoS, load balancing, packet steering | NAT, shaping, QoS, conntrack |
| Access to packet data | Direct pointer (`data`, `data_end`) | Via `skb->data` helpers |
| Rewrite packets | Yes, before checksum offload | Yes, after checksum |
| Redirect | Redirect to ifindex, CPU, AF_XDP | Mirred, ifb |

### XDP Use Cases

**1. DDoS Mitigation (Dropping attack traffic at wire speed)**

```c
// XDP program that drops based on source IP blacklist (hash map)
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1000000);
    __type(key, __u32);
    __type(value, __u32);
} blacklist SEC(".maps");

SEC("xdp")
int xdp_ddos_filter(struct xdp_md *ctx)
{
    void *data_end = (void *)(unsigned long)ctx->data_end;
    void *data = (void *)(unsigned long)ctx->data;
    struct ethhdr *eth = data;
    if (eth + 1 > data_end)
        return XDP_PASS;
    struct iphdr *ip = data + sizeof(*eth);
    if (ip + 1 > data_end)
        return XDP_PASS;
    __u32 sip = ip->saddr;
    if (bpf_map_lookup_elem(&blacklist, &sip))
        return XDP_DROP;
    return XDP_PASS;
}
```

```bash
# Populate blacklist
sudo bpftool map update pinned /sys/fs/bpf/blacklist key 0xc0 0xa8 0x01 0x01 value 0x01
```

**2. Load Balancing (DDoS protection + forwarding)**

Facebook's Katran uses XDP to build a Layer 4 load balancer that handles 10+ million packets per second per CPU core. The XDP program hashes the 5-tuple, looks up the backend in a BPF map, and uses `XDP_TX` to forward directly back out the NIC.

**3. AF_XDP Sockets**

AF_XDP is a new socket family that gives userspace zero-copy access to XDP-processed packets:

```bash
# Enable AF_XDP on an interface
sudo ethtool -n eth0 rx-flow-hash udp4
sudo ip link set dev eth0 xdp obj xdpsock_kern.o
# Then use xdpsock_user to receive zero-copy
```

---

## 🔍 Section 4: Cilium

### What Is Cilium?

Cilium is an eBPF-based CNI (Container Network Interface) plugin for Kubernetes. It replaces the entire kube-proxy and iptables-based networking with a high-performance eBPF datapath. It provides:

- **eBPF-based service translation** (replaces kube-proxy)
- **Network policies** at L3, L4, and L7
- **Hubble** — observability for network flows
- **Transparent encryption** via WireGuard or IPsec
- **Service mesh** — L7 traffic management, ingress, gateway API
- **ClusterMesh** — multi-cluster networking

### Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    Kubernetes Node                                 │
│                                                                    │
│  ┌──────────────────────┐  ┌────────────────────┐                 │
│  │  Cilium Agent        │  │  Cilium Operator   │                 │
│  │  (cilium-agent)      │  │  (cluster-level)   │                 │
│  │                      │  │                    │                 │
│  │  • eBPF datapath     │  │  • IPAM            │                 │
│  │  • Policy enforcement│  │  • Node management │                 │
│  │  • Service handling  │  │  • CNI integration │                 │
│  │  • Hubble server     │  │  • CiliumEndpoint  │                 │
│  └──────────┬───────────┘  └────────────────────┘                 │
│             │                                                      │
│  ┌──────────▼───────────┐                                         │
│  │  eBPF Programs       │                                         │
│  │  ┌──────┐ ┌───────┐ │ ┌──────────────┐ ┌──────────────────┐   │
│  │  │ XDP  │ │ tc    │ │ │ cgroup/skb   │ │ cgroup/sock      │   │
│  │  └──────┘ └───────┘ │ └──────────────┘ └──────────────────┘   │
│  │  ┌────────┐ ┌─────┐ │ ┌──────────┐                            │
│  │  │ l3_l4  │ │ l7  │ │ │ encap    │                            │
│  │  └────────┘ └─────┘ │ └──────────┘                            │
│  └─────────────────────┘                                          │
│                                                                    │
│  ┌──────────────────────┐                                         │
│  │  Hubble              │                                         │
│  │  • Flow collector    │                                         │
│  │  • Service map       │                                         │
│  │  • Metrics (Prom)    │                                         │
│  └──────────────────────┘                                         │
└────────────────────────────────────────────────────────────────────┘
```

### Installing Cilium

**Prerequisites:**
```bash
# Install kind (Kubernetes in Docker)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/

# Create a kind cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

**Install Cilium CLI:**
```bash
# Download and install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
```

**Install Cilium with kube-proxy replacement:**
```bash
cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=<KUBERNETES_API_SERVER_IP> \
  --set k8sServicePort=6443

# Or for a kind cluster (simpler):
cilium install --set kubeProxyReplacement=true

# Verify
cilium status
cilium connectivity test
```

### How Cilium Replaces kube-proxy

Traditional Kubernetes networking:

```
Pod A (10.0.1.5) → Service IP (10.96.0.10:80) → iptables NAT → Pod B (10.0.2.7)
                                                            ↓
                                                    Every packet traverses
                                                    iptables chains (O(n) rules)
```

Cilium's eBPF approach:

```
Pod A (10.0.1.5) → Service IP (10.96.0.10:80)
                            ↓
                    eBPF program (tc or XDP)
                            ↓
                    BPF map lookup:
                    {service_ip, port} → {backend_ip, port}
                            ↓
                    Direct XDP_TX or tc redirect
                    No iptables involved — O(1) lookup
```

The eBPF program runs in the kernel and performs a hash table lookup (BPF_MAP_TYPE_HASH) to translate service VIPs to backend pods. This is **O(1)**, compared to iptables which chains through rules linearly.

```bash
# Verify kube-proxy is not needed
kubectl -n kube-system get pods | grep proxy
# Should show nothing if kubeProxyReplacement=true

# Inspect Cilium's eBPF programs
cilium bpf service list
# Shows service-to-backend mapping

# Example output:
# 10.96.0.10:80 (1) 10.0.2.7:8080 (1)
#                   10.0.2.8:8080 (1)
```

---

## 🔍 Section 5: Cilium Network Policies

### Policy Basics

CiliumNetworkPolicy (CNP) is a Kubernetes custom resource that defines traffic rules. Unlike default Kubernetes NetworkPolicy (which works at L3/L4 with iptables), Cilium policies can:

- Match on L3 (CIDR, pod labels, service identities)
- Match on L4 (ports, protocols)
- Match on L7 (HTTP methods, paths, headers, gRPC methods, Kafka topics)
- Use FQDN-based rules (allow traffic to `api.example.com`)
- Egress and ingress on the same or separate rules

### Policy Structure

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: example-policy
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
  egress:
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
```

### Deny-All Policy

```yaml
# deny-all-ingress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  ingress:
    - {}  # Empty rule = deny all ingress
```

```bash
kubectl apply -f deny-all-ingress.yaml
```

### L3/L4 Policy — Allow Specific Pod-to-Pod

```yaml
# allow-frontend-to-backend.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: backend
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
```

### L7 Policy — HTTP Methods, Paths, Headers

```yaml
# http-l7-policy.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-http
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: web-frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/api/v1/users"
              - method: POST
                path: "/api/v1/orders"
              - method: GET
                path: "/healthz"
              - method: GET
                path: "/api/v1/products/*"
```

```bash
kubectl apply -n default -f http-l7-policy.yaml
# Test:
# kubectl exec -it frontend-pod -- curl -X POST http://api-server:8080/api/v1/users  # Allowed
# kubectl exec -it frontend-pod -- curl -X DELETE http://api-server:8080/api/v1/users # Blocked (403)
```

### FQDN Policy — Allow Egress to Specific Domains

```yaml
# fqdn-egress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-api-egress
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  egress:
    - toFQDNs:
        - matchName: api.example.com
        - matchPattern: "*.example.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
```

FQDN policies automatically resolve DNS names and update the BPF map when IPs change. Cilium intercepts DNS responses to learn new IP addresses.

### CIDR Rules — Direct IP Range Filtering

```yaml
# cidr-egress.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-cidr-egress
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: my-service
  egress:
    - toCIDR:
        - 10.100.0.0/16
        - 192.168.1.0/24
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    - toCIDRSet:
        - cidr: 10.0.0.0/8
          except:
            - 10.96.0.0/12  # Exclude Kubernetes service range
```

### Policy Enforcement Modes

| Mode | Behavior |
|------|----------|
| `default` | Deny-all ingress, allow-all egress (Kubernetes default) |
| `always` | Always enforce policies (even without rules — deny all) |
| `never` | Disable policy enforcement (for migration/testing) |
| Custom | Mix of enforce/audit per endpoint |

```bash
# Check per-endpoint enforcement mode
kubectl describe cep my-pod-xxxxx | grep Policy
```

---

## 🔍 Section 6: Cilium Service Mesh

### L7 Traffic Management

Cilium's service mesh is built into the eBPF datapath — no sidecar proxies needed (unless you want them). It provides:

- **HTTP/1.1, HTTP/2, gRPC aware routing**
- **Transparent encryption** (WireGuard) between pods
- **Mutual authentication** via SPIFFE identities
- **Ingress and Gateway API** support
- **ClusterMesh** for multi-cluster service connectivity

### Enabling L7 Policy

```yaml
# l7-visibility.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-ingress-visibility
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: httpbin
  ingress:
    - toPorts:
        - ports:
            - port: "80"
              protocol: TCP
          rules:
            http:
              - method: "GET"
                path: "/get"
              - method: "POST"
                path: "/post"
```

### Transparent Encryption with WireGuard

Cilium can automatically encrypt all pod-to-pod traffic using WireGuard without modifying application code:

```bash
# Install Cilium with WireGuard encryption
cilium install \
  --set encryption.enabled=true \
  --set encryption.type=wireguard

# Verify WireGuard is active
cilium status | grep Encryption
# Expected: Encryption: WireGuard

# List WireGuard peers on a node
cilium encrypt status

# Check WireGuard interfaces per pod
sudo ip link show | grep lxc
# Cilium creates one WireGuard device per node: cilium_wg0
```

### How Cilium WireGuard Works

```
Pod A (node-1) ──► cilium_wg0 ──► Node-2 ──► Pod B
                     │
                     ▼
              Encrypted tunnel
              ChaCha20Poly1305
              Noise protocol
```

Cilium assigns SPIFFE identities to each pod. When Pod A sends to Pod B:
1. eBPF program classifies the packet and determines it needs encryption
2. Packet is routed to `cilium_wg0` WireGuard interface
3. WireGuard encrypts with Node B's public key
4. Node B decrypts and delivers to Pod B

### Mutual Authentication with SPIFFE

Cilium uses SPIFFE (Secure Production Identity Framework for Everyone) to issue identities to pods:

```
spiffe://cluster.local/ns/default/sa/my-sa
```

These identities are embedded in the eBPF datapath — no sidecars needed.

### Ingress/Gateway API

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cilium-gateway
  namespace: default
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-app-1
  namespace: default
spec:
  parentRefs:
    - name: cilium-gateway
  hostnames:
    - app1.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: app1-service
          port: 8080
```

```bash
kubectl apply -f gateway.yaml -f httproute.yaml
```

### ClusterMesh

ClusterMesh connects multiple Kubernetes clusters so that pods in one cluster can discover and connect to services in another cluster, with all eBPF benefits:

```bash
# Install Cilium on cluster-1 and cluster-2
cilium install --context cluster-1
cilium install --context cluster-2

# Enable ClusterMesh
cilium clustermesh enable --context cluster-1
cilium clustermesh enable --context cluster-2

# Connect them
cilium clustermesh connect --context cluster-1 --destination-context cluster-2

# Status
cilium clustermesh status --context cluster-1
```

---

## 🔍 Section 7: Hubble

### What Is Hubble?

Hubble is a fully distributed networking and security observability platform built on top of Cilium and eBPF. It provides:

- **Flow logs** — every packet flow with metadata (source, dest, protocol, verdict, L7 info)
- **Service map** — real-time dependency graph of services
- **Metrics** — Prometheus metrics for network traffic
- **Cluster-wide visibility** — across all nodes without central aggregation

### Hubble Architecture

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Node 1       │  │ Node 2       │  │ Node 3       │
│ Cilium Agent │  │ Cilium Agent │  │ Cilium Agent │
│ Hubble       │  │ Hubble       │  │ Hubble       │
│ Server       │  │ Server       │  │ Server       │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                    ┌─────▼──────┐
                    │  Hubble    │
                    │  Relay     │
                    │  (optional)│
                    └─────┬──────┘
                          │
              ┌───────────┴───────────┐
              │                       │
         ┌────▼────┐           ┌─────▼─────┐
         │  hubble  │           │ Hubble UI │
         │  CLI     │           │           │
         └─────────┘           └───────────┘
```

### Hubble CLI

```bash
# Install Hubble CLI
curl -L https://raw.githubusercontent.com/cilium/hubble/master/hubble/install.sh | bash

# Or download specific version
curl -Lo hubble-linux-amd64.tar.gz https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar xzvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin/

# Set up port-forward to Hubble Relay
cilium hubble enable
cilium hubble port-forward &

# Observe flows
hubble observe

# Observe flows from a specific namespace
hubble observe --namespace default

# Observe flows for a specific pod
hubble observe --pod frontend-xxxxx

# Observe flows with L7 information
hubble observe --protocol http

# Observe dropped packets
hubble observe --verdict DROPPED

# Observe flows to/from a service
hubble observe --service default/my-service

# JSON output for machine parsing
hubble observe -o json

# Follow mode (like tail -f)
hubble observe -f

# Filter by specific label
hubble observe --label app=frontend

# Show flows for the last 5 minutes
hubble observe --since 5m
```

### Hubble UI

```bash
# Enable Hubble UI
cilium hubble enable --ui

# Access UI
cilium hubble ui

# Or port-forward manually
kubectl -n kube-system port-forward service/hubble-ui 12000:80
# Open http://localhost:12000
```

The Hubble UI shows:
- **Service Map** — real-time graph of all pods and services, with traffic flows
- **Flow Details** — click any pod to see its traffic flows
- **Health Status** — node and cilium-agent health
- **Policies** — which policies are applied to which endpoints

### Service Map

The service map is a live dependency graph showing:

```
┌────────────┐     HTTP GET /api/v1/users     ┌────────────┐
│  frontend  │ ──────────────────────────────► │  api-server │
│  :3000     │                                  │  :8080      │
└────────────┘                                  └────────────┘
      │                                               │
      │ DNS lookup kube-dns:53                        │ Redis:6379
      ▼                                               ▼
┌────────────┐                                  ┌────────────┐
│  kube-dns  │                                  │  redis      │
└────────────┘                                  └────────────┘
```

```bash
# Dump service map as JSON
hubble observe -o json --since 1h > flows.json

# Count unique connections
hubble observe -o json | jq 'select(.l4) | "\\(.source.namespace)/\\(.source.pod_name) -> \\(.destination.namespace)/\\(.destination.pod_name) \\(.l4.TCP.destination_port)"' | sort -u
```

### Metrics

Hubble exports Prometheus metrics:

```bash
# Default metrics endpoints
kubectl -n kube-system port-forward service/hubble-metrics 9091

# Available metrics
curl http://localhost:9091/metrics | grep hubble
```

Key metrics:
- `hubble_flows_processed_total` — total flows by type, verdict, protocol
- `hubble_drop_total` — dropped packet count by reason
- `hubble_tcp_flags_total` — TCP flag distribution
- `hubble_http_requests_total` — HTTP request count by method, path, code
- `hubble_http_duration_seconds` — HTTP latency histogram

---

## 🔍 Section 8: WireGuard

### What Is WireGuard?

WireGuard is a modern VPN protocol that aims to be faster, simpler, and more secure than IPsec or OpenVPN. It is implemented as a kernel module (~4,000 lines of code) and has been part of the Linux kernel since 5.6.

### Architecture

```
┌─────────────┐                    ┌─────────────┐
│   Peer A    │     Encrypted      │   Peer B    │
│ 10.0.0.1/24│ ◄────────────────► │ 10.0.0.2/24│
│ wg0         │   UDP :51820       │ wg0         │
└──────┬──────┘                    └──────┬──────┘
       │                                   │
       │   ┌─────────────────────────┐    │
       └──►│ WireGuard Kernel Module │◄───┘
           │                         │
           │ • ChaCha20Poly1305      │
           │ • Noise_IK handshake    │
           │ • Timers & roaming      │
           │ • Cookie defense        │
           └─────────────────────────┘
```

### WireGuard Kernel Internals

**Cryptographic Primitives:**
- **Symmetric encryption:** ChaCha20Poly1305 (authenticated encryption)
- **Key exchange:** Curve25519 ECDH (X25519)
- **Hashing:** BLAKE2s (for session key derivation)
- **Handshake:** Noise protocol framework (Noise_IK_25519_ChaChaPoly_BLAKE2s)

**Noise Protocol (IK pattern):**
```
→ e, es, s, ss
← e, ee, se
```

This means:
1. Initiator sends: ephemeral key, encrypted static key, signature
2. Responder replies with: ephemeral key, derived session keys
3. Both sides now share symmetric session keys for data

**WireGuard Handshake (Step-by-step):**

```
Peer A                              Peer B
  │                                   │
  │ 1. Generate ephemeral keypair     │
  │    (e_priv, e_pub)                │
  │                                   │
  │ 2. msg1 = Handshake initiation    │
  │    ┌──────────────────────────────►│
  │    │ sender_index                 │
  │    │ unencrypted_ephemeral        │
  │    │ encrypted_static             │
  │    │ encrypted_timestamp          │
  │    │ mac1, mac2                   │
  │    └──────────────────────────────►│
  │                                   │
  │                                   │ 3. Compute DH:
  │                                   │    e_pub * s_priv → shared key
  │                                   │    Decrypt static, verify timestamp
  │                                   │ 4. Generate ephemeral keypair
  │                                   │
  │                                   │ 5. msg2 = Handshake response
  │    ◄──────────────────────────────┐
  │    │ sender_index                 │
  │    │ unencrypted_ephemeral        │
  │    │ encrypted_nothing            │
  │    │ mac1                         │
  │    └──────────────────────────────┤
  │                                   │
  │ 6. Verify, derive session keys    │
  │    (S1, S2 for encryption)        │
  │                                   │
  │ 7. msg3 = Cookie reply            │
  │    ┌──────────────────────────────►│ 8. Session established
  │    │ (empty, just confirms)       │    Data transport begins
  │    └──────────────────────────────►│
```

**Data Transport:**
- Each peer maintains a session with a 64-bit counter
- Each packet is encrypted with ChaCha20Poly1305 using session-derived key
- Includes a message counter to prevent replay attacks

**Roaming:**
WireGuard associates a peer with its public key, not its IP address. If a peer's IP changes (e.g., a mobile client), WireGuard detects the new source IP from an incoming packet and updates its endpoint transparently. This is built into the protocol — no reconnection needed.

**Timers:**
- `persistent_keepalive` — sends empty packets every N seconds to keep NAT mappings alive
- `rekey_after_time` — renegotiates session keys every 120 seconds by default
- `handshake_timeout` — retry handshake every 3 seconds if no response

**Cookie Defense:**
To prevent DoS attacks (like Amplification attacks where a small handshake triggers a large response), WireGuard uses a cookie mechanism. A peer receiving a handshake from an unknown IP first sends a cookie, and the initiator must include the cookie in its handshake before receiving a full response.

### Installing WireGuard

```bash
# Most modern kernels include WireGuard. Check:
modinfo wireguard
# If not found:
sudo apt install wireguard-dkms wireguard-tools
# Install on Ubuntu/Debian
sudo apt install wireguard
# Install on RHEL/CentOS 8+
sudo dnf install wireguard-tools
```

### Configuration

**Server configuration** `/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = gN65s7y7vF6s5h4g3f2d1s0a9z8x7c6v5b4n3m2l1k=

# Peer 1: laptop
[Peer]
PublicKey = 7J34kL2m9nB5vC6xZ1qW8eR4tY7uI3oP5aS6dF7gH8jK9l=
AllowedIPs = 10.0.0.2/32

# Peer 2: server
[Peer]
PublicKey = fR5tG6hY7jU8kI9lO0pP1aQ2sW3dE4rF5tG6hY7jU8k=
AllowedIPs = 10.0.0.3/32
```

**Client configuration** `/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = 4jH8kL9m0nB1vC2xZ3aQ4wS5eD6rF7gT8yU9iI0oP1a=
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = 5gH6jK7lZ8x9cV0bN1mQ2wE3rT4yU5iO6pP7aS8dF9gH=
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### Key Generation

```bash
# Generate private key
wg genkey | tee private.key | wg pubkey > public.key

# Generate pre-shared key (optional, adds symmetric layer)
wg genpsk > psk.key

# View keys
cat private.key
cat public.key

# Generate a full configuration with keys
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
wg genkey | tee /etc/wireguard/client_private.key | wg pubkey > /etc/wireguard/client_public.key
```

### Bringing Up the Interface

```bash
# Bring up WireGuard
sudo wg-quick up wg0

# Check status
sudo wg show

# Expected output:
# interface: wg0
#   public key: 5gH6jK7lZ8x9cV0bN1mQ2wE3rT4yU5iO6pP7aS8dF9gH=
#   private key: (hidden)
#   listening port: 51820
#
# peer: 7J34kL2m9nB5vC6xZ1qW8eR4tY7uI3oP5aS6dF7gH8jK9l=
#   endpoint: 203.0.113.5:51820
#   allowed ips: 10.0.0.2/32
#   latest handshake: 1 minute ago
#   transfer: 1.2 MiB received, 3.4 MiB sent

# Verbose status
sudo wg showconf wg0

# Test connectivity
ping 10.0.0.2

# Bring down
sudo wg-quick down wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

### MTU Considerations

WireGuard adds 60 bytes of overhead (20 IP + 8 UDP + 4 type + 4 key_index + 8 counter + 16 Poly1305 tag = 60):

```ini
[Interface]
Address = 10.0.0.1/24
PrivateKey = ...
MTU = 1420  # 1500 - 60 - 20 (for PPPoE: 1492 - 60 - 8 = 1424)
```

---

## 🔍 Section 9: WireGuard in Practice

### Point-to-Point Tunnel

**Host A (eth0: 203.0.113.1):**
```bash
wg genkey | tee /etc/wireguard/private.key
chmod 600 /etc/wireguard/private.key
```

`/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.99.99.1/30
PrivateKey = <host-a-private>
ListenPort = 51820

[Peer]
PublicKey = <host-b-public>
AllowedIPs = 10.99.99.2/32
Endpoint = 203.0.113.2:51820
PersistentKeepalive = 25
```

**Host B (eth0: 203.0.113.2):**
`/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.99.99.2/30
PrivateKey = <host-b-private>
ListenPort = 51820

[Peer]
PublicKey = <host-a-public>
AllowedIPs = 10.99.99.1/32
Endpoint = 203.0.113.1:51820
PersistentKeepalive = 25
```

```bash
# Bring up on both hosts
sudo wg-quick up wg0

# Test
ping 10.99.99.2  # from Host A
ping 10.99.99.1  # from Host B
```

### Site-to-Site VPN

**Site A (10.0.0.0/24):**
```ini
[Interface]
Address = 10.99.99.1/30
PrivateKey = <site-a-private>
ListenPort = 51820

[Peer]
PublicKey = <site-b-public>
AllowedIPs = 10.0.1.0/24, 10.99.99.2/32
Endpoint = site-b.example.com:51820
PersistentKeepalive = 25
```

**Site B (10.0.1.0/24):**
```ini
[Interface]
Address = 10.99.99.2/30
PrivateKey = <site-b-private>
ListenPort = 51820

[Peer]
PublicKey = <site-a-public>
AllowedIPs = 10.0.0.0/24, 10.99.99.1/32
Endpoint = site-a.example.com:51820
PersistentKeepalive = 25
```

```bash
# Enable IP forwarding on both sides
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
# Make permanent:
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf

# Now any machine in 10.0.0.0/24 can reach any machine in 10.0.1.0/24
# via the tunnel.
```

### Roaming Clients (Mobile/Container)

The beauty of WireGuard's roaming is that a client can move between networks without reconnecting:

```bash
# Client on a laptop at home (192.168.1.100)
# Moves to coffee shop (10.0.0.50 via NAT)
# WireGuard detects the change automatically
# 
# The client sends a packet to the server
# Server sees source IP 10.0.0.50:51820
# Server updates its endpoint for the client
# Connection stays alive

# For NAT traversal, use PersistentKeepalive:
[Peer]
PublicKey = <server-public>
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25  # Send keepalive every 25 seconds
```

### Docker WireGuard Containers

```bash
# Run WireGuard in a container for VPN server
docker run -d \
  --name wireguard \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 51820:51820/udp \
  -v /path/to/config:/config \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  linuxserver/wireguard

# Or for a VPN client (route all traffic through tunnel)
docker run -d \
  --name=wireguard-client \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/client-config:/config \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv6.conf.all.disable_ipv6=0" \
  linuxserver/wireguard
```

### wg-dynamic — Dynamic IP Announcement

`wg-dynamic` is a DHCP-like protocol for WireGuard that allows peers to announce IP prefixes dynamically:

```bash
# Install wg-dynamic
git clone https://github.com/WireGuard/wg-dynamic.git
cd wg-dynamic

# Server configuration /etc/wireguard/wg-dynamic.conf:
[Interface]
PrivateKey = <server-private>
ListenPort = 51820

[Peer]
PublicKey = <client-public>
AllowedIPs = 10.99.99.0/24

# Client: announce a /32
# wg-dynamic automatically configures the client's IP
```

---

## 🔍 Section 10: VXLAN

### What Is VXLAN?

VXLAN (Virtual Extensible LAN) is an overlay networking protocol that encapsulates Layer 2 Ethernet frames inside UDP packets. It is designed to overcome the limitations of VLANs (4096 VLANs) by providing 16 million segments (24-bit VNI).

### VXLAN Encapsulation

```
Original L2 Frame:
┌────────┬──────────┬────────┬──────────┐
│  MAC   │  MAC     │ 802.1Q │  Payload │
│  Dst   │  Src     │ (opt)  │          │
└────────┴──────────┴────────┴──────────┘

VXLAN Encapsulated Packet:
┌──────┬────────┬──────────┬────────┬───────┬──────────┐
│ Outer│ Outer  │ UDP      │ VXLAN  │ Inner │ Inner    │
│ IP   │ UDP    │ 4789    │ Header │ L2    │ Payload  │
│ Hdr  │ Hdr    │          │ VNI=42 │ Frame │          │
└──────┴────────┴──────────┴────────┴───────┴──────────┘
                            │
                       VXLAN Header:
                       Flags (8 bits)  │ Reserved (24)
                       VNI (24 bits)   │ Reserved (8)
```

### Kernel VXLAN Implementation

The kernel implements VXLAN in `drivers/net/vxlan.c`. The encapsulation path:

```
1. skb arrives at VXLAN interface (vxlan0)
2. vxlan_xmit() is called
3. Original L2 frame is preserved as inner header
4. Kernel prepends VXLAN header (VNI, flags)
5. Prepends UDP header (dst_port=4789)
6. Prepends outer IP header (src=local VTEP IP, dst=remote VTEP IP)
7. Prepends outer MAC header
8. skb is transmitted through real interface (eth0)
```

Decapsulation:
```
1. skb arrives at eth0, UDP port 4789
2. vxlan_udp_encap_recv() matches the socket
3. Kernel validates VXLAN header
4. Removes outer headers (MAC, IP, UDP, VXLAN)
5. Inner L2 frame is injected into the VXLAN net_device
6. Linux bridge forwards the frame to the correct local port
```

### VTEP and VNI

| Term | Full Name | Description |
|------|-----------|-------------|
| **VTEP** | VXLAN Tunnel Endpoint | The entity that originates/terminates VXLAN tunnels (Linux host, switch, hypervisor) |
| **VNI** | VXLAN Network Identifier | 24-bit segment ID (1-16,777,215) that identifies the tenant/broadcast domain |
| **VXLAN Interface** | `vxlan0` | Linux virtual interface representing one VNI |
| **UDP Port** | 4789 (IANA) or 8472 (Linux default) | Destination port for VXLAN traffic |

### Linux VXLAN Interfaces

```bash
# Create a VXLAN interface with multicast
sudo ip link add vxlan0 type vxlan \
  id 42 \
  group 239.1.1.1 \
  dstport 4789 \
  dev eth0

# Create a VXLAN interface with unicast (remote peer)
sudo ip link add vxlan1 type vxlan \
  id 100 \
  remote 10.0.0.2 \
  local 10.0.0.1 \
  dstport 4789 \
  dev eth0

# Bring up
sudo ip link set vxlan0 up

# Assign an IP
sudo ip addr add 10.10.0.1/24 dev vxlan0

# Inspect
sudo ip -d link show vxlan0
sudo bridge fdb show dev vxlan0

# Remove
sudo ip link del vxlan0
```

### VXLAN with Linux Bridge for L2 Extension

```
┌─Host-A──────────────────────┐    ┌─Host-B──────────────────────┐
│                              │    │                              │
│  ┌─────┐  ┌─────┐           │    │  ┌─────┐  ┌─────┐           │
│  │ VM1 │  │ VM2 │           │    │  │ VM3 │  │ VM4 │           │
│  └──┬──┘  └──┬──┘           │    │  └──┬──┘  └──┬──┘           │
│     │        │              │    │     │        │              │
│     └──┬─────┘              │    │     └──┬─────┘              │
│        │                    │    │        │                    │
│  ┌─────▼──────┐             │    │  ┌─────▼──────┐             │
│  │ br0        │             │    │  │ br0        │             │
│  │ (Linux br) │             │    │  │ (Linux br) │             │
│  └──┬─────────┘             │    │  └──┬─────────┘             │
│     │                       │    │     │                       │
│  ┌──▼──────────┐            │    │  ┌──▼──────────┐            │
│  │ vxlan42     │            │    │  │ vxlan42     │            │
│  │ (VTEP id 42)│            │    │  │ (VTEP id 42)│            │
│  └──┬──────────┘            │    │  └──┬──────────┘            │
│     │                       │    │     │                       │
│  ┌──▼──────┐                │    │  ┌──▼──────┐                │
│  │ eth0    │                │    │  │ eth0    │                │
│  │ 10.0.0.1│                │    │  │ 10.0.0.2│                │
│  └─────────┘                │    │  └─────────┘                │
│         │                   │    │         │                   │
└─────────┼───────────────────┘    └─────────┼───────────────────┘
          │            VXLAN tunnel            │
          │          UDP :4789 VNI=42          │
          └─────────────────────────────────────┘
```

**Host A Setup:**
```bash
# Create bridge
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Create VXLAN interface
sudo ip link add vxlan42 type vxlan \
  id 42 \
  dstport 4789 \
  local 10.0.0.1 \
  dev eth0 \
  nolearning

# Add VXLAN to bridge
sudo ip link set vxlan42 master br0
sudo ip link set vxlan42 up

# Add physical ports (from VMs/containers)
sudo ip link set veth-vm1 master br0
sudo ip link set veth-vm2 master br0

# Add the remote VTEP FDB entry manually
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan42 dst 10.0.0.2

# Verify
sudo bridge fdb show br0
sudo bridge fdb show dev vxlan42
```

**Host B Setup:**
```bash
# Same as Host A but with local=10.0.0.2 and dst=10.0.0.1
sudo ip link add br0 type bridge
sudo ip link set br0 up

sudo ip link add vxlan42 type vxlan \
  id 42 \
  dstport 4789 \
  local 10.0.0.2 \
  dev eth0 \
  nolearning

sudo ip link set vxlan42 master br0
sudo ip link set vxlan42 up
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan42 dst 10.0.0.1
```

### Multicast vs Unicast VXLAN

| Aspect | Multicast | Unicast |
|--------|-----------|---------|
| **Discovery** | Automatic (IGMP) | Manual FDB entries or EVPN |
| **BUM traffic** | Via multicast group | Head-end replication or EVPN |
| **Network requirement** | IP multicast enabled | Standard IP routing |
| **Scalability** | Limited by multicast | Virtually unlimited |
| **Use case** | Small deployments | Large datacenters |

### VTEP Auto-Discovery

For a full mesh without multicast, you need either:
1. **Static FDB entries** — manual or via orchestration
2. **EVPN (MP-BGP)** — BGP distributes VTEP addresses and MAC/IP bindings
3. **VXLAN flood learning** — VXLAN kernel driver learns remote VTEPs from data plane (but this requires multicast or configured remote)

```bash
# Static FDB entries
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan42 dst 10.0.0.2
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan42 dst 10.0.0.3
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan42 dst 10.0.0.4

# With learning disabled, you must also add specific MAC addresses
sudo bridge fdb append aa:bb:cc:dd:ee:01 dev vxlan42 dst 10.0.0.2
sudo bridge fdb append aa:bb:cc:dd:ee:02 dev vxlan42 dst 10.0.0.3
```

### Use Case: Multi-Tenant Networking

```bash
# Tenant 1 (VNI 1001)
sudo ip link add vxlan1001 type vxlan id 1001 dstport 4789 dev eth0

# Tenant 2 (VNI 1002)
sudo ip link add vxlan1002 type vxlan id 1002 dstport 4789 dev eth0

# Assign IPs from different subnets
sudo ip addr add 10.100.1.1/24 dev vxlan1001
sudo ip addr add 10.100.2.1/24 dev vxlan1002

# Each tenant gets its own isolated VNI — traffic never crosses between them
```

---

## 🔍 Section 11: Building Overlays — VXLAN + FRR (BGP EVPN)

### EVPN Overview

EVPN (Ethernet VPN) uses BGP to distribute MAC address reachability across a VXLAN fabric. Instead of flooding to learn MACs, each VTEP advertises its locally-learned MAC addresses via BGP.

```
┌─Spine──────────────────────────────────────────────────────────────────┐
│  BGP Route Reflector (optional)                                         │
└────────────┬──────────────────────────────────────┬─────────────────────┘
             │ BGP EVPN NLRI                         │ BGP EVPN NLRI
             │                                        │
┌────────────▼──────────────┐      ┌─────────────────▼────────────────────┐
│ Leaf-1 (VTEP)             │      │ Leaf-2 (VTEP)                       │
│ 10.0.0.1                  │      │ 10.0.0.2                            │
│                           │      │                                      │
│ VNI 1001:                  │      │ VNI 1001:                            │
│   MAC-A → 10.0.0.1         │◄────►│   MAC-B → 10.0.0.2                  │
│ Advertises:                │      │ Advertises:                          │
│   MAC-A → 10.0.0.1 via BGP│      │   MAC-B → 10.0.0.2 via BGP           │
└────────────────────────────┘      └─────────────────────────────────────┘
```

### FRR (Free Range Routing) Configuration

**Install FRR:**
```bash
# Ubuntu/Debian
sudo apt install frr frr-pythontools

# Enable BGP daemon
sudo sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
sudo systemctl enable frr
sudo systemctl restart frr
```

**FRR Configuration for EVPN/VXLAN:**

`/etc/frr/frr.conf` on Leaf-1:
```
!
router bgp 65001
  bgp router-id 10.0.0.1
  bgp bestpath as-path multipath-relax
  neighbor 10.0.0.100 remote-as 65000      # Spine / Route Reflector
  neighbor 10.0.0.100 update-source 10.0.0.1
  !
  address-family l2vpn evpn
    neighbor 10.0.0.100 activate
    advertise-all-vni
    advertise-subnet
  exit-address-family
!
```

`/etc/frr/frr.conf` on Leaf-2:
```
router bgp 65002
  bgp router-id 10.0.0.2
  neighbor 10.0.0.100 remote-as 65000
  neighbor 10.0.0.100 update-source 10.0.0.2
  !
  address-family l2vpn evpn
    neighbor 10.0.0.100 activate
    advertise-all-vni
    advertise-subnet
  exit-address-family
!
```

### Anycast Gateways

For seamless VM/container mobility, use the same gateway IP across all VTEPs:

```bash
# On every leaf:
sudo ip addr add 10.100.1.1/24 dev vxlan1001
# This IP is the same on every leaf (anycast)
# The leaf that owns the MAC will respond to ARP/ND
# BGP EVPN distributes the MAC-to-VTEP mapping
```

The combination of VXLAN + EVPN with anycast gateways enables:
- VM mobility (vMotion) without IP address changes
- Active-active load balancing across multiple VTEPs
- Subnet extension across the entire fabric

---

## 🔍 Section 12: Performance and Tuning

### eBPF Overhead

| Hook | Typical Latency | Description |
|------|-----------------|-------------|
| XDP (native) | 10-50 ns | Pre-skb, in driver |
| XDP (generic) | 200-500 ns | Post-skb, any driver |
| tc egress | 50-100 ns | After skb allocation |
| tc ingress | 50-100 ns | After GRO |
| kprobe | 100-500 ns | Dynamic tracing |
| tracepoint | 50-200 ns | Static tracing |

```bash
# Measure XDP overhead with bpftrace
sudo bpftrace -e 'tracepoint:xdp:xdp_bulk_tx {@lat = hist(args->sent);}'
```

### XDP Driver vs Generic vs Native Mode

```bash
# Check if driver supports native XDP
sudo ethtool -i eth0 | grep driver
# Look up driver support:
# ixgbe, i40e, mlx5, nfp, virtio_net (partial), veth — native XDP
# All others — generic mode

# Force native mode
sudo ip link set dev eth0 xdp obj prog.o
# Check mode:
sudo ip -d link show eth0
# Look for: xdp: progs/id:123

# Driver mode shows: xdp: progs/id:123
# Generic mode shows: xdpgeneric/id:123

# Benchmark XDP throughput
# Use pktgen for packet generation and measure drops
```

### WireGuard Performance vs IPsec/OpenVPN

```bash
# Benchmark WireGuard throughput
# Server A (WireGuard) → Server B
# On server A:
iperf3 -s

# On server B:
iperf3 -c 10.99.99.1 -t 30

# Compare with:
# IPsec: iperf3 -c 10.99.98.1 -t 30
# OpenVPN: iperf3 -c 10.99.97.1 -t 30

# Typical results (10 Gbps link):
# WireGuard: 8.5-9.5 Gbps (kernel module)
# IPsec:     6.0-8.0 Gbps (depends on offload)
# OpenVPN:   0.5-1.5 Gbps (userspace, TCP over TCP issues)

# CPU usage comparison:
# WireGuard: ~15% of one core at 1 Gbps
# IPsec:     ~25% of one core at 1 Gbps
# OpenVPN:   ~80% of one core at 1 Gbps
```

WireGuard performance advantages:
- Kernel module (no context switching)
- ChaCha20Poly1305 is fast on modern CPUs (hardware-accelerated on some)
- Simple codebase (4,000 lines vs OpenVPN's 100,000+)
- No userspace-to-kernel transitions for data path

### VXLAN MTU Considerations

```
Physical MTU:    1500 (standard Ethernet)
VXLAN overhead:  50 bytes (20 outer IP + 8 UDP + 8 VXLAN + 14 inner MAC)

Effective MTU:   1450 (1500 - 50)
With VLAN:       1436 (1500 - 50 - 4 VLAN tag)
With PPPoE:      1442 (1492 - 50)

Recommended MTU on VXLAN interface: 1450
```

```bash
# Set proper MTU on VXLAN
sudo ip link set vxlan0 mtu 1450

# If physical network supports jumbo frames (9000):
sudo ip link set eth0 mtu 9000
sudo ip link set vxlan0 mtu 8950  # 9000 - 50

# Verify path MTU
# From a VM over VXLAN:
ping -M do -c 3 -s 1422 10.100.1.2  # 1422 + 28 (ICMP) = 1450
```

### GRO/GSO/TSO Offload Impact

These offload features can conflict with XDP and WireGuard:

```bash
# Check offload settings
sudo ethtool -k eth0

# Common offloads:
# tx-tcp-segmentation: on  (TSO)
# generic-segmentation-offload: on  (GSO)
# generic-receive-offload: on  (GRO)
# rx-vlan-offload: on

# XDP requires GRO to be off or adjusted in some drivers
# Some WireGuard issues with TSO: disable if you see corruption
sudo ethtool -K eth0 tx-udp_tnl-segmentation off

# For XDP with VXLAN, disable offloads that interfere:
sudo ethtool -K eth0 gro off gso off tso off

# Check with:
sudo ip -d link show vxlan0
```

### General Tuning Recommendations

```bash
# Increase UDP receive buffer size (for VXLAN)
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400

# Increase max backlog
sudo sysctl -w net.core.netdev_max_backlog=5000

# RPS (Receive Packet Steering) for spreading across CPUs
echo ffff | sudo tee /sys/class/net/eth0/queues/rx-0/rps_cpus

# XPS (Transmit Packet Steering)
echo ffff | sudo tee /sys/class/net/eth0/queues/tx-0/xps_cpus

# For Cilium: tune eBPF map sizes
cilium config set bpf-map-dynamic-size-ratio 0.0025

# For WireGuard: increase number of peers per interface
# (default max is 1M, but 500+ peers may need larger crypto memory)
sysctl -w net.core.wmem_max=8388608
```

---

## 👨‍🍳 15 Hands-On Practices

### Practice 1: Install bpftool and bpftrace, Run execsnoop and opensnoop

```bash
# Step 1: Install tools
sudo apt update
sudo apt install -y linux-tools-$(uname -r) bpftool bpftrace

# Step 2: Check kernel support
sudo bpftool feature | grep -E "eBPF|BPF"
uname -r

# Step 3: Run execsnoop (monitor new processes)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }'

# In another terminal, run: ls, cat, etc.

# Step 4: Run opensnoop (monitor file opens)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }'

# Step 5: Save output to file
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%-10u %-16s %s\\n", pid, comm, str(args->filename)); }' > execsnoop.log &
sleep 10
kill %1
cat execsnoop.log
```

### Practice 2: Write bpftrace One-Liner to Count Syscalls by Process

```bash
# One-liner that counts total syscalls per process name
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); } interval:s:10 { print(@); clear(@); }'

# More detailed: show PID and COMM
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[pid, comm, probe] = count(); } interval:s:5 { printf("\\nTop syscalls:\\n"); print(@, 10); clear(@); }'

# Count specific syscall (e.g., read, write)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_read { @reads[comm] = count(); } tracepoint:syscalls:sys_enter_write { @writes[comm] = count(); } interval:s:10 { printf("Reads:\\n"); print(@reads); printf("\\nWrites:\\n"); print(@writes); clear(@reads); clear(@writes); }'

# Practical: find which process is doing the most I/O
sudo bpftrace -e 'kprobe:vfs_read { @[comm] = count(); } interval:s:5 { printf("\\nTop I/O processes:\\n"); print(@, 5); clear(@); }'
```

### Practice 3: Write XDP Program to Drop Packets on a Specific Port

```bash
# Create the XDP program
cat > xdp_drop.c << 'XDPEOF'
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <bpf/bpf_endian.h>

SEC("xdp")
int xdp_drop_prog(struct xdp_md *ctx)
{
    void *data_end = (void *)(unsigned long)ctx->data_end;
    void *data = (void *)(unsigned long)ctx->data;
    struct ethhdr *eth = data;

    if (eth + 1 > data_end)
        return XDP_PASS;

    if (bpf_ntohs(eth->h_proto) != ETH_P_IP)
        return XDP_PASS;

    struct iphdr *ip = data + sizeof(*eth);
    if (ip + 1 > data_end)
        return XDP_PASS;

    if (ip->protocol != IPPROTO_TCP)
        return XDP_PASS;

    struct tcphdr *tcp = (void *)ip + sizeof(*ip);
    if (tcp + 1 > data_end)
        return XDP_PASS;

    if (tcp->dest == bpf_htons(9090))
        return XDP_DROP;

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
XDPEOF

# Compile
clang -O2 -target bpf -c xdp_drop.c -o xdp_drop.o

# Verify with llvm-objdump
llvm-objdump -d xdp_drop.o

# Load on test interface (use veth pair for safety)
sudo ip link set dev eth0 xdp obj xdp_drop.o

# Verify
sudo ip -d link show eth0 | grep xdp
sudo bpftool prog list | grep xdp

# Test with nc or curl
echo "test" | nc -w1 localhost 9090  # Should be dropped

# Remove
sudo ip link set dev eth0 xdp off
```

### Practice 4: Install Cilium on a kind/k3s Cluster

```bash
# Step 1: Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/

# Step 2: Create kind cluster
cat <<'EOF' | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: "none"
EOF

# Step 3: Install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

# Step 4: Install Cilium with kube-proxy replacement
cilium install \
  --set kubeProxyReplacement=true \
  --set ipam.mode=kubernetes

# Step 5: Wait for Cilium to be ready
cilium status --wait

# Step 6: Run connectivity test
cilium connectivity test

# Verify no kube-proxy pods
kubectl -n kube-system get pods | grep proxy
```

### Practice 5: Create Cilium Network Policies

```bash
# Deploy test applications
kubectl create deployment nginx --image=nginx
kubectl create deployment busybox --image=busybox -- sleep 3600
kubectl expose deployment nginx --port=80

# Step 1: Deny-all ingress policy
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: nginx
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: nginx
EOF

# Test: should fail
kubectl exec deploy/busybox -- wget -O- http://nginx 2>&1
# Expected: connection timeout

# Step 2: Allow specific pod-to-pod
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-busybox-to-nginx
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: nginx
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: busybox
      toPorts:
        - ports:
            - port: "80"
              protocol: TCP
EOF

# Test: should succeed
kubectl exec deploy/busybox -- wget -O- http://nginx 2>&1

# Step 3: FQDN egress policy
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-egress-fqdn
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: busybox
  egress:
    - toFQDNs:
        - matchName: example.com
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
EOF

# Test: can reach example.com but not other sites
kubectl exec deploy/busybox -- wget -O- https://example.com 2>&1
kubectl exec deploy/busybox -- wget -O- https://google.com 2>&1
```

### Practice 6: Use hubble CLI to Observe Flows

```bash
# Enable Hubble
cilium hubble enable

# Wait for Hubble to be ready
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-relay

# Port-forward Hubble
cilium hubble port-forward &

# Set hubble address
export HUBBLE_SERVER=127.0.0.1:4245

# Observe all flows
hubble observe

# Observe only flows involving a specific pod
hubble observe --pod nginx

# Observe dropped packets
hubble observe --verdict DROPPED

# Observe HTTP flows (if L7 policy is applied)
hubble observe --protocol http

# Observe flows in JSON format
hubble observe -o json --last 100

# Follow live flows
hubble observe -f

# Filter by service
hubble observe --service default/nginx

# Filter by namespace
hubble observe --namespace default

# Show flows since 5 minutes ago
hubble observe --since 5m

# Count flows by protocol
hubble observe -o json --last 1000 | jq -r '.l4 | keys[]' | sort | uniq -c
```

### Practice 7: Set Up WireGuard Tunnel Between Two Linux Servers

```bash
# On Server A (203.0.113.1)
sudo apt install wireguard
umask 077
wg genkey | tee server-a-private.key | wg pubkey > server-a-public.key

# Config /etc/wireguard/wg0.conf
sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = 10.99.99.1/30
PrivateKey = '$(cat server-a-private.key)'
ListenPort = 51820

[Peer]
PublicKey = <server-b-public>
AllowedIPs = 10.99.99.2/32
Endpoint = 203.0.113.2:51820
PersistentKeepalive = 25
WGEOF'

# On Server B (203.0.113.2)
sudo apt install wireguard
umask 077
wg genkey | tee server-b-private.key | wg pubkey > server-b-public.key

sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = 10.99.99.2/30
PrivateKey = '$(cat server-b-private.key)'
ListenPort = 51820

[Peer]
PublicKey = <server-a-public>
AllowedIPs = 10.99.99.1/32
Endpoint = 203.0.113.1:51820
PersistentKeepalive = 25
WGEOF'

# Start on both
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Verify
sudo wg show
ping -c 3 10.99.99.2  # from A
ping -c 3 10.99.99.1  # from B
```

### Practice 8: Configure WireGuard as a VPN Client

```bash
# VPN Client (your laptop)
sudo apt install wireguard
umask 077
wg genkey | tee client-private.key | wg pubkey > client-public.key

# /etc/wireguard/wg0.conf
sudo bash -c 'cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
Address = 10.99.99.100/24
PrivateKey = '$(cat client-private.key)'
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = <vpn-server-public>
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
WGEOF'

# Start
sudo wg-quick up wg0

# Verify all traffic goes through VPN
curl ifconfig.me
# Should show the VPN server's IP

# Check routes
ip route show table 51820

# Check that it works:
ping 10.99.99.1
ping 1.1.1.1

# Stop
sudo wg-quick down wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0
```

### Practice 9: Create a VXLAN Interface Between Two Namespaces

```bash
# This practice uses network namespaces instead of separate hosts

# Create namespaces
sudo ip netns add ns1
sudo ip netns add ns2

# Create a veth pair to connect namespaces to the host
sudo ip link add veth1 type veth peer name veth1-br
sudo ip link add veth2 type veth peer name veth2-br

# Move one end into each namespace
sudo ip link set veth1 netns ns1
sudo ip link set veth2 netns ns2

# Create a bridge in the host
sudo ip link add br-vxlan type bridge
sudo ip link set br-vxlan up

# Attach veth pairs to bridge
sudo ip link set veth1-br master br-vxlan
sudo ip link set veth1-br up
sudo ip link set veth2-br master br-vxlan
sudo ip link set veth2-br up

# Create VXLAN interfaces inside each namespace
sudo ip netns exec ns1 ip link add vxlan1 type vxlan id 100 remote 10.0.0.2 local 10.0.0.1 dstport 4789 dev lo
sudo ip netns exec ns2 ip link add vxlan1 type vxlan id 100 remote 10.0.0.1 local 10.0.0.2 dstport 4789 dev lo

# Bring up and assign IPs
sudo ip netns exec ns1 ip addr add 10.10.0.1/24 dev vxlan1
sudo ip netns exec ns2 ip addr add 10.10.0.2/24 dev vxlan1
sudo ip netns exec ns1 ip link set vxlan1 up
sudo ip netns exec ns2 ip link set vxlan1 up

# Test
sudo ip netns exec ns1 ping -c 3 10.10.0.2

# Clean up
sudo ip netns del ns1
sudo ip netns del ns2
sudo ip link del br-vxlan
```

### Practice 10: Bridge VXLAN with Linux Bridge for L2 Extension

```bash
# On Host A (10.0.0.1)
# Create bridge
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Create VXLAN interface
sudo ip link add vxlan0 type vxlan id 100 dstport 4789 local 10.0.0.1 dev eth0 nolearning

# Add VXLAN to bridge
sudo ip link set vxlan0 master br0
sudo ip link set vxlan0 up

# Add a container or VM veth
sudo ip link add veth-internal type veth peer name veth-internal-peer
sudo ip link set veth-internal-peer master br0
sudo ip link set veth-internal-peer up
sudo ip addr add 10.100.0.1/24 dev veth-internal

# Add remote VTEP (Host B at 10.0.0.2)
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.2

# Verify
bridge fdb show dev vxlan0

# On Host B (10.0.0.2)
sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip link add vxlan0 type vxlan id 100 dstport 4789 local 10.0.0.2 dev eth0 nolearning
sudo ip link set vxlan0 master br0
sudo ip link set vxlan0 up
sudo ip addr add 10.100.0.2/24 dev veth-internal
sudo bridge fdb append 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.1

# Test L2 connectivity
ping -c 3 10.100.0.2  # from Host A
# Ping MAC addresses:
arping -c 3 10.100.0.2
```

### Practice 11: Deploy Cilium with WireGuard Encryption

```bash
# Prerequisites: kind or existing K8s cluster

# Install Cilium with WireGuard encryption
cilium install \
  --set kubeProxyReplacement=true \
  --set encryption.enabled=true \
  --set encryption.type=wireguard

# Wait for rollout
cilium status --wait

# Verify WireGuard is active
cilium status | grep -i encrypt

# List WireGuard peers
cilium encrypt status

# Check the WireGuard interface
kubectl -n kube-system exec -it daemonset/cilium -- ip link show cilium_wg0

# Verify traffic is encrypted
# On a node:
sudo tcpdump -i any -nn port 51820
# You should see WireGuard traffic between nodes

# Deploy test pods
kubectl create deployment test-a --image=nginx
kubectl create deployment test-b --image=busybox -- sleep 3600
kubectl expose deployment test-a --port=80

# Test connectivity
kubectl exec -it deploy/test-b -- wget -O- http://test-a.default

# Verify encryption with Hubble
hubble observe --pod test-b --pod test-a
```

### Practice 12: Benchmark WireGuard vs iperf3

```bash
# Server side (WireGuard endpoint)
# First, set up a WireGuard tunnel between two machines
# (see Practice 7 for setup)

# On the remote server:
iperf3 -s

# On the local machine through WireGuard:
iperf3 -c 10.99.99.2 -t 30 -P 4

# Compare with direct connection (no VPN):
iperf3 -c 203.0.113.2 -t 30 -P 4

# Compare UDP throughput
iperf3 -c 10.99.99.2 -u -b 1000M -t 30

# Measure CPU usage during benchmark
# In separate terminal:
top -p $(pgrep -d',' -x wg-quick) -b -d 2

# Test with different MTU sizes
# Change MTU on wg0:
sudo ip link set wg0 mtu 1280
iperf3 -c 10.99.99.2 -t 30

# Test latency
ping -c 100 10.99.99.2 | tail -2
# Compare:
ping -c 100 203.0.113.2 | tail -2
```

### Practice 13: Set Up Hubble UI to Visualize Service Map

```bash
# Step 1: Enable Hubble UI
cilium hubble enable --ui

# Wait for UI pod
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-ui

# Step 2: Port-forward to access UI
cilium hubble ui &

# Or manually:
kubectl -n kube-system port-forward service/hubble-ui 12000:80

# Open browser to http://localhost:12000

# Step 3: Generate traffic to see the service map
kubectl run -it --rm load-generator --image=busybox -- /bin/sh
# Inside the pod:
while true; do wget -q -O- http://nginx.default; sleep 0.5; done

# Step 4: Observe in Hubble UI
# - Service Map tab: see real-time graph
# - Flow tab: see individual flows
# - Click on pods to inspect their traffic

# Step 5: Add L7 policy to see HTTP flows
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: hubble-l7-visibility
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: nginx
  ingress:
    - toPorts:
        - ports:
            - port: "80"
              protocol: TCP
          rules:
            http:
              - method: GET
EOF

# Now Hubble UI will show L7 information (HTTP methods, paths, status codes)
```

### Practice 14: Create Cilium L7 Policy to Restrict HTTP Paths

```bash
# Deploy a backend service with different paths
kubectl create deployment httpbin --image=mccutchen/go-httpbin
kubectl expose deployment httpbin --port=8080
kubectl create deployment curl-pod --image=curlimages/curl -- sleep 3600

# Test unrestricted access
kubectl exec curl-pod -- curl -s http://httpbin:8080/get
kubectl exec curl-pod -- curl -s http://httpbin:8080/post -X POST
kubectl exec curl-pod -- curl -s http://httpbin:8080/delete -X DELETE
kubectl exec curl-pod -- curl -s http://httpbin:8080/status/500

# Apply L7 policy restricting paths
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-httpbin
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: httpbin
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: curl-pod
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/get"
              - method: GET
                path: "/status/200"
              - method: POST
                path: "/post"
EOF

# Test allowed paths
kubectl exec curl-pod -- curl -s http://httpbin:8080/get
kubectl exec curl-pod -- curl -s http://httpbin:8080/status/200
kubectl exec curl-pod -- curl -s http://httpbin:8080/post -X POST

# Test denied paths
kubectl exec curl-pod -- curl -s http://httpbin:8080/delete -X DELETE
kubectl exec curl-pod -- curl -s http://httpbin:8080/status/500
kubectl exec curl-pod -- curl -s http://httpbin:8080/anything

# Observe dropped requests in Hubble
hubble observe --pod httpbin --verdict DROPPED
```

### Practice 15: Real-World Integration — Multi-Node Kubernetes with Cilium

```bash
# ┌────────────────────────────────────────────────────────────────────────┐
# │ REAL-WORLD INTEGRATION                                                 │
# │                                                                        │
# │ Deploy a multi-node Kubernetes cluster with:                           │
# │   • Cilium with eBPF networking (kube-proxy replacement)               │
# │   • CiliumNetworkPolicies (L3/L4/L7)                                   │
# │   • Hubble observability (service map + flow logs)                     │
# │   • WireGuard encryption (pod-to-pod traffic encrypted)                │
# │   • VXLAN overlay (if using Cilium in tunneling mode)                  │
# └────────────────────────────────────────────────────────────────────────┘

# Step 1: Create multi-node kind cluster
cat <<'EOF' | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: "none"
EOF

# Step 2: Install Cilium with all features
cilium install \
  --set kubeProxyReplacement=true \
  --set encryption.enabled=true \
  --set encryption.type=wireguard \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Wait for everything
cilium status --wait

# Step 3: Verify the setup
echo "=== Cilium Status ==="
cilium status

echo "=== Encryption ==="
cilium encrypt status

echo "=== Hubble ==="
cilium hubble status

# Step 4: Deploy microservices
kubectl create deployment frontend --image=nginx
kubectl create deployment api-server --image=mccutchen/go-httpbin
kubectl create deployment db --image=postgres:13-alpine --env="POSTGRES_PASSWORD=test"
kubectl expose deployment frontend --port=80
kubectl expose deployment api-server --port=8080
kubectl expose deployment db --port=5432

# Step 5: Apply defense-in-depth policies

# Default deny-all for all services
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  endpointSelector:
    matchLabels: {}
  ingress:
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
            - port: "53"
              protocol: TCP
  egress:
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
            - port: "53"
              protocol: TCP
EOF

# Allow frontend → api-server (L7 aware)
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: frontend-to-api
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/get"
              - method: GET
                path: "/status/200"
              - method: POST
                path: "/post"
EOF

# Allow api-server → db
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-to-db
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: db
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: api-server
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
EOF

# Allow egress to external API (FQDN based)
cat <<'EOF' | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-egress-external
  namespace: default
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  egress:
    - toFQDNs:
        - matchPattern: "*.example.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
EOF

# Step 6: Test connectivity
echo "=== Testing frontend → api-server ==="
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s http://frontend:80/

echo "=== Testing api-server → db ==="
kubectl exec -it deploy/api-server -- sh -c \
  'apt-get update && apt-get install -y postgresql-client && \
   PGPASSWORD=test psql -h db -U postgres -c "\\l"'

# Step 7: Observe with Hubble
echo "=== Hubble Flow Log ==="
cilium hubble port-forward &
sleep 2
hubble observe --since 5m --verdict FORWARDED | head -20

echo "=== Hubble Dropped Flows ==="
hubble observe --since 5m --verdict DROPPED

# Step 8: Verify WireGuard encryption
echo "=== WireGuard Peers ==="
kubectl -n kube-system exec daemonset/cilium -- wg show

# Step 9: Access Hubble UI
echo "=== Hubble UI available at: ==="
echo "http://localhost:12000"
kubectl -n kube-system port-forward service/hubble-ui 12000:80 &

echo "=== Integration Complete ==="
echo "Multi-node Kubernetes cluster with:"
echo "  eBPF datapath (no iptables)"
echo "  kube-proxy replacement"
echo "  CiliumNetworkPolicies (L3/L4/L7)"
echo "  Hubble observability"
echo "  WireGuard encryption"
echo "  FQDN-based egress policies"
```

---

## 🧠 Deep Understanding

### How eBPF Works Step-by-Step

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. C Source Code                                                       │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ int xdp_func(struct xdp_md *ctx) { return XDP_PASS; }         │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 2. clang -O2 -target bpf                                               │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ Compiles to ELF with .text section containing BPF bytecode     │   │
│    │ Uses BPF backend (llvm/lib/Target/BPF)                        │   │
│    │ Produces BPF instructions (opcodes, dst/src regs, offset)     │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 3. BPF Bytecode                                                        │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ 0: (b7) r0 = 2     // XDP_PASS = 2                          │   │
│    │ 1: (95) exit        // return r0                             │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 4. bpf() syscall — BPF_PROG_LOAD                                       │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ union bpf_attr attr = {                                       │   │
│    │   .prog_type = BPF_PROG_TYPE_XDP,                            │   │
│    │   .insns = ptr_to_u64(insns),                                │   │
│    │   .insn_cnt = 2,                                             │   │
│    │   .license = "GPL"                                           │   │
│    │ };                                                             │   │
│    │ int fd = bpf(BPF_PROG_LOAD, &attr, sizeof(attr));            │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 5. Verifier                                                            │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ Kernel's BPF verifier (kernel/bpf/verifier.c) walks the       │   │
│    │ control flow graph (CFG) of the program:                     │   │
│    │                                                               │   │
│    │ 1. Creates a directed acyclic graph (DAG) of instructions    │   │
│    │ 2. Simulates execution with abstract values (each reg has     │   │
│    │    a "type": scalar, pointer-to-packet, pointer-to-map, etc.) │   │
│    │ 3. Checks that:                                               │   │
│    │    a) No out-of-bounds memory access                          │   │
│    │       (data + offset < data_end is enforced)                 │   │
│    │    b) No unreachable instructions                             │   │
│    │    c) No loops (or bounded loops < BPF_MAX_LOOPS)             │   │
│    │    d) Stack boundaries respected                              │   │
│    │    e) Return type matches program type                        │   │
│    │    f) Map access types match (read-only maps not written)     │   │
│    │                                                               │   │
│    │ If program passes verifier → JIT                              │   │
│    │ If program fails → EACCES with verifier log message           │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 6. JIT Compilation                                                     │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ Kernel's BPF JIT (arch/x86/net/bpf_jit_comp.c for x86_64):   │   │
│    │                                                               │   │
│    │ BPF instruction → x86_64 machine code:                       │   │
│    │   (b7) r0 = 2    →  mov eax, 2                             │   │
│    │   (95) exit       →  ret                                     │   │
│    │                                                               │   │
│    │ Also does:                                                    │   │
│    │   • Register mapping (BPF regs → x86_64 regs)                │   │
│    │   • Dead code elimination                                    │   │
│    │   • Constant propagation                                      │   │
│    │   • Tail-call optimization                                    │   │
│    │   • The JIT output is cached and reused for all attachments   │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 7. Attach to Hook                                                      │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ Depending on program type, attach differently:                │   │
│    │                                                               │   │
│    │ XDP:    ip link set dev eth0 xdp fd <fd>                     │   │
│    │ TC:     tc filter add dev eth0 ingress bpf da obj prog.o     │   │
│    │ kprobe: /sys/kernel/debug/tracing/kprobe_events              │   │
│    │ tracepoint: /sys/kernel/debug/tracing/events/.../enable     │   │
│    │                                                               │   │
│    │ Each hook has a struct bpf_prog pointer that the kernel       │   │
│    │ calls at the appropriate point in the code path.             │   │
│    └───────────────────────────────────────────────────────────────┘   │
│                          │                                              │
│ 8. Maps (Shared State)                                                 │
│    ┌───────────────────────────────────────────────────────────────┐   │
│    │ Creating: bpf(BPF_MAP_CREATE) → map_fd                       │   │
│    │ Accessing in BPF: bpf_map_lookup_elem(&map, &key) via helper │   │
│    │ Accessing in userspace: bpf(BPF_MAP_LOOKUP_ELEM, map_fd...)  │   │
│    │                                                               │   │
│    │ Maps are per-CPU or global, shared between:                   │   │
│    │   • Multiple BPF programs                                     │   │
│    │   • BPF programs and userspace daemons                        │   │
│    │   • Different BPF hooks (e.g., XDP + tc sharing an LRU hash) │   │
│    └───────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### How Cilium's eBPF Datapath Replaces kube-proxy

Traditional Kubernetes use `iptables` (or `ipvs`) to implement Service IP translation. The problem: every new Service adds more iptables rules, and every packet traverses the full chain.

```
Traditional iptables (kube-proxy):
──────────────────────────────────

Packet from Pod A to Service 10.96.0.10:80:

1. PREROUTING chain (raw)
2. PREROUTING chain (nat)
3. KUBE-SERVICES chain:
   - Match 10.96.0.10:80 → jump to KUBE-SVC-XXXXX
4. KUBE-SVC-XXXXX chain:
   - 50% → KUBE-SEP-A (pod-a:8080)
   - 50% → KUBE-SEP-B (pod-b:8080)
5. FORWARD chain
6. POSTROUTING chain
7. OUTPUT chain

Total: O(n) where n = number of services/endpoints
```

Cilium's eBPF approach:

```
Cilium eBPF datapath:
──────────────────────

Packet from Pod A:
       │
       ▼
    ┌────────────────┐
    │ eBPF program   │
    │ (tc ingress)   │
    └───────┬────────┘
            │
            ▼
    ┌────────────────────────────────────────────┐
    │ bpf_map_lookup_elem(lb4_service, &key)     │
    │                                            │
    │ key = {ip: 10.96.0.10, port: 80, proto: 6}│
    │                                            │
    │ result = backend_ip: 10.0.2.7:8080        │
    │           (direct from BPF_MAP_TYPE_HASH)  │
    └────────────────────────────────────────────┘
            │
            ▼
    ┌────────────────┐
    │ Rewrite dst IP │
    │ and port       │
    │ in xdp_md     │
    └───────┬────────┘
            │
            ▼
    ┌────────────────┐
    │ Redirect via   │
    │ XDP_TX or      │
    │ tc redirect    │
    └────────────────┘
            │
            ▼
    Packet delivered to Pod B

Total: O(1) — single hash table lookup
```

The BPF map `lb4_service` is populated by the Cilium agent whenever Services or Endpoints change:

```bash
# Inspect the service BPF maps
cilium bpf service list

# Example output:
# 10.96.0.10:80 (1) 10.0.2.7:8080 (1)
#                   10.0.2.8:8080 (1)
# 10.96.0.1:443 (1) 192.168.0.1:6443 (1)
```

For each service, Cilium maintains:
- `lb4_service`: service IP → list of backend IDs
- `lb4_backend`: backend ID → actual backend IP:port
- `lb4_reverse_nat`: reverse mapping for return traffic

### How WireGuard Works at the Kernel Level

WireGuard is implemented primarily in `drivers/net/wireguard/`:

```
drivers/net/wireguard/
├── main.c        — Module init, netlink interface
├── device.c      — net_device operations (xmit, open, close)
├── receive.c     — Packet reception, decryption, handshake processing
├── send.c        — Packet sending, encryption, ratelimiting
├── noise.c       — Noise protocol implementation (handshake state machine)
├── noise.h       — Noise protocol constants and data structures
├── peer.c        — Peer management (creation, destruction, timers)
├── timers.c      — Handshake timers, keepalive, key rotation
├── queueing.c    — Packet queuing (for parallel crypto)
├── ratelimit.c   — Cookie-based rate limiting
├── messages.h    — WireGuard message structs (handshake, transport)
├── crypto.c      — ChaCha20Poly1305, BLAKE2s, Curve25519 wrappers
└── selftest/     — Kernel self-tests
```

**Handshake State Machine (noise.c):**

```
STATE_START
    │
    ├─► send initiation message (msg1)
    │    │
    │    ▼
    STATE_MSG1_SENT
    │    │
    │    ◄─ receive response (msg2)
    │    │
    │    ▼
    STATE_MSG2_RECEIVED
    │    │
    │    ├─► send cookie reply (msg3)
    │    │
    │    ▼
    STATE_ESTABLISHED  ──────► key rotation timer
                               │
                               ▼
                         rekey after 120 seconds
                              (STATE_START)
```

**Data Path Encryption (send.c):**

```c
/* Simplified: WireGuard packet encryption flow */
int wg_packet_send_skb(struct sk_buff *skb, struct wg_peer *peer)
{
    // 1. Pad packet to block size (16 bytes for Poly1305)
    // 2. Construct transport header:
    //    - Type (4 bytes, always 4 for transport)
    //    - Receiver index (4 bytes, peer's session index)
    //    - Counter (8 bytes, monotonic)
    //    - Encrypted payload (ChaCha20Poly1305)
    //    - Poly1305 tag (16 bytes)
    // 3. Queue for sending via UDP socket
    // 4. UDP packet transmitted via real interface
}
```

**Data Path Decryption (receive.c):**

```c
/* Simplified: WireGuard packet decryption flow */
int wg_packet_receive_skb(struct sk_buff *skb, struct wg_device *wg)
{
    // 1. Validate UDP packet length
    // 2. Parse header: type, receiver_index, counter
    // 3. Look up peer by receiver_index in hash table
    // 4. Validate counter (replay protection)
    // 5. Decrypt with ChaCha20Poly1305 using session key
    // 6. Remove outer headers, expose inner packet
    // 7. Deliver to network stack as if locally generated
}
```

**Roaming Implementation:**

```c
/* When a packet arrives from a new source IP for an existing peer,
 * the kernel updates the peer's endpoint automatically: */
int wg_receive_incoming(struct sk_buff *skb, struct wg_device *wg)
{
    // ...
    // If packet source IP:port differs from stored endpoint:
    //   peer->endpoint.addr = new_source_address
    //   peer->endpoint.port = new_source_port
    // This happens atomically, with no handshake needed
}
```

### How VXLAN Encapsulation Works in the Kernel

The kernel VXLAN driver lives at `drivers/net/vxlan.c`.

**Encapsulation flow (vxlan_xmit → vxlan_xmit_one):**

```c
/* Simplified: VXLAN encapsulation in the kernel */
static int vxlan_xmit_one(struct sk_buff *skb, struct net_device *dev,
                          struct vxlan_rdst *rdst, bool did_ipv6)
{
    // 1. Get the VNI from the VXLAN device
    __u32 vni = vxlan->default_dst.remote_vni;

    // 2. Calculate UDP payload length
    int total_len = skb->len + sizeof(struct vxlanhdr) + ETH_HLEN;

    // 3. Set inner MAC header (original L2 frame)
    skb_set_inner_protocol(skb, htons(ETH_P_TEB));

    // 4. Prepare UDP encapsulation
    //    - Reserve headroom for outer headers
    //    - Build outer IP header
    //    - Build outer UDP header
    //    - udp_tunnel_handle_offloads(skb, ...)

    // 5. Insert VXLAN header:
    struct vxlanhdr *vxh = skb_push(skb, sizeof(struct vxlanhdr));
    vxh->vx_flags = htonl(VXLAN_HF_VNI);
    vxh->vx_vni = htonl(vni << 8);

    // 6. Finalize headers and transmit
    return udp_tunnel_xmit_skb(rdst->remote_sa, ...);
}
```

**Decapsulation flow (vxlan_udp_encap_recv → vxlan_rcv):**

```c
/* Simplified: VXLAN decapsulation in the kernel */
static int vxlan_rcv(struct sock *sk, struct sk_buff *skb)
{
    // 1. Validate UDP length
    // 2. Parse VXLAN header:
    struct vxlanhdr *vxh = (struct vxlanhdr *)(udp_hdr(skb) + 1);
    __u32 vni = ntohl(vxh->vx_vni) >> 8;

    // 3. Check that the VNI is valid
    struct vxlan_dev *vxlan = vni_to_vxlan(vni);

    // 4. Remove outer headers (IP, UDP, VXLAN)

    // 5. Set the packet's protocol to ETH_P_TEB
    skb->protocol = htons(ETH_P_TEB);

    // 6. GRO (Generic Receive Offload) to coalesce packets

    // 7. Deliver to the VXLAN net_device
    //    - If VXLAN device is part of a bridge:
    //      netif_receive_skb(skb) → bridge processing
    //    - If VXLAN device has its own IP:
    //      Deliver to IP stack
}
```

**VXLAN with GRO/GSO:**

```c
static struct udp_tunnel_ops vxlan_udp_tunnel_ops = {
    .create_sock      = vxlan_sock_add,
    .destroy_sock     = vxlan_sock_release,
    .gro_receive      = vxlan_gro_receive,
    .gro_complete     = vxlan_gro_complete,
};
```

---

## 📋 Command Reference

### eBPF / bpftool

| Command | Description |
|---------|-------------|
| `sudo bpftool prog list` | List all loaded eBPF programs |
| `sudo bpftool map list` | List all eBPF maps |
| `sudo bpftool prog dump xlated id N` | Disassemble BPF bytecode |
| `sudo bpftool prog dump jited id N` | Show JIT-compiled machine code |
| `sudo bpftool prog pin id N /sys/fs/bpf/prog` | Pin program to BPF filesystem |
| `sudo bpftool map dump id N` | Dump all entries in a map |
| `sudo bpftool map update id N key HEX value HEX` | Update a map entry |
| `sudo bpftool net list` | Show network-attached BPF programs |
| `sudo bpftool feature` | Show kernel eBPF feature support |
| `sudo mount -t bpf bpffs /sys/fs/bpf` | Mount BPF filesystem |

### bpftrace

| Command | Description |
|---------|-------------|
| `sudo bpftrace -e 'probe { action }'` | Run one-liner |
| `sudo bpftrace script.bt` | Run script file |
| `sudo bpftrace -l 'tracepoint:syscalls:*'` | List available probes |
| `sudo bpftrace -v -e '...'` | Verbose (show compilation) |
| `sudo bpftrace --btf` | Use BTF for type info |

### XDP

| Command | Description |
|---------|-------------|
| `sudo ip link set dev eth0 xdp obj prog.o` | Load XDP program (native) |
| `sudo ip link set dev eth0 xdpgeneric obj prog.o` | Load XDP (generic mode) |
| `sudo ip link set dev eth0 xdp off` | Remove XDP program |
| `sudo ip -d link show eth0` | Show XDP attachment |
| `sudo bpftool net attach xdp id N dev eth0` | Attach XDP by program ID |
| `clang -O2 -target bpf -c prog.c -o prog.o` | Compile BPF program |
| `llvm-objdump -d prog.o` | Disassemble BPF object file |

### Cilium

| Command | Description |
|---------|-------------|
| `cilium install --set kubeProxyReplacement=true` | Install Cilium |
| `cilium status` | Check Cilium status |
| `cilium connectivity test` | Run connectivity tests |
| `cilium bpf service list` | Show service-to-backend mappings |
| `cilium bpf nat list` | Show NAT table |
| `cilium bpf lb list` | Show load balancer tables |
| `cilium encrypt status` | Show encryption status |
| `cilium hubble enable --ui` | Enable Hubble with UI |
| `cilium hubble port-forward` | Port-forward Hubble |
| `cilium clustermesh enable` | Enable ClusterMesh |
| `cilium config set KEY VALUE` | Set Cilium config |

### Hubble

| Command | Description |
|---------|-------------|
| `hubble observe` | Observe all flows |
| `hubble observe --pod NAME` | Filter by pod |
| `hubble observe --namespace NS` | Filter by namespace |
| `hubble observe --verdict DROPPED` | Show only dropped packets |
| `hubble observe --protocol http` | Show only HTTP flows |
| `hubble observe --since 5m` | Flows from last 5 minutes |
| `hubble observe -o json` | JSON output |
| `hubble observe -f` | Follow mode |
| `hubble status` | Hubble connection status |

### WireGuard

| Command | Description |
|---------|-------------|
| `wg genkey` | Generate private key |
| `wg pubkey < private.key` | Derive public key from private |
| `wg genpsk` | Generate pre-shared key |
| `wg-quick up wg0` | Bring up WireGuard interface |
| `wg-quick down wg0` | Bring down WireGuard interface |
| `wg show` | Show WireGuard status |
| `wg showconf wg0` | Show full configuration |
| `wg set wg0 peer PUBKEY endpoint IP:PORT` | Update peer endpoint |
| `wg set wg0 peer PUBKEY allowed-ips CIDR` | Update allowed IPs |
| `systemctl enable wg-quick@wg0` | Enable at boot |
| `modinfo wireguard` | Check if WireGuard module exists |

### VXLAN

| Command | Description |
|---------|-------------|
| `sudo ip link add vxlan0 type vxlan id 100 dev eth0 remote 10.0.0.2` | Create VXLAN interface |
| `sudo ip link add vxlan0 type vxlan id 100 group 239.1.1.1 dev eth0` | VXLAN with multicast |
| `sudo ip -d link show vxlan0` | Show VXLAN details |
| `sudo ip link set vxlan0 mtu 1450` | Set MTU for VXLAN |
| `sudo ip link del vxlan0` | Delete VXLAN interface |
| `sudo bridge fdb show dev vxlan0` | Show FDB entries for VXLAN |
| `sudo bridge fdb append MAC dev vxlan0 dst IP` | Add FDB entry |

### Performance

| Command | Description |
|---------|-------------|
| `sudo ethtool -k eth0` | Show offload settings |
| `sudo ethtool -K eth0 gro off` | Disable GRO |
| `sudo ethtool -K eth0 tx-udp_tnl-segmentation off` | Disable UDP tunnel segmentation |
| `sudo ip link set eth0 mtu 9000` | Set jumbo frames |
| `sudo sysctl -w net.core.rmem_max=26214400` | Increase UDP buffer size |
| `iperf3 -c HOST -t 30 -P 4` | Benchmark throughput |
| `ping -M do -s 1472 HOST` | Test MTU |

---

## 🚀 What's Coming in Part 58

**Part 58: Secrets Management — Vault, SOPS, Sealed Secrets** — Modern networking needs secrets for everything: TLS certificates, database passwords, API keys, and WireGuard private keys. In Part 58 you will learn how to manage secrets in production using HashiCorp Vault (for dynamic secrets and encryption-as-a-service), SOPS (for Git-encrypted configuration files), and Sealed Secrets (for Kubernetes-native secret encryption at rest). You will also understand how Cilium's integration with Vault can automate TLS certificate distribution and WireGuard key rotation across your cluster.

Topics covered:
- Secrets management philosophy — encryption at rest vs in transit vs in use
- HashiCorp Vault architecture — seal/unseal, secret engines, auth methods
- Vault dynamic secrets for databases and cloud IAM
- SOPS — encrypted files in Git with AWS/GCP/Azure KMS or age
- Sealed Secrets — encrypting Kubernetes Secrets for safe storage in Git
- Cilium integration with Vault for automated certificate management
- WireGuard key rotation with Vault PKI
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What are the three components the eBPF verifier checks before allowing a program to run, and why is JIT compilation important for performance?

2. How does an XDP program access packet data differently from a tc program? What data structure does each receive?

3. What are the five possible return values from an XDP program, and what does each do?

4. How does Cilium's eBPF datapath achieve O(1) service translation compared to iptables O(n)?

5. In a CiliumNetworkPolicy, what is the difference between `endpointSelector`, `fromEndpoints`, `toEndpoints`, and `toFQDNs`?

6. How does an L7 Cilium policy inspect HTTP paths and methods when the traffic is encrypted with TLS?

7. What information does Hubble's service map display, and how does it collect flow data without a central aggregation bottleneck?

8. Draw the WireGuard handshake message sequence. What cryptographic primitives are used at each step?

9. How does WireGuard handle a client that changes its IP address (roaming) without re-establishing the tunnel?

10. What is the purpose of `PersistentKeepalive` in a WireGuard configuration, and what problem does it solve?

11. A VXLAN packet is received on UDP port 4789. Walk through the kernel's decapsulation steps from `eth0` to the final bridge delivery.

12. What is the MTU of a VXLAN interface if the physical link is 1500 bytes? Show the calculation including all overhead.

13. In the FRR + VXLAN (EVPN) architecture, what does BGP distribute, and how does it eliminate the need for multicast or flooding for MAC learning?

14. When Cilium encrypts pod-to-pod traffic with WireGuard, where does the encryption happen in the network path? What BPF programs are involved?

15. You have a Kubernetes cluster with 500 nodes and 10,000 services. Explain why Cilium's eBPF approach scales better than kube-proxy with iptables at this scale.

**Score:** 12/15 correct = ready for Part 58.

---

*Linux SysAdmin Course | Part 57 of ∞ | Reverse Engineering Approach*
*Previous → Part 56: Observability Deep Dive*
*Next → Part 58: Secrets Management*


[← Previous](part56.md) | [Next →](part58.md)
