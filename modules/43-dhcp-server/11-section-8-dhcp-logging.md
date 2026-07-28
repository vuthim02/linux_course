## 📝 Section 8: DHCP Logging

### 8.1 Default Logging

```bash
sudo tail -f /var/log/syslog | grep dhcpd
```

### 8.2 Separate Log File

```bash
# In dhcpd.conf:
log-facility local7;

# /etc/rsyslog.d/50-dhcp.conf
local7.* /var/log/dhcpd.log

sudo touch /var/log/dhcpd.log && sudo chown syslog:adm /var/log/dhcpd.log
sudo systemctl restart rsyslog
sudo systemctl restart isc-dhcp-server
```

### 8.3 Reading DHCP Logs

```bash
# Successful assignment
grep DHCPACK /var/log/dhcpd.log
# Jun 24 10:00:01 dhcpd DHCPACK on 192.168.1.100 to 52:54:00:ab:cd:ef via eth0

# Denied (NAK)
grep DHCPNAK /var/log/dhcpd.log

# No free leases — look for DHCPDISCOVER without matching ACK
grep DHCPDISCOVER /var/log/dhcpd.log | wc -l
```

### 8.4 Packet Capture

```bash
# Live capture
sudo tcpdump -i eth0 -n port 67 or port 68 -v

# Save to file
sudo tcpdump -i eth0 -n -s 0 port 67 or port 68 -w dhcp.pcap

# Sample output:
# 10:00:00.123456 IP 0.0.0.0.68 > 255.255.255.255.67:
#   BOOTP/DHCP, Request from 52:54:00:ab:cd:ef, xid 0x3a4b7c8d
#   DHCP-Message (53): Discover
#   Parameter-Request (55): 1,3,6,15,42,51,58,59
```





[← Previous](10-section-7-dhcp-relay.md) | [↑ Index](index.md) | [Next →](12-level-3-advanced-failover-kea.md)
