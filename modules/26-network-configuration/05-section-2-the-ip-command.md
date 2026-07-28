## 🔍 Section 2: The `ip` Command — Modern Network Swiss Army Knife

The `ip` command from the `iproute2` package is the modern replacement for `ifconfig`, `route`, `arp`, and `netstat`. It communicates with the kernel via **Netlink sockets**, a more powerful and extensible mechanism than the old `ioctl` system calls.

### ip addr — Address Management

```bash
# Show all addresses
ip addr

# Show addresses for a specific interface
ip addr show enp0s3

# Show only IPv4 addresses
ip -4 addr

# Show only IPv6 addresses
ip -6 addr

# Add an IP address
sudo ip addr add 192.168.1.100/24 dev enp0s3

# Remove an IP address
sudo ip addr del 192.168.1.100/24 dev enp0s3

# Flush all IPs from an interface
sudo ip addr flush dev enp0s3
```

### ip link — Interface Control

```bash
# List all interfaces
ip link show

# Show a specific interface
ip link show enp0s3

# Bring an interface up/down
sudo ip link set enp0s3 up
sudo ip link set enp0s3 down

# Set MAC address
sudo ip link set enp0s3 address 00:11:22:33:44:55

# Set MTU
sudo ip link set enp0s3 mtu 9000

# Set interface alias (visible in ip link)
sudo ip link set enp0s3 alias "Primary uplink"
```

### ip route — Routing Table

```bash
# Show routing table
ip route

# Show routing table for a specific protocol
ip route show proto static
ip route show proto kernel

# Add a default gateway
sudo ip route add default via 192.168.1.1

# Add a static route
sudo ip route add 10.0.0.0/8 via 192.168.1.1

# Add a route via an interface (no gateway)
sudo ip route add 10.0.0.0/8 dev enp0s3

# Delete a route
sudo ip route del 10.0.0.0/8

# Replace a route (atomically update)
sudo ip route replace 10.0.0.0/8 via 192.168.1.100

# Show route cache (deprecated, but some kernels support it)
ip route show cache
```

### ip neigh — Neighbor Table (ARP/NDISC)

```bash
# Show ARP table (IPv4 neighbors)
ip neigh

# Show IPv6 neighbors
ip -6 neigh

# Add a static ARP entry
sudo ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev enp0s3

# Delete a neighbor entry
sudo ip neigh del 192.168.1.1 dev enp0s3

# Flush all neighbor entries
sudo ip neigh flush all
```

### ip netns — Network Namespaces

```bash
# List network namespaces
ip netns list

# Create a namespace
sudo ip netns add testns

# Run a command in a namespace
sudo ip netns exec testns ip addr

# Add a veth pair to connect namespaces
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth1 netns testns
```

### The `ip` command is Scriptable

```bash
# JSON output for programmatic use
ip -j addr show
ip -j -p link show  # Pretty-printed JSON

# Batch mode (read commands from file)
cat << 'EOF' | sudo ip -batch -
addr add 192.168.2.10/24 dev enp0s3
link set enp0s3 up
route add default via 192.168.2.1
EOF
```

### Why `ip` Replaced `ifconfig`

| Feature | `ip` | `ifconfig` |
|---------|------|------------|
| Multiple IPs per interface | Native | Alias interfaces (eth0:0) |
| IPv6 | Full support | Limited |
| Netlink protocol | Yes | ioctl (older) |
| Network namespaces | Yes | No |
| JSON output | Yes | No |
| Batch mode | Yes | No |
| VRF, bridge, VLAN | Integrated | Separate tools |





[← Previous](04-level-2-intermediary-network-configuration.md) | [↑ Index](index.md) | [Next →](06-section-3-legacy-ifconfig-and.md)
