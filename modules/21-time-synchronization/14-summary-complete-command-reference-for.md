## 📋 Summary — Complete Command Reference for Part 21

### Level 1: Basic Commands — timedatectl

| Command | Action |
|---------|--------|
| `timedatectl` | Show time & date status |
| `timedatectl list-timezones` | List all timezones |
| `timedatectl set-timezone ZONE` | Set timezone |
| `timedatectl set-time TIME` | Set time (NTP off) |
| `timedatectl set-ntp yes/no` | Enable/disable NTP |

### Level 2: Intermediary Commands — Chrony / chronyc

| Command | Action |
|---------|--------|
| `chronyc sources -v` | Show NTP sources |
| `chronyc tracking` | Show sync status |
| `chronyc activity` | Show NTP activity |
| `chronyc sourcestats -v` | Source statistics |
| `chronyc makestep` | Force immediate sync |
| `systemctl status chrony` | Check Chrony daemon status |
| `systemctl enable --now chrony` | Enable and start Chrony |
| `journalctl -u chrony -n 50` | View Chrony logs |
| `cat /etc/chrony/chrony.conf` | View Chrony configuration |
| `systemctl status systemd-timesyncd` | Check timesyncd status |
| `cat /etc/systemd/timesyncd.conf` | View timesyncd configuration |

### Level 3: Advanced Commands — Hardware Clock and NTP Debugging

| Command | Action |
|---------|--------|
| `sudo hwclock --show` | Read hardware clock |
| `sudo hwclock -w` | System → Hardware |
| `sudo hwclock -s` | Hardware → System |
| `timedatectl \| grep "RTC time"` | Show RTC time via timedatectl |
| `nc -zuv POOL 123` | Test UDP connectivity to NTP server |
| `sudo journalctl -u chrony \| grep -i "step\|slew"` | Search for time adjustments |
| `chronyc tracking \| grep Frequency` | Check clock drift (ppm) |





[← Previous](13-deep-understanding-how-ntp-really.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-22.md)
