## 🔍 Section 4: NetworkManager, nmcli, nmtui

NetworkManager is the default network management service on most modern Linux distributions. It abstracts hardware, configuration files, and connectivity in a unified D-Bus service.

### The NetworkManager Architecture

```
┌──────────────────────────────────────────┐
│           NetworkManager daemon          │
│  (systemd service: NetworkManager.service) │
├──────────────────────────────────────────┤
│  D-Bus API ─┬─ nmcli (command line)      │
│              ├─ nmtui (text UI)          │
│              ├─ GNOME Settings (GUI)     │
│              └─ nm-connection-editor     │
├──────────────────────────────────────────┤
│  Backends: netplan, ifupdown,            │
│            /etc/sysconfig/network-scripts│
└──────────────────────────────────────────┘
```

```bash
# Check if NetworkManager is running
systemctl status NetworkManager

# Or
nmcli general status
```

### nmcli — The Command-Line Tool

#### General Status and Control

```bash
# Show overall status
nmcli general status

# Show hostname and networking state
nmcli general hostname
nmcli networking connectivity check
nmcli networking on
nmcli networking off

# Show permissions
nmcli general permissions

# Show version
nmcli --version
```

#### Device Management

```bash
# Show all network devices
nmcli device status

# Show device details
nmcli device show enp0s3

# Show device capabilities (speed, duplex, etc.)
nmcli device show enp0s3 | grep -E 'SPEED|DUPLEX|AUTONEG'

# Connect a Wi-Fi network
nmcli device wifi connect "MyWiFi" password "secret123"

# List available Wi-Fi networks
nmcli device wifi list

# Disconnect and reconnect a device
nmcli device disconnect enp0s3
nmcli device connect enp0s3

# Monitor device changes
nmcli device monitor enp0s3
```

#### Connection Management

```bash
# List all connections
nmcli connection show

# List only active connections
nmcli connection show --active

# Show connection details
nmcli connection show "Wired connection 1"

# Create a new static IP connection
nmcli connection add \
    type ethernet \
    con-name "static-eth0" \
    ifname enp0s3 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns 8.8.8.8,8.8.4.4

# Create a DHCP connection
nmcli connection add \
    type ethernet \
    con-name "dhcp-eth0" \
    ifname enp0s3 \
    ipv4.method auto

# Modify an existing connection
nmcli connection modify "static-eth0" \
    ipv4.addresses 192.168.1.200/24 \
    ipv4.dns "1.1.1.1"

# Activate a connection
nmcli connection up "static-eth0"

# Deactivate a connection
nmcli connection down "static-eth0"

# Delete a connection
nmcli connection delete "static-eth0"

# Clone a connection
nmcli connection clone "static-eth0" "backup-eth0"
```

#### Wi-Fi from Command Line

```bash
# Scan for Wi-Fi
nmcli device wifi list

# Connect to an open network
nmcli device wifi connect "CoffeeShop"

# Connect to a WPA2 network
nmcli device wifi connect "WorkWiFi" password "s3cr3t"

# Connect using WPA2 Enterprise (EAP)
nmcli device wifi connect "University" \
    password "student123" \
    wep-key-type key \
    --ask

# Save a Wi-Fi network but don't connect
nmcli device wifi connect "KnownNetwork" password "pass" --hidden yes

# Turn Wi-Fi on/off
nmcli radio wifi off
nmcli radio wifi on
```

### nmtui — The Text User Interface

`nmtui` is a curses-based UI that runs in any terminal.

```bash
# Start the text UI
nmtui
```

Menu structure:
```
┌───────────── NetworkManager TUI ─────────────┐
│                                               │
│  Edit a connection                            │
│  Activate a connection                        │
│  Set system hostname                          │
│  Quit                                         │
│                                               │
└───────────────────────────────────────────────┘
```

Use arrow keys to navigate, Enter to select, Tab to switch fields.

### NetworkManager Configuration Files

Connections are stored in `/etc/NetworkManager/system-connections/`:

```bash
# List all connection files
ls /etc/NetworkManager/system-connections/

# View a connection file (INI format)
sudo cat /etc/NetworkManager/system-connections/static-eth0.nmconnection
```

Example connection file:
```ini
[connection]
id=static-eth0
uuid=abc12345-6789-def0-1234-56789abcdef0
type=ethernet
interface-name=enp0s3

[ipv4]
method=manual
addresses=192.168.1.100/24
gateway=192.168.1.1
dns=8.8.8.8;8.8.4.4;

[ipv6]
method=disabled
```

### Managing NetworkManager via systemd

```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Reload configuration without restarting
sudo nmcli connection reload

# View NetworkManager logs
journalctl -u NetworkManager -n 50 -f
```

---



---

[← Previous](06-section-3-legacy-ifconfig-and.md) | [↑ Index](index.md) | [Next →](08-section-5-netplan-modern-ubuntudebian.md)
