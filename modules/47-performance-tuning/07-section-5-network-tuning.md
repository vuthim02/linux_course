## 🔍 Section 5: Network Tuning

### sysctl Network Parameters

Most network tuning is done through sysctl parameters under `net.*`.

**Socket Buffers:**

```bash
# Default socket buffer sizes
sysctl net.core.rmem_default     # default receive buffer (212992)
sysctl net.core.wmem_default     # default send buffer (212992)

# Maximum socket buffer sizes
sysctl net.core.rmem_max          # max receive buffer
sysctl net.core.wmem_max          # max send buffer

# TCP buffer sizes (min, default, max in bytes)
sysctl net.ipv4.tcp_rmem          # "4096 131072 6291456"
sysctl net.ipv4.tcp_wmem          # "4096 16384 4194304"
```

**Tuning for high-throughput network:**

```bash
# Increase max socket buffer
sudo sysctl net.core.rmem_max=134217728
sudo sysctl net.core.wmem_max=134217728

# Auto-tune TCP buffers aggressively
sudo sysctl net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl net.ipv4.tcp_wmem="4096 65536 134217728"

# Enable TCP window scaling
sudo sysctl net.ipv4.tcp_window_scaling=1

# Enable TCP timestamps (better RTT estimation)
sudo sysctl net.ipv4.tcp_timestamps=1
```

**Packet Processing:**

```bash
# netdev_budget — how many packets to process per NAPI poll
# Higher = more throughput per interrupt, higher latency
sudo sysctl net.core.netdev_budget=600

# somaxconn — max listen backlog
sudo sysctl net.core.somaxconn=65536

# tcp_max_syn_backlog — SYN flood protection buffer
sudo sysctl net.ipv4.tcp_max_syn_backlog=65536

# Enable TCP fast open
sudo sysctl net.ipv4.tcp_fastopen=3
```

### Interface Queue Length

```bash
# Check current txqueuelen
ip link show eth0 | grep qlen

# Increase for high-throughput scenarios
sudo ip link set dev eth0 txqueuelen 10000

# Make permanent in /etc/rc.local or netplan/network-scripts
```

### Ring Buffers (`ethtool -G`)

NIC ring buffers hold packets between the hardware and the kernel:

```bash
# Check current ring buffer sizes
sudo ethtool -g eth0

# Increase RX and TX ring buffers (reduces drops under load)
sudo ethtool -G eth0 rx 4096 tx 4096

# Check for packet drops
sudo ethtool -S eth0 | grep -E "(drop|discard|error)"
```

### RSS (Receive Side Scaling) with RPS/XPS

**RSS (hardware):** NIC distributes packets across multiple RX queues, each handled by a different CPU.

```bash
# Check number of RX queues
ls /sys/class/net/eth0/queues/rx-*

# Set RSS with ethtool
# Distribute to CPUs 0-3 (bitmask 0xF)
sudo ethtool -X eth0 equal 4

# Or set custom indirection table
sudo ethtool -X eth0 weight 1 1 1 1
```

**RPS (software RSS):** Distribute packet processing across CPUs when NIC doesn't support RSS:

```bash
# Enable RPS on eth0 — use CPUs 0-3
echo f | sudo tee /sys/class/net/eth0/queues/rx-0/rps_cpus

# Flow count table size
echo 4096 | sudo tee /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
```

**XPS (Transmit Packet Steering):** Spread TX processing across CPUs:

```bash
# Set XPS for TX queue 0 to use CPUs 0-3
echo f | sudo tee /sys/class/net/eth0/queues/tx-0/xps_cpus
```





[← Previous](06-section-4-disk-io-tuning.md) | [↑ Index](index.md) | [Next →](08-section-6-kernel-parameters.md)
