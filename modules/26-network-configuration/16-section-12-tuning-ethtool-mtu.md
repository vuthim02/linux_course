## 🔍 Section 12: Tuning — ethtool, MTU, Offloading, Ring Buffers

### ethtool — Query and Control Network Devices

```bash
# Install ethtool
sudo apt install ethtool

# Basic information
sudo ethtool enp0s3

# Show driver info
sudo ethtool -i enp0s3
# Output:
# driver: e1000
# version: 7.3.21-k8-NAPI
# firmware-version: 0.3-0
# bus-info: 0000:00:03.0

# Show link status and speed
sudo ethtool enp0s3 | grep -E "Speed|Duplex|Link detected"

# Show NIC capabilities
sudo ethtool -k enp0s3  # Offloading features
sudo ethtool -c enp0s3  # Coalescing settings
sudo ethtool -g enp0s3  # Ring buffer sizes
sudo ethtool -a enp0s3  # Pause parameteres
```

### Changing Settings with ethtool

```bash
# Set speed and duplex
sudo ethtool -s enp0s3 speed 1000 duplex full autoneg on

# Set ring buffer sizes
sudo ethtool -G enp0s3 rx 4096 tx 4096

# Set coalescing (interrupt moderation)
sudo ethtool -C enp0s3 rx-usecs 100 tx-usecs 100

# Set pause frames
sudo ethtool -A enp0s3 rx on tx on

# Wake-on-LAN settings
sudo ethtool -s enp0s3 wol g  # Magic packet
sudo ethtool enp0s3 | grep "Wake-on"
```

### MTU (Maximum Transmission Unit)

MTU is the largest packet size a network interface can transmit without fragmentation.

```bash
# Check current MTU
ip link show enp0s3 | grep mtu

# Set MTU to 1500 (standard Ethernet)
sudo ip link set enp0s3 mtu 1500

# Set MTU to 9000 (jumbo frames — for data centers)
sudo ip link set enp0s3 mtu 9000

# Test MTU with ping
ping -M do -s 1472 -c 3 192.168.1.1   # 1472 + 28 = 1500
ping -M do -s 8972 -c 3 192.168.1.1   # 8972 + 28 = 9000

# -M do = Don't Fragment (probe MTU)
# -s = payload size (ICMP header is 8 bytes, IP header 20)
```

### Path MTU Discovery

```bash
# Find the smallest MTU along a path
tracepath 8.8.8.8

# Use tracepath -n for faster results (no DNS)
tracepath -n 8.8.8.8 | head -10
```

### TCP Offloading

Modern NICs can offload TCP processing from the CPU:

```bash
# Show offload settings
sudo ethtool -k enp0s3

# Common offload features:
# tx-checksumming: Checksum offload for transmit
# rx-checksumming: Checksum offload for receive
# tcp-segmentation-offload (TSO): NIC splits large TCP segments
# generic-segmentation-offload (GSO): Software version of TSO
# generic-receive-offload (GRO): Merge incoming packets
# large-receive-offload (LRO): Merge incoming packets (coarse)
# rx-vlan-offload: VLAN tag stripping on receive
# tx-vlan-offload: VLAN tag insertion on transmit
```

Disable offloading for troubleshooting or specific workloads:

```bash
# Disable TSO and GSO
sudo ethtool -K enp0s3 tso off gso off

# Disable checksum offloading
sudo ethtool -K enp0s3 tx off rx off

# Disable LRO/GRO
sudo ethtool -K enp0s3 lro off gro off

# Re-enable
sudo ethtool -K enp0s3 tso on gso on tx on rx on
```

### Ring Buffer Sizes

Ring buffers hold received packets waiting for the kernel to process them:

```bash
# Show current ring buffer
sudo ethtool -g enp0s3

# Output:
# Ring parameters for enp0s3:
# Pre-set maximums:
# RX:             4096
# TX:             4096
# Current hardware settings:
# RX:             256
# TX:             256

# Increase ring buffer (reduces drops at high packet rates)
sudo ethtool -G enp0s3 rx 4096 tx 4096
```

### Persistent Tuning with systemd Link Files

```bash
# /etc/systemd/network/10-enp0s3.link
[Match]
MACAddress=08:00:27:ab:cd:ef

[Link]
MTUBytes=9000
WakeOnLan=magic
```

Or with udev rules:

```bash
# /etc/udev/rules.d/70-persistent-net.rules
ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp0s3", \
    RUN+="/sbin/ethtool -s $name speed 1000 duplex full"
```

### Network Performance Monitoring

```bash
# Interface statistics (packets, errors, drops)
ip -s link show enp0s3

# Live monitoring with watch
watch -n 1 'ip -s link show enp0s3'

# Per-protocol statistics
netstat -s

# Socket statistics
ss -s
```

---



---

[← Previous](15-level-3-advanced-performance-tuning.md) | [↑ Index](index.md) | [Next →](17-section-13-troubleshooting-ping-traceroute.md)
