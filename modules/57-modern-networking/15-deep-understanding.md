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





[← Previous](14-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](16-command-reference.md)
