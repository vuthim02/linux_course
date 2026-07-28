## 🔍 Section 3: Legacy ifconfig and route — Still in the Wild

Despite being deprecated, `ifconfig` and `route` are still installed on many systems and are essential knowledge for maintaining older servers (RHEL 6, CentOS 6, Ubuntu 14.04).

### ifconfig

```bash
# Install ifconfig (net-tools package)
sudo apt install net-tools   # Debian/Ubuntu
sudo yum install net-tools   # RHEL/CentOS

# Show all interfaces (including down)
ifconfig -a

# Show active interfaces only
ifconfig

# Show a specific interface
ifconfig enp0s3

# Set an IP address
sudo ifconfig enp0s3 192.168.1.100 netmask 255.255.255.0

# Bring interface up/down
sudo ifconfig enp0s3 up
sudo ifconfig enp0s3 down

# Set MTU
sudo ifconfig enp0s3 mtu 9000

# Add an alias (secondary IP)
sudo ifconfig enp0s3:0 192.168.1.200 netmask 255.255.255.0

# Add an alias with broadcast
sudo ifconfig enp0s3:1 10.0.0.1 netmask 255.0.0.0 broadcast 10.255.255.255
```

### route

```bash
# Show routing table
route -n   # -n shows numeric IPs (no DNS lookup)

# Add a default gateway
sudo route add default gw 192.168.1.1

# Add a static route
sudo route add -net 10.0.0.0 netmask 255.0.0.0 gw 192.168.1.1

# Add a route via an interface
sudo route add -net 10.0.0.0 netmask 255.0.0.0 dev enp0s3

# Delete a route
sudo route del -net 10.0.0.0 netmask 255.0.0.0

# Reject a route (blackhole)
sudo route add -net 10.0.0.0 netmask 255.0.0.0 reject
```

### arp (Address Resolution Protocol)

```bash
# Show ARP cache
arp -n

# Add static ARP entry
sudo arp -s 192.168.1.1 00:11:22:33:44:55

# Delete ARP entry
sudo arp -d 192.168.1.1

# Show interface ARP statistics
arp -i enp0s3 -n
```

### netstat (Deprecated, Use ss Instead)

```bash
# Show all listening ports
netstat -tuln

# Show routing table
netstat -rn

# Show network statistics
netstat -s

# Show active connections
netstat -an | grep ESTABLISHED

# Show process using each socket
netstat -tulnp
```

### Why These Are Legacy

- `ifconfig` cannot show detailed stats (dropped packets, errors, speed)
- `ifconfig` reports inconsistent output for multi-address interfaces
- `route` cannot handle advanced routing (policy routing, multipath)
- `netstat` is slow on systems with many connections
- All use the older `ioctl` system call instead of Netlink sockets





[← Previous](05-section-2-the-ip-command.md) | [↑ Index](index.md) | [Next →](07-section-4-networkmanager-nmcli-nmtui.md)
