## 🔍 Section 11: VLAN Tagging — 802.1Q

VLANs (Virtual LANs) allow you to segment a single physical network into multiple logical networks using 802.1Q tags.

### How 802.1Q Works

```
┌──────────────┬────────┬──────────────┬───────────────┬──────┐
│ Destination  │ Source │ 802.1Q Tag   │ EtherType     │ Payload │
│ MAC (6B)     │ MAC(6B)│ (4B)         │ (2B)          │       │
└──────────────┴────────┴──────────────┴───────────────┴──────┘
                         ├─ Priority (3 bits)
                         ├─ DEI (1 bit)
                         ├─ VID (12 bits) → 1-4094
                         └─ EtherType 0x8100
```

### Creating VLAN Interfaces

```bash
# Load the 8021q kernel module
sudo modprobe 8021q

# Check if loaded
lsmod | grep 8021q

# Create a VLAN interface
sudo ip link add link enp0s3 name enp0s3.100 type vlan id 100

# Bring it up and assign IP
sudo ip addr add 192.168.100.1/24 dev enp0s3.100
sudo ip link set enp0s3.100 up

# Alternative naming (vlan100)
sudo ip link add link enp0s3 name vlan100 type vlan id 100
```

### Using vconfig (Legacy)

```bash
# Install vlan package
sudo apt install vlan    # Debian/Ubuntu

# Create VLAN
sudo vconfig add enp0s3 100

# Set VLAN flags
sudo vconfig set_flag enp0s3 1  # Enable VLAN reorder header
sudo vconfig set_egress_map enp0s3 0 7  # Set priority

# Remove VLAN
sudo vconfig rem enp0s3.100
```

### VLAN Management

```bash
# Show VLAN interfaces
ip link show type vlan

# Show VLAN details
cat /proc/net/vlan/enp0s3.100

# Output:
# enp0s3.100  VID: 100      REORDER_HDR: 1  dev->priv_flags: 1
# total frames received:         0
# total bytes received:          0
# total frames transmitted:      0
# total bytes transmitted:       0
# ...

# Remove a VLAN interface
sudo ip link delete enp0s3.100
```

### VLAN in /etc/network/interfaces

```bash
auto enp0s3.100
iface enp0s3.100 inet static
    address 192.168.100.1
    netmask 255.255.255.0
    vlan-raw-device enp0s3
```

### VLAN with NetworkManager

```bash
# Create a VLAN connection
nmcli connection add type vlan \
    con-name vlan-100 \
    dev enp0s3 \
    id 100 \
    ipv4.method manual \
    ipv4.addresses 192.168.100.1/24

# Or using raw device
nmcli connection add type vlan \
    con-name vlan-200 \
    ifname enp0s3.200 \
    vlan.parent enp0s3 \
    vlan.id 200 \
    ipv4.addresses 192.168.200.1/24
```

### Practical VLAN Scenario

A router/firewall with one physical interface connected to a trunk port:

```bash
# Physical interface (no IP)
sudo ip link set enp0s3 up

# Management VLAN 10
sudo ip link add link enp0s3 name vlan10 type vlan id 10
sudo ip addr add 10.0.10.1/24 dev vlan10
sudo ip link set vlan10 up

# Client VLAN 20
sudo ip link add link enp0s3 name vlan20 type vlan id 20
sudo ip addr add 10.0.20.1/24 dev vlan20
sudo ip link set vlan20 up

# Server VLAN 30
sudo ip link add link enp0s3 name vlan30 type vlan id 30
sudo ip addr add 10.0.30.1/24 dev vlan30
sudo ip link set vlan30 up

# Enable routing between VLANs
sudo sysctl -w net.ipv4.ip_forward=1

# Make persistent
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-router.conf
```





[← Previous](13-section-10-bonding-and-bridging.md) | [↑ Index](index.md) | [Next →](15-level-3-advanced-performance-tuning.md)
