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





[← Previous](03-section-2-bpftrace.md) | [↑ Index](index.md) | [Next →](05-section-4-cilium.md)
