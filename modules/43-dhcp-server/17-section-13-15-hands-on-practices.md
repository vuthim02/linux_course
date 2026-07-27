## 🛠️ Section 13: 15 Hands-On Practices

### ⭐ Level 1: Basic Practices

#### Practice 1: Install ISC DHCP Server

```bash
sudo apt update && sudo apt install -y isc-dhcp-server
dhcpd --version
systemctl status isc-dhcp-server
sudo ss -tulpn | grep :67
```

### ⭐ Level 2: Intermediary Practices

#### Practice 2: Configure a Basic Subnet

```bash
# /etc/dhcp/dhcpd.conf
option domain-name "homelab.local";
option domain-name-servers 8.8.8.8, 1.1.1.1;
default-lease-time 86400;
max-lease-time 172800;
authoritative;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
}
```

```bash
sudo dhcpd -t && sudo systemctl restart isc-dhcp-server
sudo tail -f /var/log/syslog | grep dhcpd
```

#### Practice 3: Add a Static Reservation

Add to `dhcpd.conf`:
```bash
host my-server {
    hardware ethernet 52:54:00:ab:cd:ef;
    fixed-address 192.168.1.50;
    option host-name "my-server";
}
```

```bash
sudo dhcpd -t && sudo systemctl restart isc-dhcp-server
sudo grep my-server /var/log/syslog
```

#### Practice 4: Set Custom DNS and NTP Options

```bash
option domain-name "example.com";
option domain-name-servers 8.8.8.8, 8.8.4.4;
option ntp-servers time.google.com, pool.ntp.org;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 192.168.1.1, 8.8.8.8;
}
```

Verify client received options:
```bash
nmcli dev show eth0 | grep DNS
sudo tcpdump -i eth0 -n port 67 or port 68 -X | grep -A 2 "Domain-Name-Server"
```

#### Practice 5: Enable DHCP Logging to Separate File

```bash
# In dhcpd.conf:
log-facility local7;

# /etc/rsyslog.d/50-dhcp.conf
echo 'local7.* /var/log/dhcpd.log' | sudo tee /etc/rsyslog.d/50-dhcp.conf
sudo touch /var/log/dhcpd.log && sudo chown syslog:adm /var/log/dhcpd.log
sudo systemctl restart rsyslog && sudo systemctl restart isc-dhcp-server
sudo tail -f /var/log/dhcpd.log
```

#### Practice 6: Set Up DHCP Relay (On VMs)

**Topology:** VM1 (DHCP: 192.168.1.10), VM2 (Relay: eth0=192.168.1.11, eth1=192.168.2.1), VM3 (Client: subnet B)

On relay:
```bash
sudo apt install -y isc-dhcp-relay
# /etc/default/isc-dhcp-relay
# SERVERS="192.168.1.10"
# INTERFACES="eth0 eth1"
sudo systemctl enable --now isc-dhcp-relay
sudo sysctl -w net.ipv4.ip_forward=1
```

On DHCP server, add subnet for relayed network:
```bash
subnet 192.168.2.0 netmask 255.255.255.0 {
    range 192.168.2.100 192.168.2.200;
    option routers 192.168.2.1;
}
```

#### Practice 7: Configure DHCPv6 (Stateless)

```bash
# /etc/dhcp/dhcpd6.conf
option dhcp6.name-servers 2001:4860:4860::8888;
option dhcp6.domain-search "example.com";
subnet6 2001:db8:1::/64 {
    range6 2001:db8:1::100 2001:db8:1::200;
}

sudo dhcpd -6 -cf /etc/dhcp/dhcpd6.conf -lf /var/lib/dhcp/dhcpd6.leases eth0
ip -6 addr show   # On client
```

#### Practice 8: Debug DHCP with tcpdump

```bash
# Terminal 1: capture
sudo tcpdump -i eth0 -n port 67 or port 68 -v -e

# Terminal 2: force renew
sudo dhclient -r eth0 && sudo dhclient -v eth0
```

Analyze each packet:
```
1. DHCPDISCOVER — src MAC, 0.0.0.0, broadcast
2. DHCPOFFER   — yiaddr (offered IP), server ID, lease time
3. DHCPREQUEST — requested IP, server ID
4. DHCPACK     — confirmed, all options
```

### ⭐ Level 3: Advanced Practices

#### Practice 9: Configure DHCP Failover

Set up two servers using the config from Section 9. Test:
```bash
# Stop primary — verify secondary takes over
sudo systemctl stop isc-dhcp-server
sudo tail -f /var/log/syslog | grep dhcpd
# "I move from normal to partner-down"

# Restart primary — verify resync
sudo systemctl start isc-dhcp-server
# "recovering from partner-down"
```

#### Practice 10: Install Kea with JSON Config

```bash
sudo apt install -y kea-dhcp4-server kea-ctrl-agent
sudo vim /etc/kea/kea-dhcp4.conf   # Use JSON from Section 10.4
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4-server
sudo tail -f /var/log/kea/kea-dhcp4.log
```

#### Practice 11: Use Kea REST API

```bash
sudo systemctl enable --now kea-ctrl-agent

# List leases
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/

# Add reservation
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "command": "reservation-add", "service": [ "dhcp4" ],
    "parameters": {
        "reservation": {
            "hw-address": "52:54:00:aa:bb:cc",
            "ip-address": "192.168.1.99",
            "hostname": "api-test"
        }
    }
}' http://localhost:8000/

# Get stats
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "statistic-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/
```

#### Practice 12: Stateful DHCPv6 with Kea

Use the Kea DHCPv6 JSON from Section 11.6:
```bash
sudo systemctl enable --now kea-dhcp6-server
sudo tail -f /var/log/kea/kea-dhcp6.log
```

#### Practice 13: Configure PXE Boot Options

```bash
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option tftp-server-name "192.168.1.5";
    option bootfile-name "pxelinux.0";
}
```

```bash
sudo apt install -y tftpd-hpa
sudo mkdir -p /srv/tftp && echo "test" | sudo tee /srv/tftp/pxelinux.0
sudo systemctl enable --now tftpd-hpa
tftp 192.168.1.5 -c get pxelinux.0
```

#### Practice 14: Multi-Arch PXE (BIOS + UEFI)

Implement the class-based config from Section 12.5. Test with VMs of different firmware types.

#### Practice 15: Real-World Integration — Production DHCP Server with Failover + PXE

Build a complete production-grade DHCP infrastructure:

```bash
# ┌─────────────────────────────────────────────────────────────┐
# │  REAL-WORLD INTEGRATION CHECKLIST                          │
# │                                                             │
# │  [✓] ISC DHCP installed on primary and secondary            │
# │  [✓] Subnets configured for all VLANs                      │
# │  [✓] Static reservations for servers, printers, IP cameras │
# │  [✓] Failover peer configured (primary + secondary)         │
# │  [✓] DHCP relay configured on router for remote subnets    │
# │  [✓] PXE boot options for BIOS and UEFI                    │
# │  [✓] Logging to separate file + centralized syslog         │
# │  [✓] Kea installed and tested as next-gen replacement      │
# │  [✓] DHCPv6 stateful configured for IPv6 clients           │
# │  [✓] Backup — /etc/dhcp/ and /var/lib/dhcp/ backed up     │
# │  [✓] Monitoring — DHCP pool utilization tracked            │
# │  [✓] Firewall — only 67/udp, 647/tcp open                  │
# └─────────────────────────────────────────────────────────────┘
```

**Reference architecture:**

```
                     Router (ip helper-address 192.168.1.10)
                              │
           ┌──────────────────┼──────────────────┐
           │                  │                  │
    DHCP Primary        DHCP Secondary       TFTP/HTTP
    192.168.1.10        192.168.1.11        192.168.1.5
    (failover) ◄──────► (failover)           (PXE files)
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                 ┌────────────┼────────────┐
                 │            │            │
           VLAN 10        VLAN 20       VLAN 30
       192.168.10.0/24  10.0.0.0/24  172.16.0.0/24
        (Users)          (Servers)    (PXE Boot)
```

**Backup script:**
```bash
#!/bin/bash
# /usr/local/bin/dhcp-backup.sh
BACKUP_DIR="/backup/dhcp"
DATE=$(date +%Y%m%d_%H%M)
mkdir -p $BACKUP_DIR
tar czf "$BACKUP_DIR/dhcp-config-$DATE.tar.gz" /etc/dhcp/ /etc/default/isc-dhcp-server
cp /var/lib/dhcp/dhcpd.leases "$BACKUP_DIR/dhcpd.leases-$DATE"
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
logger "DHCP backup completed: $DATE"
```

**Pool monitoring:**
```bash
#!/bin/bash
# /usr/local/bin/dhcp-pool-usage.sh
for pool in "192.168.1.100 192.168.1.200"; do
    read start end <<< "$pool"
    used=$(grep -c "binding state active" /var/lib/dhcp/dhcpd.leases 2>/dev/null || echo 0)
    echo "Pool $start-$end: $used active leases"
done
```

---



---

[← Previous](16-section-12-pxe-booting.md) | [↑ Index](index.md) | [Next →](18-section-14-deep-understanding.md)
