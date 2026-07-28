## 🛠️ 15 Hands-On Practices


### 📘 Level 1 Practices: Interface Basics and Hostname Configuration

Explore your network interfaces, understand naming conventions, and configure hostname and DNS resolution settings.

### ✅ Practice 1: Explore Your Network Interfaces

```bash
mkdir -p ~/linux-course/part26
cd ~/linux-course/part26

# List all interfaces and their details
ip link show

# Save the output
ip link show > interfaces.txt

# Identify each interface type:
# - Which is the loopback?
# - Which is Ethernet?
# - Any wireless interfaces?

# Check interface speeds (if ethtool is available)
for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
    echo "=== $iface ==="
    sudo ethtool "$iface" 2>/dev/null | grep -E "Speed|Duplex|Link detected" || echo "No ethtool info"
done

# Count total interfaces
echo "Total interfaces: $(ip -o link show | wc -l)"
```


### 📘 Level 2 Practices: Configuration, Management, and Troubleshooting

Master the `ip` command, configure interfaces with Netplan and nmcli, set up bonding/bridging/VLANs, and practice troubleshooting with mtr, tcpdump, and ss.

### ✅ Practice 2: Master the `ip` Command

```bash
cd ~/linux-course/part26

# 1. Show all IP addresses
ip addr > ip_addresses.txt

# 2. Show routing table
ip route > routing_table.txt

# 3. Show neighbor table (ARP)
ip neigh > arp_cache.txt

# 4. Show only IPv6 addresses
ip -6 addr > ipv6_addresses.txt

# 5. JSON output (programmatic)
ip -j -p addr show > ip_json.json

# Compare the output of each file
cat ip_addresses.txt
cat routing_table.txt
cat arp_cache.txt
```


### ✅ Practice 3: Compare `ip` vs `ifconfig` Output

```bash
cd ~/linux-course/part26

# Install net-tools if not present
which ifconfig || sudo apt install -y net-tools

# Compare outputs for the same interface
INTERFACE=$(ip -o link show | grep -v lo | head -1 | awk -F': ' '{print $2}')

echo "=== ip addr show $INTERFACE ==="
ip addr show $INTERFACE

echo ""
echo "=== ifconfig $INTERFACE ==="
ifconfig $INTERFACE

echo ""
echo "=== ip route ==="
ip route

echo ""
echo "=== route -n ==="
route -n

# Note the differences:
# - ifconfig shows less information (no statistics, no secondary IPs)
# - route shows less routing information
```


### ✅ Practice 4: Set a Static IP with Netplan

```bash
cd ~/linux-course/part26

# Back up existing config
sudo cp /etc/netplan/*.yaml /etc/netplan/backup.yaml 2>/dev/null || echo "No existing config to backup"

# Create a static IP configuration
sudo tee /etc/netplan/01-static-practice.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.50.10/24
      routes:
        - to: default
          via: 192.168.50.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
EOF

# Test the configuration (auto-reverts in 120 seconds if not confirmed)
sudo netplan try

# Apply if confirmed
# sudo netplan apply

# Verify
# ip addr show enp0s3

# Restore DHCP
sudo tee /etc/netplan/01-static-practice.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
EOF

# Re-apply
# sudo netplan apply
```


### ✅ Practice 5: Use nmcli to Configure a Connection

```bash
cd ~/linux-course/part26

# List all connections
nmcli connection show

# Create a new DHCP connection via nmcli
nmcli connection add \
    type ethernet \
    con-name "practice-dhcp" \
    ifname enp0s3 \
    ipv4.method auto

# Modify to static
nmcli connection modify "practice-dhcp" \
    ipv4.method manual \
    ipv4.addresses 192.168.50.20/24 \
    ipv4.gateway 192.168.50.1

# Show the connection file
echo "=== Connection file ==="
sudo cat /etc/NetworkManager/system-connections/practice-dhcp.nmconnection

# Delete the test connection
nmcli connection delete "practice-dhcp"
```


### ✅ Practice 6: Configure Hostname and /etc/hosts

```bash
cd ~/linux-course/part26

# Current hostname
echo "Current hostname: $(hostname)"
echo "FQDN: $(hostname -f)"

# Set a temporary hostname
sudo hostname practice-vm-01

# Confirm
hostname

# Add entries to /etc/hosts
echo "192.168.1.100   db-server db-server.example.com" | sudo tee -a /etc/hosts
echo "192.168.1.101   web-server web-server.example.com" | sudo tee -a /etc/hosts

# Test resolution
getent hosts db-server
getent hosts web-server
ping -c 1 db-server

# Remove entries
sudo sed -i '/db-server/d' /etc/hosts
sudo sed -i '/web-server/d' /etc/hosts

# Restore hostname
sudo hostname $(cat /etc/hostname)
```


### ✅ Practice 7: DNS Resolution Deep Dive

```bash
cd ~/linux-course/part26

# 1. Show resolver config
echo "=== /etc/resolv.conf ==="
cat /etc/resolv.conf

echo ""
echo "=== resolvectl status ==="
resolvectl status 2>/dev/null || systemd-resolve --status 2>/dev/null || echo "Not available"

# 2. Resolve a hostname
echo ""
echo "=== dig google.com ==="
dig +short google.com

# 3. Trace the resolution path
echo ""
echo "=== Resolution trace ==="
getent hosts google.com

# 4. Check nsswitch order
echo ""
echo "=== nsswitch hosts line ==="
grep hosts /etc/nsswitch.conf

# 5. Test DNS server resolution
echo ""
echo "=== Query specific DNS server ==="
dig @1.1.1.1 google.com +short

# 6. SRV record query
dig _http._tcp.google.com SRV +short 2>/dev/null || echo "No SRV record"
```


### ✅ Practice 8: Diagnose the Network with mtr and traceroute

```bash
cd ~/linux-course/part26

# 1. Basic connectivity
echo "=== Step 1: Local loopback ==="
ping -c 2 127.0.0.1

echo ""
echo "=== Step 2: Gateway ==="
GATEWAY=$(ip route | grep default | awk '{print $3}')
ping -c 2 "$GATEWAY"

echo ""
echo "=== Step 3: External IP ==="
ping -c 2 8.8.8.8

echo ""
echo "=== Step 4: DNS resolution ==="
host google.com 2>/dev/null || nslookup google.com 2>/dev/null

# 2. Traceroute
echo ""
echo "=== Traceroute to 8.8.8.8 ==="
traceroute -n 8.8.8.8 2>/dev/null || echo "traceroute not available"

# 3. mtr if available
if which mtr >/dev/null 2>&1; then
    echo ""
    echo "=== MTR report (5 cycles) ==="
    mtr -r -c 5 -n 8.8.8.8
fi

# Save results
traceroute -n 8.8.8.8 > traceroute_result.txt 2>/dev/null
echo "Saved traceroute result."
```


### ✅ Practice 9: Run tcpdump and Analyze Traffic

```bash
cd ~/linux-course/part26

# Capture 20 packets to a file
sudo tcpdump -i enp0s3 -c 20 -nn -w capture.pcap

# Read the capture
echo "=== Packet summary ==="
sudo tcpdump -r capture.pcap -nn -c 10

# Show hex dump of first 5 packets
echo ""
echo "=== Hex dump ==="
sudo tcpdump -r capture.pcap -nn -X -c 5

# Show packet statistics
echo ""
echo "=== Packet statistics ==="
capinfos capture.pcap 2>/dev/null || echo "capinfos not installed (try 'sudo apt install wireshark-common')"

# Count protocols
echo ""
echo "=== Protocol distribution ==="
sudo tcpdump -r capture.pcap -nn 2>/dev/null | awk '{print $3}' | cut -d. -f1 | sort | uniq -c | sort -rn

# Generate traffic while capturing in another terminal
# In a second terminal:
# ping -c 10 8.8.8.8
# curl http://example.com
```


### ✅ Practice 10: Manage Interface Bonding

```bash
cd ~/linux-course/part26

# This practice creates a virtual bond using dummy interfaces
# (since you may not have two physical NICs)

# Load bonding and dummy kernel modules
sudo modprobe bonding
sudo modprobe dummy

# Create two dummy interfaces to simulate physical NICs
sudo ip link add dummy0 type dummy
sudo ip link add dummy1 type dummy

# Create a bond interface
sudo ip link add bond0 type bond

# Configure bond mode (active-backup)
sudo ip link set bond0 type bond mode 1 miimon 100

# Add dummy interfaces as slaves
sudo ip link set dummy0 master bond0
sudo ip link set dummy1 master bond0

# Assign IP to bond
sudo ip addr add 192.168.200.50/24 dev bond0

# Bring everything up
sudo ip link set dummy0 up
sudo ip link set dummy1 up
sudo ip link set bond0 up

# Check bond status
echo "=== Bond status ==="
cat /proc/net/bonding/bond0

# Test failover
echo ""
echo "=== Active slave before ==="
cat /proc/net/bonding/bond0 | grep "Active Slave"

# Take down the active slave
ACTIVE=$(cat /proc/net/bonding/bond0 | grep "Active Slave" | awk '{print $4}')
echo "Taking down $ACTIVE..."
sudo ip link set "$ACTIVE" down

echo ""
echo "=== Active slave after failover ==="
sleep 1
cat /proc/net/bonding/bond0 | grep "Active Slave"

# Clean up
sudo ip link set bond0 down
sudo ip link delete bond0
sudo ip link delete dummy0
sudo ip link delete dummy1
```


### ✅ Practice 11: Create a Linux Bridge

```bash
cd ~/linux-course/part26

# Create a bridge
sudo ip link add br-practice type bridge

# Create two veth pairs (virtual Ethernet cables)
sudo ip link add veth-a type veth peer name veth-a-br
sudo ip link add veth-b type veth peer name veth-b-br

# Connect one end of each to the bridge
sudo ip link set veth-a-br master br-practice
sudo ip link set veth-b-br master br-practice

# Assign IPs to the free ends
sudo ip addr add 10.0.100.1/24 dev veth-a
sudo ip addr add 10.0.100.2/24 dev veth-b

# Bring everything up
sudo ip link set br-practice up
sudo ip link set veth-a up
sudo ip link set veth-b up
sudo ip link set veth-a-br up
sudo ip link set veth-b-br up

# Verify bridge
echo "=== Bridge status ==="
bridge link show master br-practice

# Test connectivity through the bridge
echo ""
echo "=== Ping through bridge ==="
ping -c 2 -I veth-a 10.0.100.2

# Show FDB (forwarding database)
echo ""
echo "=== MAC table ==="
bridge fdb show br br-practice

# Clean up
sudo ip link delete br-practice
sudo ip link delete veth-a
sudo ip link delete veth-b
```


### ✅ Practice 12: Configure a VLAN Interface

```bash
cd ~/linux-course/part26

# Load 8021q kernel module
sudo modprobe 8021q

# Create a VLAN interface on top of a dummy interface
sudo ip link add dummy-vlan type dummy
sudo ip link set dummy-vlan up

# Create VLAN 100 and VLAN 200
sudo ip link add link dummy-vlan name dummy-vlan.100 type vlan id 100
sudo ip link add link dummy-vlan name dummy-vlan.200 type vlan id 200

# Assign IPs
sudo ip addr add 10.0.100.1/24 dev dummy-vlan.100
sudo ip addr add 10.0.200.1/24 dev dummy-vlan.200

# Bring them up
sudo ip link set dummy-vlan.100 up
sudo ip link set dummy-vlan.200 up

# Show VLAN interfaces
echo "=== VLAN interfaces ==="
ip link show type vlan

# Show VLAN details
echo ""
echo "=== VLAN 100 details ==="
cat /proc/net/vlan/dummy-vlan.100

# Enable routing between VLANs (router-on-a-stick)
sudo sysctl -w net.ipv4.ip_forward=1

# Show IPs on each VLAN
echo ""
echo "=== IPs ==="
ip addr show dummy-vlan.100
ip addr show dummy-vlan.200

# Clean up
sudo ip link delete dummy-vlan
```


### 📘 Level 3 Practices: Performance Tuning and Advanced Diagnostics

Tune network interfaces with ethtool, analyze socket states with ss, and apply your skills in a multi-segment network mini-project.

### ✅ Practice 13: Tune Network with ethtool

```bash
cd ~/linux-course/part26

# Pick the first non-loopback interface
IFACE=$(ip -o link show | grep -v lo | head -1 | awk -F': ' '{print $2}')

echo "=== Interface: $IFACE ==="

# Basic info
echo "=== ethtool $IFACE ==="
sudo ethtool "$IFACE" 2>/dev/null

# Driver info
echo ""
echo "=== Driver info ==="
sudo ethtool -i "$IFACE" 2>/dev/null

# Offload settings
echo ""
echo "=== Offload settings ==="
sudo ethtool -k "$IFACE" 2>/dev/null | head -20

# Ring buffer
echo ""
echo "=== Ring buffers ==="
sudo ethtool -g "$IFACE" 2>/dev/null

# Coalescing settings
echo ""
echo "=== Coalescing ==="
sudo ethtool -c "$IFACE" 2>/dev/null

# Current speed and duplex
echo ""
echo "=== Current link ==="
sudo ethtool "$IFACE" 2>/dev/null | grep -E "Speed|Duplex|Auto-negotiation|Link detected"

# Check if WOL is enabled
echo ""
echo "=== Wake-on-LAN ==="
sudo ethtool "$IFACE" 2>/dev/null | grep "Wake-on"

# Interface statistics
echo ""
echo "=== Interface stats ==="
ip -s link show "$IFACE"
```


### ✅ Practice 14: Deep Troubleshooting with ss and Socket Analysis

```bash
cd ~/linux-course/part26

# 1. Socket statistics summary
echo "=== Socket summary ==="
ss -s

# 2. All listening ports
echo ""
echo "=== Listening ports ==="
ss -tulpn

# 3. Established TCP connections
echo ""
echo "=== Established connections ==="
ss -t state established

# 4. Services with the most connections
echo ""
echo "=== Top services by connection count ==="
ss -t | awk '{print $4}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# 5. Connection states distribution
echo ""
echo "=== TCP state distribution ==="
ss -t | awk '{print $1}' | sort | uniq -c | sort -rn

# 6. Time-wait connections (high count = performance issue)
echo ""
echo "=== TIME-WAIT connections ==="
ss -t state time-wait | wc -l

# 7. Process owning each socket
echo ""
echo "=== Socket to process mapping ==="
ss -tupn | head -20

# 8. Memory usage per socket
echo ""
echo "=== Socket memory (top 5) ==="
ss -t -m | grep -oP 'skmem\([^)]+\)' | head -10
```


### ✅ Practice 15: Real-World Integration — Multi-Segment Network Mini-Project

```bash
cd ~/linux-course/part26

# This practice builds a small multi-segment network with:
# - A bridge (switch)
# - Two VLANs
# - A bonding interface
# - Routing between segments
# - All virtual, running on a single machine

cat > network-lab.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "============================================"
echo "  Multi-Segment Network Lab"
echo "============================================"

# Load modules
sudo modprobe bonding
sudo modprobe 8021q
sudo modprobe dummy

# Create the "physical" interfaces (simulated)
sudo ip link add phys0 type dummy
sudo ip link add phys1 type dummy
sudo ip link add phys2 type dummy

# 1. Create a bond from phys0 and phys1 (redundant trunk)
echo "[1] Creating bond0 (active-backup)..."
sudo ip link add bond0 type bond mode 1 miimon 100
sudo ip link set phys0 master bond0
sudo ip link set phys1 master bond0
sudo ip link set bond0 up
sudo ip link set phys0 up
sudo ip link set phys1 up
echo "  Bond status:"
cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Active Slave"

# 2. Create VLANs on the bond (trunk ports)
echo ""
echo "[2] Creating VLANs on bond0..."
sudo ip link add link bond0 name bond0.10 type vlan id 10
sudo ip link add link bond0 name bond0.20 type vlan id 20
sudo ip link set bond0.10 up
sudo ip link set bond0.20 up

# 3. Create a bridge for VLAN 10
echo ""
echo "[3] Creating bridge br10 for VLAN 10..."
sudo ip link add br10 type bridge
sudo ip link set bond0.10 master br10
sudo ip addr add 10.0.10.1/24 dev br10
sudo ip link set br10 up

# 4. Create a bridge for VLAN 20
echo ""
echo "[4] Creating bridge br20 for VLAN 20..."
sudo ip link add br20 type bridge
sudo ip link set bond0.20 master br20
sudo ip addr add 10.0.20.1/24 dev br20
sudo ip link set br20 up

# 5. Connect a "client" to each VLAN via veth pairs
echo ""
echo "[5] Connecting simulated clients..."
# Client A on VLAN 10
sudo ip link add client-a type veth peer name client-a-br
sudo ip link set client-a-br master br10
sudo ip addr add 10.0.10.100/24 dev client-a
sudo ip link set client-a up
sudo ip link set client-a-br up

# Client B on VLAN 20
sudo ip link add client-b type veth peer name client-b-br
sudo ip link set client-b-br master br20
sudo ip addr add 10.0.20.100/24 dev client-b
sudo ip link set client-b up
sudo ip link set client-b-br up

# 6. Connect the router to phys2
echo ""
echo "[6] Setting up external connectivity..."
sudo ip addr add 10.0.0.1/24 dev phys2
sudo ip link set phys2 up

# 7. Enable IP forwarding (router)
echo ""
echo "[7] Enabling routing..."
sudo sysctl -w net.ipv4.ip_forward=1

# 8. Verify everything
echo ""
echo "============================================"
echo "  Network Lab — Verification"
echo "============================================"

echo ""
echo "=== Interfaces ==="
ip link show | grep -E "bond|br|client|phys" | awk '{print $2, $9}'

echo ""
echo "=== VLANs ==="
ip link show type vlan

echo ""
echo "=== Bridges ==="
bridge link show | head -10

echo ""
echo "=== Bond status ==="
cat /proc/net/bonding/bond0 | grep -E "Bonding Mode|Active Slave|MII Status"

echo ""
echo "=== IP assignments ==="
ip addr show | grep "inet " | grep -E "10\.0\."

echo ""
echo "=== Connectivity tests ==="
echo -n "Client A → Gateway (VLAN 10): "
ping -c 1 -W 1 -I client-a 10.0.10.1 >/dev/null 2>&1 && echo "OK" || echo "FAIL"

echo -n "Client B → Gateway (VLAN 20): "
ping -c 1 -W 1 -I client-b 10.0.20.1 >/dev/null 2>&1 && echo "OK" || echo "FAIL"

echo -n "Client A → Client B (inter-VLAN): "
ping -c 1 -W 1 -I client-a 10.0.20.100 >/dev/null 2>&1 && echo "OK (routed)" || echo "FAIL (no route, needs firewall rules)"

echo ""
echo "============================================"
echo "  Lab complete! Run './network-cleanup.sh' to tear down."
echo "============================================"
EOF

chmod +x network-lab.sh

cat > network-cleanup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Tearing down network lab..."
sudo ip link delete br10 2>/dev/null || true
sudo ip link delete br20 2>/dev/null || true
sudo ip link delete bond0 2>/dev/null || true
sudo ip link delete phys0 2>/dev/null || true
sudo ip link delete phys1 2>/dev/null || true
sudo ip link delete phys2 2>/dev/null || true
sudo ip link delete client-a 2>/dev/null || true
sudo ip link delete client-b 2>/dev/null || true
echo "Cleanup complete."
EOF

chmod +x network-cleanup.sh

echo "Network lab scripts created!"
echo ""
echo "Run the lab:"
echo "  sudo ./network-lab.sh"
echo ""
echo "Clean up:"
echo "  sudo ./network-cleanup.sh"
```





[← Previous](17-section-13-troubleshooting-ping-traceroute.md) | [↑ Index](index.md) | [Next →](19-deep-understanding-how-linux-networking.md)
