## 🔍 Section 9: WireGuard in Practice

### Point-to-Point Tunnel

**Host A (eth0: 203.0.113.1):**
```bash
wg genkey | tee /etc/wireguard/private.key
chmod 600 /etc/wireguard/private.key
```

`/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.99.99.1/30
PrivateKey = <host-a-private>
ListenPort = 51820

[Peer]
PublicKey = <host-b-public>
AllowedIPs = 10.99.99.2/32
Endpoint = 203.0.113.2:51820
PersistentKeepalive = 25
```

**Host B (eth0: 203.0.113.2):**
`/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.99.99.2/30
PrivateKey = <host-b-private>
ListenPort = 51820

[Peer]
PublicKey = <host-a-public>
AllowedIPs = 10.99.99.1/32
Endpoint = 203.0.113.1:51820
PersistentKeepalive = 25
```

```bash
# Bring up on both hosts
sudo wg-quick up wg0

# Test
ping 10.99.99.2  # from Host A
ping 10.99.99.1  # from Host B
```

### Site-to-Site VPN

**Site A (10.0.0.0/24):**
```ini
[Interface]
Address = 10.99.99.1/30
PrivateKey = <site-a-private>
ListenPort = 51820

[Peer]
PublicKey = <site-b-public>
AllowedIPs = 10.0.1.0/24, 10.99.99.2/32
Endpoint = site-b.example.com:51820
PersistentKeepalive = 25
```

**Site B (10.0.1.0/24):**
```ini
[Interface]
Address = 10.99.99.2/30
PrivateKey = <site-b-private>
ListenPort = 51820

[Peer]
PublicKey = <site-a-public>
AllowedIPs = 10.0.0.0/24, 10.99.99.1/32
Endpoint = site-a.example.com:51820
PersistentKeepalive = 25
```

```bash
# Enable IP forwarding on both sides
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
# Make permanent:
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf

# Now any machine in 10.0.0.0/24 can reach any machine in 10.0.1.0/24
# via the tunnel.
```

### Roaming Clients (Mobile/Container)

The beauty of WireGuard's roaming is that a client can move between networks without reconnecting:

```bash
# Client on a laptop at home (192.168.1.100)
# Moves to coffee shop (10.0.0.50 via NAT)
# WireGuard detects the change automatically
# 
# The client sends a packet to the server
# Server sees source IP 10.0.0.50:51820
# Server updates its endpoint for the client
# Connection stays alive

# For NAT traversal, use PersistentKeepalive:
[Peer]
PublicKey = <server-public>
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25  # Send keepalive every 25 seconds
```

### Docker WireGuard Containers

```bash
# Run WireGuard in a container for VPN server
docker run -d \
  --name wireguard \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 51820:51820/udp \
  -v /path/to/config:/config \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  linuxserver/wireguard

# Or for a VPN client (route all traffic through tunnel)
docker run -d \
  --name=wireguard-client \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/client-config:/config \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv6.conf.all.disable_ipv6=0" \
  linuxserver/wireguard
```

### wg-dynamic — Dynamic IP Announcement

`wg-dynamic` is a DHCP-like protocol for WireGuard that allows peers to announce IP prefixes dynamically:

```bash
# Install wg-dynamic
git clone https://github.com/WireGuard/wg-dynamic.git
cd wg-dynamic

# Server configuration /etc/wireguard/wg-dynamic.conf:
[Interface]
PrivateKey = <server-private>
ListenPort = 51820

[Peer]
PublicKey = <client-public>
AllowedIPs = 10.99.99.0/24

# Client: announce a /32
# wg-dynamic automatically configures the client's IP
```

---



---

[← Previous](09-section-8-wireguard.md) | [↑ Index](index.md) | [Next →](11-section-10-vxlan.md)
