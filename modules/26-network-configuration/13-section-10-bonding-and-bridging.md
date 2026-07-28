## 🔍 Section 10: Bonding and Bridging

### Interface Bonding (Link Aggregation)

Bonding combines multiple physical interfaces into one logical interface for redundancy and/or increased throughput.

#### Bonding Modes

| Mode | Name | Description |
|------|------|-------------|
| 0 | balance-rr | Round-robin: packets alternate across interfaces |
| 1 | active-backup | One active, one standby (failover) |
| 2 | balance-xor | XOR of MAC addresses selects interface |
| 3 | broadcast | All packets sent on all interfaces |
| 4 | 802.3ad | IEEE 802.3ad dynamic link aggregation (LACP) |
| 5 | balance-tlb | Adaptive transmit load balancing |
| 6 | balance-alb | Adaptive load balancing (tx + rx) |

```bash
# Load the bonding kernel module
sudo modprobe bonding

# Check available modes
cat /sys/class/net/bonding_masters 2>/dev/null || echo "No bonds exist"
```

#### Create a Bond from Command Line

```bash
# 1. Create the bond interface
sudo ip link add bond0 type bond mode 802.3ad

# 2. Set bond parameters
sudo ip link set bond0 type bond miimon 100
sudo ip link set bond0 type bond xmit_hash_policy layer3+4

# 3. Add slave interfaces
sudo ip link set eth0 master bond0
sudo ip link set eth1 master bond0

# 4. Bring bond up with an IP
sudo ip addr add 192.168.1.50/24 dev bond0
sudo ip link set bond0 up
```

#### Check Bond Status

```bash
# Bond status in /proc
cat /proc/net/bonding/bond0

# Bond details with ip
ip link show bond0
ip link show master bond0  # Shows slaves

# Check which interface is active (active-backup mode)
cat /proc/net/bonding/bond0 | grep -E "Active Slave|Currently Active Slave"
```

#### Kernel Module Parameters

```bash
# Show bonding module parameters
modinfo bonding

# Load with specific parameters
sudo modprobe bonding mode=1 miimon=100 max_bonds=2

# Load at boot: /etc/modules or /etc/modprobe.d/bonding.conf
echo "bonding" | sudo tee /etc/modules-load.d/bonding.conf
echo "options bonding mode=1 miimon=100" | sudo tee /etc/modprobe.d/bonding.conf
```

### Linux Bridge

A Linux bridge is a virtual switch. It connects interfaces (physical or virtual) as if they were plugged into the same switch.

```bash
# Install bridge utilities
sudo apt install bridge-utils    # Debian/Ubuntu
sudo yum install bridge-utils    # RHEL/CentOS
```

#### Create a Bridge

```bash
# Method 1: Using ip (modern)
sudo ip link add br0 type bridge
sudo ip link set br0 up

# Method 2: Using brctl (legacy)
sudo brctl addbr br0
sudo brctl addif br0 eth0
sudo brctl addif br0 tap0  # Virtual interface for a VM
sudo ifconfig br0 192.168.1.200/24 up
```

#### Bridge Management

```bash
# Show bridges
brctl show

# Show bridge details (STP, forwarding)
bridge link show
bridge fdb show          # Forwarding database (MAC table)

# STP (Spanning Tree Protocol) control
sudo brctl stp br0 on    # Enable Spanning Tree
sudo brctl stp br0 off   # Disable Spanning Tree

# Set bridge priority
sudo brctl setbridgeprio br0 4096

# Ageing time (how long before learned MACs expire)
sudo brctl setageing br0 300
```

#### Bridge + Netplan

```yaml
network:
  version: 2
  renderer: networkd
  bridges:
    br0:
      interfaces: [enp0s3, enp0s8]
      addresses: [192.168.1.200/24]
      routes:
        - to: default
          via: 192.168.1.1
      parameters:
        stp: true
        forward-delay: 4
        ageing-time: 300
        priority: 32768
```

### Bridge for VMs (Docker/Libvirt Style)

When you install Docker or libvirt, they create bridges:

```bash
# Docker bridge
ip link show docker0
brctl show docker0

# libvirt default bridge
ip link show virbr0
brctl show virbr0

# Check which interfaces are bridged
bridge link show master virbr0
```





[← Previous](12-section-9-etcresolvconf-and-dns.md) | [↑ Index](index.md) | [Next →](14-section-11-vlan-tagging-8021q.md)
