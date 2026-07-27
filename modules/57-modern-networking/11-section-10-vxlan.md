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



---

[← Previous](10-section-9-wireguard-in-practice.md) | [↑ Index](index.md) | [Next →](12-section-11-building-overlays-vxlan.md)
