## 🆕 Section 10: Kea — The Modern ISC DHCP

### 10.1 Kea vs ISC DHCP

| Feature | ISC DHCP | Kea |
|---------|----------|-----|
| Config format | Flat file | **JSON** |
| Database | Flat file | **MySQL, PostgreSQL, memfile** |
| Performance | Single-threaded | **Multi-threaded** |
| API | None | **REST API** (kea-ctrl-agent) |
| Extensibility | None | **Hooks library** system |
| DHCPv6 | Basic | Full IA_NA, IA_PD support |
| High Availability | Failover protocol | DB-based + REST API |
| Metrics | None | Prometheus via hooks |

### 10.2 Architecture

```
kea-dhcp4 → kea-ctrl-agent (REST :8000) → kea-shell / curl
                  │
            MySQL / PostgreSQL
```

### 10.3 Installation

```bash
sudo apt install -y kea-dhcp4-server kea-ctrl-agent kea-admin
# RHEL: sudo dnf install -y kea-dhcp4 kea-ctrl-agent
```

### 10.4 JSON Configuration

```json
{
    "Dhcp4": {
        "interfaces-config": {
            "interfaces": [ "eth0" ]
        },
        "lease-database": {
            "type": "memfile",
            "lfc-interval": 3600
        },
        "valid-lifetime": 86400,
        "renew-timer": 43200,
        "rebind-timer": 75600,
        "subnet4": [
            {
                "subnet": "192.168.1.0/24",
                "id": 1,
                "pools": [
                    { "pool": "192.168.1.100 - 192.168.1.200" }
                ],
                "option-data": [
                    { "name": "routers", "data": "192.168.1.1" },
                    { "name": "domain-name-servers", "data": "8.8.8.8, 8.8.4.4" },
                    { "name": "domain-name", "data": "example.com" }
                ],
                "reservations": [
                    {
                        "hw-address": "aa:bb:cc:dd:ee:01",
                        "ip-address": "192.168.1.10",
                        "hostname": "mail-server"
                    }
                ]
            }
        ],
        "loggers": [
            {
                "name": "kea-dhcp4",
                "severity": "INFO",
                "output_options": [
                    { "output": "/var/log/kea/kea-dhcp4.log" }
                ]
            }
        ]
    }
}
```

### 10.5 Validate and Start

```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4-server
sudo systemctl enable --now kea-ctrl-agent
sudo tail -f /var/log/kea/kea-dhcp4.log
```

### 10.6 MySQL Backend

```bash
sudo mysql -u root -p
mysql> CREATE DATABASE kea;
mysql> GRANT ALL ON kea.* TO 'kea'@'localhost' IDENTIFIED BY 'password';
mysql> FLUSH PRIVILEGES;
# Initialize schema
sudo kea-admin db-init mysql -u kea -p password -n kea
```

### 10.7 REST API

```bash
# List all leases
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "lease4-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/

# Add reservation
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "command": "reservation-add",
    "service": [ "dhcp4" ],
    "parameters": {
        "reservation": {
            "hw-address": "52:54:00:aa:bb:cc",
            "ip-address": "192.168.1.99",
            "hostname": "api-test"
        }
    }
}' http://localhost:8000/

# Get statistics
curl -X POST -H "Content-Type: application/json" \
  -d '{ "command": "statistic-get-all", "service": [ "dhcp4" ] }' \
  http://localhost:8000/
```

### 10.8 Kea Hooks

```bash
sudo apt install -y kea-hook-lease-cmds kea-hook-statistics kea-hook-flex-id kea-hook-forensic-log

# Enable in config:
"hooks-libraries": [
    { "library": "/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_lease_cmds.so" },
    { "library": "/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_statistics.so" }
]
```

---



---

[← Previous](13-section-9-isc-dhcp-failover.md) | [↑ Index](index.md) | [Next →](15-section-11-dhcpv6.md)
