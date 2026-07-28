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
| `chronyc -a makestep` | Force immediate sync |

### Level 3: Advanced Commands — Hardware Clock

| Command | Action |
|---------|--------|
| `sudo hwclock --show` | Read hardware clock |
| `sudo hwclock -w` | System → Hardware |
| `sudo hwclock -s` | Hardware → System |





[← Previous](13-deep-understanding-how-ntp-really.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-22.md)
