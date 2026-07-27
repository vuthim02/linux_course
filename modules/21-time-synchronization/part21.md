# 🐧 Linux System Administrator — Complete Course
## Part 21 of ∞: Time Synchronization — NTP and Chrony

---

> **Reverse Engineering Approach:** If your server's clock is wrong, everything breaks. Logs have impossible timestamps, cron jobs run at the wrong time, SSL certificates say "not yet valid," and authentication protocols fail. Time synchronization is not optional — it is foundational. Understanding how NTP works — from the atomic clock down to your server's system clock — is essential infrastructure knowledge.

---

## 🎯 What You Will Achieve in Part 21

This module is organized into three progressive levels:

| Level | Focus | What You'll Master |
|-------|-------|--------------------|
| ⭐ Level 1: Basic | Time Concepts and Basics | Why time matters, NTP stratum hierarchy, using `timedatectl` |
| ⭐ Level 2: Intermediary | Chrony Configuration | Installing/configuring Chrony, NTP server setup, systemd-timesyncd |
| ⭐ Level 3: Advanced | Troubleshooting and Internals | Debugging time sync, NTP algorithm internals, leap second handling |

---

## ⭐ Level 1: Basic — Time Concepts and Basics

![NTP architecture — stratum hierarchy from atomic clocks to clients](https://upload.wikimedia.org/wikipedia/commons/0/0d/Architecture_NTP_no_labels.svg)

*NTP stratum hierarchy (Roland Geider / Wikimedia Commons / public domain)*

> **Level 1 Goal:** Understand why accurate time is critical for servers, how the NTP hierarchy works, and how to use `timedatectl` to manage basic time settings.

## 🔍 Section 1: Why Time Matters

### What Depends on Accurate Time?

```bash
# 1. Authentication
# Kerberos requires time within 5 minutes of the server
# SSL/TLS certificates have validity periods (notBefore/notAfter)
# OAuth tokens expire

# 2. Logging and Auditing
# Log timestamps must be accurate for forensics
# Correlating logs across multiple servers requires synchronized time

# 3. Scheduling
# cron jobs run at specific times
# Database backups must align across servers

# 4. Distributed Systems
# Distributed databases (Cassandra, etc.) depend on time ordering
# File timestamps for build systems (make, git)
# Transaction ordering

# 5. Security
# DNSSEC validation
# Certificate revocation lists (CRLs)
# Session timeouts
```

### How Bad Can It Be?

```bash
# Clock off by 1 second:   barely noticeable
# Clock off by 1 minute:   cron jobs start early/late
# Clock off by 1 hour:     log timestamps confusing, cron off by hours
# Clock off by 1 day:      SSL certificates fail ("not yet valid")
# Clock off by 1 year:     everything breaks
```

---

## 🔍 Section 2: How NTP Works

### The NTP Hierarchy (Stratum)

```
Stratum 0: Atomic clocks, GPS receivers
    (not connected to network directly)
    │
Stratum 1: Servers directly connected to Stratum 0
    (time.apple.com, time.google.com, nist.gov)
    │
Stratum 2: Servers syncing from Stratum 1
    (pool.ntp.org servers, your ISP's NTP servers)
    │
Stratum 3: Your organization's NTP servers
    │
Stratum 4: Your workstations and servers
```

### The NTP Protocol

```
NTP Client                    NTP Server
    │                              │
    │── Request (sent at T1) ─────→│
    │                              │
    │←─ Response (T1, T2, T3) ────│
    │      (Received at T4)        │
    │                              │

Round-trip delay = (T4 - T1) - (T3 - T2)
Time offset = ((T2 - T1) + (T3 - T4)) / 2

NTP continuously adjusts the clock:
- Small corrections: slewed (gradually adjusted)
- Large corrections: stepped (jumped immediately)
- Default step threshold: 128ms (slew) vs 128ms+ (step)
```

### NTP vs Chrony

| Aspect | NTP (ntpd) | Chrony |
|--------|-----------|--------|
| Convergence speed | Slower | Faster |
| Accuracy | Excellent | Better (especially with variable latency) |
| Intermittent networks | Works | Works better |
| Virtual machines | Works | Works BETTER (handles suspend/resume) |
| Config format | Simple | Simple |
| Monitoring | ntpq, ntpstat | chronyc |
| Default on | Older distros | Newer distros (RHEL 8+, Ubuntu 18.04+, Debian 10+) |

---

## 🔍 Section 3: Using timedatectl

`timedatectl` is part of systemd and is the primary tool for managing time and date.

```bash
# Show current time settings
timedatectl

# Output:
#                Local time: Mon 2024-01-15 10:30:45 EST
#            Universal time: Mon 2024-01-15 15:30:45 UTC
#                  RTC time: Mon 2024-01-15 15:30:45
#                 Time zone: America/New_York (EST, -0500)
# System clock synchronized: yes
#               NTP service: active
#           RTC in local TZ: no
```

### Setting Time Zone

```bash
# List all time zones
timedatectl list-timezones

# Filter timezones by region
timedatectl list-timezones | grep -i "america"
timedatectl list-timezones | grep -i "europe"

# Set time zone
sudo timedatectl set-timezone America/New_York
sudo timedatectl set-timezone UTC          # Servers often use UTC

# Check current timezone
timedatectl | grep "Time zone"
```

### Setting Time Manually

```bash
# Set date and time (when NTP is disabled)
sudo timedatectl set-ntp no               # Disable NTP first
sudo timedatectl set-time "2024-01-15 10:30:00"
sudo timedatectl set-ntp yes              # Re-enable NTP
```

### Managing NTP

```bash
# Check if NTP is active
timedatectl | grep "NTP service"

# Enable NTP (starts systemd-timesyncd or chronyd)
sudo timedatectl set-ntp yes

# Disable NTP
sudo timedatectl set-ntp no
```

### RTC (Hardware Clock)

```bash
# Show RTC (hardware clock) settings
timedatectl | grep "RTC"

# Set RTC to use UTC (recommended)
sudo timedatectl set-local-rtc 0

# Set RTC to use local time (not recommended for servers)
sudo timedatectl set-local-rtc 1

# Sync system clock to hardware clock
sudo hwclock -w

# Sync hardware clock to system clock
sudo hwclock -s
```

---

## ⭐ Level 2: Intermediary — Chrony Configuration

![NTP servers and clients — hierarchical time distribution](https://upload.wikimedia.org/wikipedia/commons/6/6d/Network_Time_Protocol_servers_and_clients.svg)

*Network Time Protocol servers and clients distribution hierarchy (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Install and configure Chrony as both client and server, understand configuration directives, use `chronyc` for monitoring, and compare with `systemd-timesyncd`.

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

---

## 🔍 Section 5: Configuring Chrony as a Server

If you have many machines on a network, set up one internal NTP server:

```bash
# /etc/chrony/chrony.conf on the NTP server

# Use public NTP servers upstream
pool 2.debian.pool.ntp.org iburst

# Allow clients from your network
allow 192.168.1.0/24

# Serve time even if upstream is temporarily unavailable
local stratum 10

# Log client requests
log measurements statistics tracking
```

On client machines:

```bash
# /etc/chrony/chrony.conf

# Use your internal NTP server
server ntp.internal.example.com iburst

# Fallback to public pool if internal is unreachable
pool 2.debian.pool.ntp.org iburst
```

---

## 🔍 Section 6: systemd-timesyncd

Some lightweight systems use `systemd-timesyncd` instead of Chrony.

```bash
# Check if timesyncd is active
systemctl status systemd-timesyncd

# Configuration
cat /etc/systemd/timesyncd.conf
```

```
[Time]
NTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org
FallbackNTP=ntp.ubuntu.com
RootDistanceMax=5
PollIntervalMin=32
PollIntervalMax=2048
```

### Timesyncd vs Chrony

| Feature | timesyncd | Chrony |
|---------|-----------|--------|
| Complexity | Very simple | Full-featured |
| Server mode | No | Yes |
| NTP peer support | No | Yes |
| Client monitoring | `timedatectl` only | `chronyc` |
| Accuracy | Good | Excellent |
| Best for | Desktops, simple servers | Servers, infrastructure |

---

## ⭐ Level 3: Advanced — Troubleshooting and Internals

![NTP algorithm diagram — clock filter and offset calculation](https://upload.wikimedia.org/wikipedia/commons/f/fb/NTP-Algorithm.svg)

*NTP algorithm showing clock offset calculation (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Diagnose and resolve time synchronization issues, understand the NTP protocol internals, leap second handling, and Chrony's advanced filtering algorithms.

## 🔍 Section 7: Troubleshooting Time Sync

### Common Problems

**Problem 1: Time not synchronized**

```bash
# Check status
timedatectl
# Look for: "System clock synchronized: no"

# Check if NTP service is running
systemctl status chrony || systemctl status systemd-timesyncd

# Check network connectivity to NTP servers
chronyc sources -v
# Or: ntpq -p (if using ntpd)

# Test DNS resolution of NTP servers
host pool.ntp.org
```

**Problem 2: Large time offset**

```bash
# Force immediate sync
sudo chronyc -a makestep

# Check how far off
chronyc tracking | grep "System time"

# If Chromy cannot adjust enough, stop it and set time manually:
sudo systemctl stop chrony
sudo timedatectl set-ntp no
sudo timedatectl set-time "2024-01-15 10:30:00"
sudo timedatectl set-ntp yes
```

**Problem 3: Firewall blocking NTP**

```bash
# NTP uses UDP port 123
# Check if it's open:
nc -zuv pool.ntp.org 123

# Open port 123 for outgoing
sudo ufw allow out 123/udp
# Or for incoming (if you're an NTP server):
sudo ufw allow 123/udp
```

**Problem 4: Virtual machine time drift**

```bash
# VM-specific issues:
# - Host suspension/pause causes time to freeze
# - VM migration can cause jumps
# - Overcommitted CPU causes time to run slow

# Solutions:
# 1. Use Chrony (handles VM pauses better)
# 2. Add to /etc/chrony/chrony.conf:
#    makestep 1.0 -1   # Always step, even large jumps
# 3. Use KVM's virtio-rtc or VMware Tools
```

### Debugging Commands

```bash
# Chrony verbose output
chronyc sources -v
chronyc sourcestats -v

# Check chrony logs
sudo journalctl -u chrony -n 50

# Check if chrony has been stepping the clock
sudo journalctl -u chrony | grep -i "step\|slew"

# Manual NTP query (bypasses Chrony)
ntpdate -q pool.ntp.org
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: Time Basics and timedatectl

---

### ✅ Practice 1: Check Your Current Time Settings

```bash
mkdir -p ~/linux-course/part21
cd ~/linux-course/part21

# Full timedatectl output
timedatectl

# Check system clock
echo ""
echo "System time: $(date)"
echo "UTC time:    $(date -u)"
echo "Unix epoch:  $(date +%s)"

# Check hardware clock
echo ""
echo "Hardware clock:"
sudo hwclock --show 2>/dev/null || echo "Cannot access hardware clock"
```

---

### ✅ Practice 2: Check NTP Service

```bash
cd ~/linux-course/part21

# Which NTP implementation is running?
echo "=== NTP Services ==="
systemctl is-active chrony 2>/dev/null && echo "chrony: active" || echo "chrony: inactive"
systemctl is-active systemd-timesyncd 2>/dev/null && echo "timesyncd: active" || echo "timesyncd: inactive"
systemctl is-active ntp 2>/dev/null && echo "ntpd: active" || echo "ntpd: inactive"

# Show the active service
echo ""
echo "=== Active time service ==="
systemctl list-units --type=service --state=running | grep -E "chrony|timesyncd|ntp"
```

---

### ✅ Practice 3: List and Change Timezones

```bash
cd ~/linux-course/part21

# Current timezone
echo "Current timezone: $(timedatectl | grep "Time zone")"

# List some timezones
echo ""
echo "=== Available timezones (Americas) ==="
timedatectl list-timezones | grep -i "america" | head -10

echo ""
echo "=== Available timezones (Europe) ==="
timedatectl list-timezones | grep -i "europe" | head -10

# Try a temporary timezone (as regular user, only affects this shell)
# Set TZ environment variable for this command
TZ='Asia/Tokyo' date
TZ='Europe/London' date
TZ='Australia/Sydney' date
```

---

### ✅ Practice 5: Check Time Synchronization Status

```bash
cd ~/linux-course/part21

# Is the clock synchronized?
echo "=== Synchronization status ==="
timedatectl | grep "synchronized"

# If available, check with chronyc
if command -v chronyc &>/dev/null; then
    echo ""
    echo "=== System time offset ==="
    chronyc tracking | grep "System time"
    
    echo ""
    echo "=== Leap status ==="
    chronyc tracking | grep "Leap status"
fi
```

---

### ✅ Practice 7: Manual Time Setting (Simulated)

```bash
cd ~/linux-course/part21

# Show how to set time manually (without actually doing it)
cat << 'EOF'
Setting time manually (requires disabling NTP first):

  # 1. Disable NTP
  sudo timedatectl set-ntp no
  
  # 2. Set time
  sudo timedatectl set-time "2024-01-15 10:30:00"
  
  # 3. Or set date/time components separately
  sudo timedatectl set-time "10:30:00"        # Time only
  sudo date +%T -s "10:30:00"                # Using date command
  
  # 4. Sync hardware clock
  sudo hwclock -w
  
  # 5. Re-enable NTP
  sudo timedatectl set-ntp yes

WARNING: Never set time manually on a production server if NTP is available.
Manual time setting can break authentication, logging, and scheduled tasks.
EOF
```

---

### ✅ Practice 12: Test Time with curl

```bash
cd ~/linux-course/part21

# Use HTTP headers to see server-side time
echo "=== Server-reported time ==="
curl -sI https://example.com 2>/dev/null | grep -i "date" || \
  curl -sI https://google.com 2>/dev/null | grep -i "date"

# Compare with local time
echo ""
echo "=== Compare with local time ==="
echo "Local:  $(date -u)"
echo "Server: $(curl -sI https://example.com 2>/dev/null | grep -i "date" | cut -d' ' -f2-)"
```

---

### Level 2 Practices: Chrony Configuration and Monitoring

---

### ✅ Practice 4: Explore Chrony (if installed)

```bash
cd ~/linux-course/part21

if command -v chronyc &>/dev/null; then
    echo "=== Chrony Sources ==="
    chronyc sources -v
    
    echo ""
    echo "=== Chrony Tracking ==="
    chronyc tracking
    
    echo ""
    echo "=== Chrony Activity ==="
    chronyc activity
    
    echo ""
    echo "=== Chrony Configuration ==="
    cat /etc/chrony/chrony.conf 2>/dev/null | grep -v "^#" | grep -v "^$"
else
    echo "Chrony not installed"
fi
```

---

### ✅ Practice 6: Test NTP Server Connectivity

```bash
cd ~/linux-course/part21

# Test basic connectivity to NTP servers
echo "=== Testing NTP server connectivity ==="
for server in pool.ntp.org time.google.com time.apple.com; do
    echo -n "  $server: "
    nc -zuvw2 $server 123 2>/dev/null && echo "OK" || echo "UNREACHABLE"
done

# Query NTP server (requires ntpdate or chrony)
echo ""
echo "=== Query time from pool.ntp.org ==="
if command -v ntpdate &>/dev/null; then
    ntpdate -q pool.ntp.org 2>/dev/null | head -3
elif command -v chronyc &>/dev/null; then
    chronyc sources pool.ntp.org 2>/dev/null | head -5
else
    echo "No NTP query tool available"
fi
```

---

### ✅ Practice 8: Measure Clock Drift

```bash
cd ~/linux-course/part21

# Check chrony's estimate of clock drift
if command -v chronyc &>/dev/null; then
    echo "=== Clock drift ==="
    chronyc tracking | grep -E "Frequency|Skew"
    echo ""
    echo "Frequency = how fast/slow the clock runs (ppm = parts per million)"
    echo "1 ppm = 0.0001% = ~86ms per day = ~31 seconds per year"
fi

# If no chrony, check drift over a shorter period
echo ""
echo "=== Current time vs UTC ==="
echo "System clock: $(date)"
echo "UTC:          $(date -u)"
```

---

### ✅ Practice 9: View Chrony Logs

```bash
cd ~/linux-course/part21

if command -v chronyc &>/dev/null; then
    echo "=== Chrony logs ==="
    journalctl -u chrony -n 30 --no-pager
fi

# Check for time adjustments
echo ""
echo "=== Recent time adjustments ==="
if command -v chronyc &>/dev/null; then
    journalctl -u chrony --no-pager | grep -i "step\|slew\|adjust" | tail -5
fi
```

---

### ✅ Practice 10: Compare Chrony and timesyncd Config

```bash
cd ~/linux-course/part21

# Compare configuration formats
cat << 'EOF'
=== Chrony config (/etc/chrony/chrony.conf) ===
pool 2.debian.pool.ntp.org iburst
makestep 1.0 3
rtcsync

=== timesyncd config (/etc/systemd/timesyncd.conf) ===
[Time]
NTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org
FallbackNTP=ntp.ubuntu.com

=== Which to use? ===
- Chrony: servers, VMs, systems requiring high accuracy
- timesyncd: desktops, laptops, containers, simple setups
EOF
```

---

### ✅ Practice 11: Chrony Server Configuration (Simulated)

```bash
cd ~/linux-course/part21

# Show what a Chrony NTP server config looks like
cat << 'EOF' > chrony_server_example.conf
# Chrony configuration for NTP SERVER
# /etc/chrony/chrony.conf

# Use upstream NTP servers
pool 2.debian.pool.ntp.org iburst
pool 0.pool.ntp.org iburst

# Serve time to local network
allow 192.168.0.0/16
allow 10.0.0.0/8

# Serve time even if upstream is unavailable
local stratum 10

# Sync hardware clock
rtcsync

# Logging
logdir /var/log/chrony
log measurements statistics tracking

# Make initial step if offset > 1 sec (first 3 updates)
makestep 1.0 3

# Client configuration (from /etc/chrony/chrony.conf on client):
# server ntp.internal.example.com iburst
EOF

echo "Example Chrony server config written"
```

---

### ✅ Practice 13: RTC (Hardware Clock) Management

```bash
cd ~/linux-course/part21

# Check RTC
echo "=== RTC settings ==="
timedatectl | grep RTC

# Show RTC time
echo ""
echo "Hardware clock:"
sudo hwclock --show 2>/dev/null || echo "Cannot read hardware clock"

# Compare system and hardware time
echo ""
echo "System time:  $(date)"
echo "Hardware RTC: $(sudo hwclock --show 2>/dev/null || echo 'N/A')"
```

---

### ✅ Practice 14: Chrony Source Statistics

```bash
cd ~/linux-course/part21

if command -v chronyc &>/dev/null; then
    echo "=== Source statistics ==="
    chronyc sourcestats -v
    
    echo ""
    echo "=== NTP reachability ==="
    # The Reach column shows if server is responding
    # 377 = all 8 probes received (perfect)
    # 0 = no response in last 8 polls
    chronyc sources | awk 'NR>2 {print $1, $6}'
fi
```

---

### Level 3 Practices: Advanced Troubleshooting and Auditing

---

### ✅ Practice 15: Real SysAdmin Scenario — Time Audit Report

```bash
cd ~/linux-course/part21

cat > time_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="time_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  TIME SYNCHRONIZATION AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Current time
echo "1. CURRENT TIME" >> "$REPORT"
echo "  Local: $(date)" >> "$REPORT"
echo "  UTC:   $(date -u)" >> "$REPORT"
echo "  Epoch: $(date +%s)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: timedatectl output
echo "2. TIMEDATECTL STATUS" >> "$REPORT"
timedatectl | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: NTP service status
echo "3. NTP SERVICE" >> "$REPORT"
for svc in chrony systemd-timesyncd ntp; do
    status=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
    echo "  $svc: $status" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 4: Chrony info (if available)
echo "4. CHRONY STATUS" >> "$REPORT"
if command -v chronyc &>/dev/null; then
    echo "  Sources:" >> "$REPORT"
    chronyc sources -v 2>/dev/null | sed 's/^/    /' >> "$REPORT"
    echo "" >> "$REPORT"
    echo "  Tracking:" >> "$REPORT"
    chronyc tracking 2>/dev/null | sed 's/^/    /' >> "$REPORT"
else
    echo "  Not installed" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 5: Timezone
echo "5. TIMEZONE" >> "$REPORT"
echo "  $(timedatectl | grep "Time zone")" >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: RTC
echo "6. HARDWARE CLOCK" >> "$REPORT"
sudo hwclock --show 2>/dev/null | sed 's/^/  /' >> "$REPORT" || echo "  Cannot read" >> "$REPORT"
echo "" >> "$REPORT"

# Section 7: Time drift
echo "7. TIME DRIFT ESTIMATE" >> "$REPORT"
if command -v chronyc &>/dev/null; then
    chronyc tracking 2>/dev/null | grep "Frequency" | sed 's/^/  /' >> "$REPORT"
    echo "  (ppm = microseconds per second)" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x time_audit.sh
./time_audit.sh
```

---

## 🧠 Deep Understanding — How NTP Really Works

### The NTP Algorithm

```
1. NTP client sends a packet to NTP server
   - Records send time (T1)

2. Server receives packet
   - Records receive time (T2)
   - Sends response with T1, T2, and transmit time (T3)

3. Client receives response
   - Records receive time (T4)

4. Client calculates:
   - Round-trip delay = (T4 - T1) - (T3 - T2)
   - Offset = ((T2 - T1) + (T3 - T4)) / 2

5. Client repeats this many times
   - Discards outliers
   - Filters best samples
   - Averages the results

6. Client adjusts clock
   - Small offset: slew (gradually adjust frequency)
   - Large offset: step (jump immediately)
```

### Why Chrony Is Better for Modern Systems

```
Virtual machines:
  - Host can pause the VM (time freezes)
  - CPU stealing can slow time
  - Live migration changes the clock
  Chrony detects VM suspend and corrects rapidly

Intermittent network:
  - Laptops that sleep/wake
  - Servers with unreliable network
  Chrony keeps good time even without constant connection

Variable latency:
  - Wi-Fi has unpredictable delays
  - Chrony's filtering handles this better than ntpd
```

### The Leap Second

```
A leap second is added (or removed) to keep UTC in sync with
Earth's rotation. It happens on June 30 or December 31.

Linux kernel handles it via:
- NTP servers broadcast the impending leap second
- Kernel inserts or skips the extra second at 23:59:60
- Some systems handle it poorly (crashes, CPU spikes)

Modern practice:
- Servers "slew" the leap second over 24 hours
- Chrony uses the "leapsec mode slew" option
- Google uses "leap smear" — spreading the second over the day
```

---

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

---

## 🚀 What's Coming in Part 22

**Part 22: Network Services — DHCP, HTTP, SSH**

You will learn:
- DHCP server configuration (isc-dhcp-server)
- HTTP server basics (Apache/Nginx)
- SSH server hardening and configuration
- Network service management
- Troubleshooting network services
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. Why is accurate time synchronization critical for servers?
2. What is the NTP stratum hierarchy?
3. What does `timedatectl set-timezone UTC` do?
4. What is the difference between NTP (ntpd) and Chrony?
5. How do you check if the system clock is synchronized?
6. What does `chronyc sources -v` show?
7. What is the `iburst` option in Chrony config?
8. What does `makestep 1.0 3` mean in Chrony config?
9. How do you set the system time manually?
10. What is the purpose of `rtcsync` in Chrony?
11. How do you configure Chrony as an NTP server?
12. What port does NTP use?
13. What is `systemd-timesyncd` and when is it used?
14. How do you check the hardware clock from Linux?
15. Why is Chrony better than ntpd for virtual machines?

**Score:** 12/15 correct = ready for Part 22.

---

*Linux SysAdmin Course | Part 21 of ∞ | Reverse Engineering Approach*
*Previous → Part 20: System Updates and Patch Management*
*Next → Part 22: Network Services — DHCP, HTTP, SSH*

[← Previous](part20.md) | [Next →](part22.md)
