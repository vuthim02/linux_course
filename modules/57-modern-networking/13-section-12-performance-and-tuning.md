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





[← Previous](12-section-11-building-overlays-vxlan.md) | [↑ Index](index.md) | [Next →](14-15-hands-on-practices.md)
