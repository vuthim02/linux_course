## 🔍 Section 4: Chrony

Chrony is the modern NTP implementation.

### Installation

```bash
# Debian/Ubuntu
sudo apt install chrony

# Fedora/RHEL (usually preinstalled)
sudo dnf install chrony

# Enable and start
sudo systemctl enable --now chrony
```

### Chrony Configuration

```bash
sudo cat /etc/chrony/chrony.conf
```

```
# Use public NTP servers
pool 2.debian.pool.ntp.org iburst
# OR for RHEL/Fedora:
pool 2.fedora.pool.ntp.org iburst

# Initial synchronization (step, don't slew)
makestep 1.0 3

# Allow the system clock to be adjusted
rtcsync

# Serve time to local network (optional)
# allow 192.168.1.0/24

# Log files
logdir /var/log/chrony
```

### Key Configuration Directives

| Directive | Purpose |
|-----------|---------|
| `pool POOL` | Use multiple servers from a pool |
| `server HOST` | Use a specific NTP server |
| `iburst` | Send burst of queries on startup (faster sync) |
| `makestep THRESHOLD LIMIT` | Step clock if adjustment > THRESHOLD, in first LIMIT updates |
| `rtcsync` | Sync hardware clock to system clock |
| `allow NETWORK` | Allow clients from this network to query |
| `deny NETWORK` | Deny clients from this network |
| `local stratum 10` | Serve time even when not synchronized |
| `bindcmdaddress` | Where to listen for chronyc commands |
| `logdir DIR` | Log directory |

### chronyc — The Chrony Monitoring Tool

```bash
# Show NTP sources
chronyc sources

# Show NTP sources with more detail
chronyc sources -v

# Show tracking information
chronyc tracking

# Show active NTP servers
chronyc activity

# Show NTP server statistics
chronyc sourcestats -v

# Force immediate sync
chronyc -a makestep

# Check chrony status
chronyc activity
```

### Understanding chronyc sources Output

```
$ chronyc sources -v

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock
 / .-- Source state '*' = current sync, '+' = candidate, '-' = unreachable
| /   .-- Source name
v v     .-- Poll interval
210 Number of sources = 4

MS Name/IP address         Stratum Poll Reach LastRx Last sampled
===============================================================================
^* ntp1.example.com              2   6   377    43   -2us[  -3us] +/-   58ms
^+ ntp2.example.com              2   6   377    65   +3us[+3538ns] +/-   65ms
^+ ntp3.example.com              2   6   377    58  -15us[ -15us] +/-   26ms
^- ntp4.example.com              3   6   377   112  +51ms[ +51ms] +/-  109ms
```

| Column | Meaning |
|--------|---------|
| `M` | Mode: `^` = server, `=` = peer, `#` = local |
| `S` | State: `*` = sync source, `+` = candidate, `-` = unreachable |
| `Stratum` | Distance from reference clock |
| `Poll` | Polling interval (power of 2 seconds; 6 = 64s) |
| `Reach` | Reachability register (377 = all 8 probes received) |
| `LastRx` | Time since last response (seconds) |
| `Last sampled` | Offset and jitter |

### Checking Chrony Synchronization

```bash
# Check if chrony is synchronized
chronyc tracking

# Output:
# Reference ID    : A1B2C3D4 (ntp1.example.com)
# Stratum         : 3
# Ref time (UTC)  : Mon Jan 15 15:30:45 2024
# System time     : 0.000001234 seconds slow of NTP time
# Last offset     : -0.000000456 seconds
# RMS offset      : 0.000003456 seconds
# Frequency       : 2.345 ppm slow
# Residual freq   : 0.001 ppm
# Skew            : 0.005 ppm
# Root delay      : 0.012345 seconds
# Root dispersion : 0.003456 seconds
# Update interval : 64.0 seconds
# Leap status     : Normal
```





[← Previous](06-level-2-intermediary-chrony-configuration.md) | [↑ Index](index.md) | [Next →](08-section-5-configuring-chrony-as.md)
