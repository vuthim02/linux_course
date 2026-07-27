## 🔍 Section 13: Troubleshooting — ping, traceroute, mtr, tcpdump, ss

### ping — Basic Connectivity Test

```bash
# Basic ping
ping 8.8.8.8

# Ping with count
ping -c 4 8.8.8.8

# Ping with interval
ping -i 0.2 -c 10 8.8.8.8   # Every 200ms

# Ping with flood (root only)
sudo ping -f -c 1000 8.8.8.8

# Check MTU with ping (Don't Fragment)
ping -M do -s 1472 -c 3 192.168.1.1

# Ping a hostname
ping -c 2 google.com
```

Interpretation:
```
64 bytes from 8.8.8.8: icmp_seq=1 ttl=118 time=12.3 ms
```
- `ttl=118` → started at 128, has traversed ~10 hops
- `time=12.3ms` → round-trip latency
- `icmp_seq=1` → sequence number (gaps mean packet loss)

### traceroute — Path Discovery

```bash
# Basic traceroute
traceroute 8.8.8.8

# Faster (no DNS lookups)
traceroute -n 8.8.8.8

# Set max hops
traceroute -m 30 -n 8.8.8.8

# Use TCP instead of UDP (for firewalls)
traceroute -T -p 80 8.8.8.8

# Use ICMP
traceroute -I 8.8.8.8

# Set source interface
traceroute -i enp0s3 -n 8.8.8.8
```

Output example:
```
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  192.168.1.1  0.523 ms  0.430 ms  0.437 ms
 2  10.0.0.1    1.234 ms  1.567 ms  1.234 ms
 3  * * *
 4  72.14.215.123  12.345 ms  15.678 ms  14.567 ms
 5  216.239.43.45  18.901 ms  19.234 ms  20.123 ms
 6  8.8.8.8     21.456 ms  21.567 ms  22.123 ms
```

`* * *` means no response (firewall or silent router).

### mtr — Continuous Traceroute + Ping

`mtr` combines traceroute and ping into a single, continuously updating display.

```bash
# Install mtr
sudo apt install mtr  # Debian/Ubuntu
sudo yum install mtr  # RHEL/CentOS

# Run mtr
mtr 8.8.8.8

# Text-only output (no ncurses)
mtr -r 8.8.8.8

# Generate a report (10 cycles)
mtr -r -c 10 8.8.8.8

# No DNS
mtr -n 8.8.8.8

# Show both IPv4 and IPv6
mtr -4 8.8.8.8
```

Output:
```
                            My traceroute  [v0.95]
server01 (192.168.1.100) -> 8.8.8.8                       Tue Jan 15 10:23:45 2024
Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                                       Packets               Pings
 Host                                Loss%   Snt   Last   Avg  Best  Wrst StDev
 1. 192.168.1.1                      0.0%    10    0.4   0.5   0.3   0.8   0.1
 2. 10.0.0.1                        0.0%    10    1.2   1.3   1.0   2.1   0.3
 3. 72.14.215.123                   0.0%    10   12.3  13.4  12.1  18.9   1.8
 4. 216.239.43.45                   0.0%    10   18.9  19.2  18.1  22.3   1.2
 5. 8.8.8.8                         0.0%    10   21.4  21.8  20.9  23.1   0.7
```

### tcpdump — Packet Capture

`tcpdump` is the Swiss Army knife of packet analysis.

#### Basic Usage

```bash
# Capture all traffic on an interface
sudo tcpdump -i enp0s3

# Capture N packets then stop
sudo tcpdump -i enp0s3 -c 100

# Don't resolve hostnames or ports
sudo tcpdump -i enp0s3 -nn

# Save to file (pcap format, readable by Wireshark)
sudo tcpdump -i enp0s3 -w capture.pcap -c 1000

# Read a capture file
sudo tcpdump -r capture.pcap -nn
```

#### Filter Expressions

```bash
# Host filter
sudo tcpdump -i enp0s3 host 192.168.1.1

# Port filter
sudo tcpdump -i enp0s3 port 80
sudo tcpdump -i enp0s3 port 22

# Protocol filter
sudo tcpdump -i enp0s3 icmp
sudo tcpdump -i enp0s3 tcp
sudo tcpdump -i enp0s3 udp
sudo tcpdump -i enp0s3 arp

# Complex expressions (and/or/not)
sudo tcpdump -i enp0s3 host 192.168.1.100 and port 443
sudo tcpdump -i enp0s3 not port 22
sudo tcpdump -i enp0s3 src 10.0.0.1 and dst port 53

# Subnet
sudo tcpdump -i enp0s3 net 192.168.1.0/24
```

#### Practical tcpdump Examples

```bash
# Watch DHCP traffic (bootp/dhcp uses ports 67/68)
sudo tcpdump -i enp0s3 -nn port 67 or port 68

# Watch DNS queries
sudo tcpdump -i enp0s3 -nn port 53

# Watch TCP handshake (SYN packets only)
sudo tcpdump -i enp0s3 'tcp[tcpflags] & tcp-syn != 0'

# Watch HTTP requests and responses
sudo tcpdump -i enp0s3 -A port 80   # -A = ASCII output
sudo tcpdump -i enp0s3 -X port 80   # -X = hex+ASCII

# Watch traffic for a specific MAC
sudo tcpdump -i enp0s3 ether host 08:00:27:ab:cd:ef

# Watch VLAN traffic
sudo tcpdump -i enp0s3 vlan

# Verbose output (more packet details)
sudo tcpdump -i enp0s3 -v
sudo tcpdump -i enp0s3 -vv
sudo tcpdump -i enp0s3 -vvv
```

#### tcpdump One-Liners

```bash
# Show top talkers by packet count
sudo tcpdump -i enp0s3 -nn -c 1000 | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -rn | head -10

# Capture HTTP requests only
sudo tcpdump -i enp0s3 -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'

# Show non-TCP traffic (just UDP and others)
sudo tcpdump -i enp0s3 not tcp

# Capture during a specific window (background, stop later)
sudo tcpdump -i enp0s3 -w overnight.pcap &
# ... let it run ...
pkill -SIGINT tcpdump  # Stop gracefully
```

### ss — Socket Statistics (Modern netstat)

`ss` is the modern replacement for `netstat`, also using Netlink sockets.

```bash
# Show all sockets
ss -a

# Show all listening sockets
ss -l

# Show TCP sockets
ss -t

# Show UDP sockets
ss -u

# Show process using each socket
ss -tup

# Numeric (no DNS/service resolution)
ss -tulpn

# Show socket statistics summary
ss -s

# Show sockets in a specific state
ss -t state established
ss -t state listening
ss -t state time-wait
ss state fin-wait-1

# Show sockets for a specific port
ss -t sport = :22
ss -t dport = :80
ss -t '( sport = :22 or dport = :22 )'

# Show all connections to a specific host
ss -t dst 192.168.1.1

# Show timer info
ss -t -o

# Show memory usage per socket
ss -t -m
```

### Troubleshooting Methodology

#### Step-by-Step Network Problem Diagnosis

```bash
# Step 1: Is the interface up?
ip link show enp0s3 | grep "state UP"

# Step 2: Do we have an IP?
ip addr show enp0s3 | grep "inet "

# Step 3: Can we reach the gateway?
ping -c 2 $(ip route | grep default | awk '{print $3}')

# Step 4: Can we reach the internet?
ping -c 2 8.8.8.8

# Step 5: Does DNS work?
host google.com

# Step 6: Is the remote service reachable?
nc -zv 192.168.1.100 80

# Step 7: Check for packet loss
mtr -rn 8.8.8.8

# Step 8: Capture traffic for deep inspection
sudo tcpdump -i enp0s3 -c 100 -nn host 192.168.1.100
```

#### Common Problems and Solutions

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Interface is DOWN | Cable unplugged | Check cable, `ip link set dev up` |
| No IP address | DHCP failure | `dhclient`, check DHCP server |
| Can't ping gateway | Wrong default route | `ip route add default via ...` |
| Can ping IP but not hostname | DNS misconfigured | Check `/etc/resolv.conf` |
| Slow connection | Duplex mismatch | `ethtool -s speed 1000 duplex full` |
| Dropped packets | Ring buffer full | `ethtool -G rx 4096` |
| High latency | Bufferbloat | Check for full buffers with `ss -t -m` |
| Port not responding | Firewall | `sudo iptables -L`, `sudo ufw status` |

---



---

[← Previous](16-section-12-tuning-ethtool-mtu.md) | [↑ Index](index.md) | [Next →](18-15-hands-on-practices.md)
