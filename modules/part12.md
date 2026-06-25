# 🐧 Linux System Administrator — Complete Course
## Part 12 of ∞: Systemd and Services — Managing the Modern Linux

---

> **Reverse Engineering Approach:** Before systemd, Linux used SysV init — a collection of shell scripts that ran one after another. Systemd replaced all of that with a single, unified system that starts services in parallel, tracks dependencies, and manages every aspect of the running system. When your server won't start, when a service keeps crashing, when you need to know why boot is slow — systemd is where you look.

---

## 🎯 What You Will Achieve in Part 12

| Level | Focus | What You'll Master |
|-------|-------|-------------------|
| ⭐ **Level 1: Basic** | Systemd fundamentals and service control | What systemd is, systemctl basics (start/stop/status/enable/disable) |
| ⭐ **Level 2: Intermediary** | Service creation and daily management | Unit types, custom services, targets, journald, boot analysis, timers |
| ⭐ **Level 3: Advanced** | Debugging and deep internals | Failed service debugging, socket activation, cgroups resource control |

---

## ⭐ Level 1: Basic — Systemd Fundamentals and Service Control

![Systemd Components Architecture](https://upload.wikimedia.org/wikipedia/commons/3/35/Systemd_components.svg)
*Systemd components architecture showing the core system and service manager. Source: Wikimedia Commons*

> **Level 1 Goal:** Understand what systemd is, why it replaced SysV init, and master the basic systemctl commands for starting, stopping, and checking services.

---

## 🔍 Section 1: What Is systemd?

**systemd** is the init system and service manager for almost every modern Linux distribution.

### The Problem systemd Solves

Before systemd (SysV init):

```
Boot sequence:
1. Kernel starts PID 1 (/sbin/init)
2. PID 1 runs /etc/rc.d/rc.sysinit
3. Runs startup scripts in /etc/rc.d/rc3.d/ one at a time
4. Each script starts or stops things (S01network, S55sshd, K90crond)
5. Everything is sequential — slow
6. No dependency tracking — scripts just ran in order
```

With systemd:

```
Boot sequence:
1. Kernel starts PID 1 (/lib/systemd/systemd)
2. systemd reads dependency graph
3. Starts services in PARALLEL where possible
4. Tracks what depends on what
5. Much faster boot, cleaner management
```

### Why the Name "systemd"?

- "systemd" = System D (daemon)
- Follows Unix convention: daemons end with 'd'
- The 'd' is lowercase to distinguish from "System D" (a pun)

```bash
# systemd is always PID 1
ps -p 1 -o pid,comm,cmd
```

Output:
```
  PID COMMAND CMD
    1 systemd /sbin/init
```

Note: `/sbin/init` is a symlink to `systemd` on modern systems.

### Distributions Using systemd

| Distribution | Uses systemd since |
|---|---|
| Ubuntu | 15.04 (2015) |
| Debian | 8 (2015) |
| Fedora | 15 (2011) |
| RHEL / CentOS | 7 (2014) |
| Arch Linux | 2012 |
| openSUSE | 12.1 (2011) |

---

## 🔍 Section 2: systemctl — The Main Control Tool

`systemctl` is THE command for interacting with systemd.

### Service Lifecycle Commands

```bash
# Check status of a service
systemctl status nginx

# Start a service
sudo systemctl start nginx

# Stop a service
sudo systemctl stop nginx

# Restart a service
sudo systemctl restart nginx

# Reload configuration (without restarting)
sudo systemctl reload nginx

# Reload or restart (reload if possible, else restart)
sudo systemctl reload-or-restart nginx
```

### Status Output Explained

```bash
systemctl status nginx
```

```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-01-15 10:23:45 UTC; 2h 3min ago
    Process: 1234 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 1235 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 1236 (nginx)
      Tasks: 3 (limit: 2345)
     Memory: 8.2M
        CPU: 50ms
     CGroup: /system.slice/nginx.service
              ├─1236 nginx: master process /usr/sbin/nginx
              └─1237 nginx: worker process
```

| Field | Meaning |
|-------|---------|
| Loaded | Is the unit loaded? Is it enabled to start at boot? |
| Active | Running, exited, failed, etc. |
| Main PID | The main process ID |
| Tasks | Number of processes in this service |
| Memory | Memory usage |
| CGroup | Control group hierarchy |

### Enabling and Disabling Services

```bash
# Enable — service starts automatically at boot
sudo systemctl enable nginx

# Disable — service will NOT start at boot
sudo systemctl disable nginx

# Enable and start right now (combines both)
sudo systemctl enable --now nginx

# Check if a service is enabled
systemctl is-enabled nginx

# Check if a service is active (running)
systemctl is-active nginx
```

### The Four States of a Service

```bash
# 1. enabled + active = running now, starts on boot (normal)
# 2. enabled + inactive = starts on boot but not running now (unusual)
# 3. disabled + active = running now but won't start on boot
# 4. disabled + inactive = not running, won't start on boot

# Check both
systemctl status nginx
# Shows: Loaded: ... enabled ... Active: active (running)
```

### Masking and Unmasking

```bash
# Mask — PREVENTS a service from ever starting (even manually)
sudo systemctl mask nginx
sudo systemctl start nginx  # Fails: "Unit nginx.service is masked."

# Unmask — restore normal behavior
sudo systemctl unmask nginx
```

Masking is stronger than disabling:
- Disable: prevents auto-start, but can still be started manually
- Mask: creates symlink to /dev/null — cannot be started at all

---

## ⭐ Level 2: Intermediary — Service Creation and Daily Management

![Linux Cgroups and Systemd](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Linux_kernel_unified_hierarchy_cgroups_and_systemd.svg/1024px-Linux_kernel_unified_hierarchy_cgroups_and_systemd.svg.png)
*Linux kernel unified hierarchy with cgroups and systemd integration. Source: Wikimedia Commons*

> **Level 2 Goal:** Understand all unit types, create custom service files, manage targets, use journald for logging, analyze boot performance, and create systemd timers.

---

## 🔍 Section 3: Understanding Unit Types

systemd manages "units" — not just services. Every resource is a unit.

### Common Unit Types

| Type | Extension | Purpose |
|------|-----------|---------|
| Service | `.service` | A daemon or application |
| Socket | `.socket` | IPC or network socket |
| Timer | `.timer` | Scheduled task (cron replacement) |
| Target | `.target` | Group of units (runlevel replacement) |
| Path | `.path` | Trigger action when file changes |
| Mount | `.mount` | Mount a filesystem |
| Automount | `.automount` | Auto-mount on access |
| Device | `.device` | Kernel device |
| Slice | `.slice` | Resource management group |

```bash
# List all units of a specific type
systemctl list-units --type=service
systemctl list-units --type=target
systemctl list-units --type=timer

# List ALL units (all types)
systemctl list-units

# List all unit files (even inactive)
systemctl list-unit-files
```

### Where Unit Files Live

```bash
# System units (shipped by packages)
ls /usr/lib/systemd/system/

# System administrator overrides
ls /etc/systemd/system/

# Runtime units (lost on reboot)
ls /run/systemd/system/
```

**Priority:** `/etc/systemd/system/` overrides `/usr/lib/systemd/system/`. This is how you customize without editing package files.

---

## 🔍 Section 4: Creating a Custom Service

A systemd service file has three main sections: `[Unit]`, `[Service]`, and `[Install]`.

### Anatomy of a Service File

```bash
# Example: Create a simple "hello-server" service
sudo cat /etc/systemd/system/hello.service
```

```ini
[Unit]
Description=Hello World Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=/opt/hello
ExecStart=/usr/local/bin/hello-server
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Explanation of Key Directives

**`[Unit]` section:**

| Directive | Purpose |
|-----------|---------|
| Description | Human-readable name |
| After | Ordering: start AFTER this unit |
| Before | Ordering: start BEFORE this unit |
| Requires | Hard dependency (if this fails, unit fails) |
| Wants | Soft dependency (best-effort) |
| Conflicts | Cannot run with this unit |

**`[Service]` section:**

| Directive | Purpose |
|-----------|---------|
| Type | simple, forking, oneshot, notify, dbus, idle |
| ExecStart | Command to start the service (full path) |
| ExecStop | Command to stop the service |
| ExecReload | Command to reload config |
| User | Run as this user (security!) |
| Group | Run with this group |
| WorkingDirectory | CD to this directory before running |
| Restart | When to restart: always, on-failure, on-abnormal, no |
| RestartSec | Seconds to wait before restart |
| Environment | Set environment variable (KEY=value) |
| StandardOutput | Where stdout goes (journal, syslog, file) |
| StandardError | Where stderr goes |

**`[Install]` section:**

| Directive | Purpose |
|-----------|---------|
| WantedBy | Creates a symlink in `.wants/` directory |
| RequiredBy | Creates a symlink in `.requires/` directory |
| Alias | Alternative name for the unit |

### Service Types Explained

```bash
# Type=simple (default)
# - ExecStart starts the main process
# - systemd considers the service started immediately

# Type=forking
# - The process forks (child continues, parent exits)
# - systemd waits for the parent to exit
# - Required for traditional daemons (sshd, httpd)
# - MUST specify PIDFile so systemd can track the child

# Type=oneshot
# - Runs once and exits
# - systemd considers it active while running, then inactive
# - Used for setup/cleanup tasks
# - Add RemainAfterExit=yes to keep it "active"

# Type=notify
# - The process sends sd_notify() when ready
# - Most modern, precise
```

### Complete Example: A Script That Runs Once at Boot

```ini
[Unit]
Description=Custom initialization script
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/custom-init.sh
RemainAfterExit=yes
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

### Creating the Service Step by Step

```bash
# 1. Create the script
sudo tee /usr/local/bin/hello-server << 'EOF'
#!/bin/bash
while true; do
    echo "Hello from systemd service at $(date)"
    sleep 60
done
EOF

sudo chmod +x /usr/local/bin/hello-server

# 2. Create the service file
sudo tee /etc/systemd/system/hello.service << 'EOF'
[Unit]
Description=Hello World Service

[Service]
Type=simple
ExecStart=/usr/local/bin/hello-server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 3. Reload systemd (required after creating/editing unit files)
sudo systemctl daemon-reload

# 4. Enable and start
sudo systemctl enable --now hello

# 5. Verify
systemctl status hello
journalctl -u hello -n 5
```

---

## 🔍 Section 5: Viewing and Managing Services

### Listing and Filtering Services

```bash
# All running services
systemctl list-units --type=service --state=running

# All failed services
systemctl list-units --type=service --state=failed

# All enabled services
systemctl list-unit-files --type=service --state=enabled

# All disabled services
systemctl list-unit-files --type=service --state=disabled

# Services that failed recently
systemctl --failed
```

### Service Dependencies

```bash
# Show what a service depends on
systemctl list-dependencies nginx

# Show what depends on a service
systemctl list-dependencies --reverse nginx
```

### Editing Service Files Safely

```bash
# Method 1: Full override (creates a new file in /etc)
sudo systemctl edit --full nginx
# Opens an editor with the full service file
# Saves to /etc/systemd/system/nginx.service

# Method 2: Drop-in override (adds to existing)
sudo systemctl edit nginx
# Creates /etc/systemd/system/nginx.service.d/override.conf
# Only the directives you specify override the original

# View drop-in overrides
systemctl cat nginx
```

### Using Drop-in Overrides

```bash
# Instead of editing the system unit file:
# 1. Create a drop-in directory and file
sudo mkdir -p /etc/systemd/system/nginx.service.d/
sudo tee /etc/systemd/system/nginx.service.d/custom.conf << 'EOF'
[Service]
Restart=always
RestartSec=10
EOF

# 2. Reload
sudo systemctl daemon-reload

# 3. Check the merged configuration
systemctl cat nginx
```

---

## 🔍 Section 6: Targets — The Modern Runlevel

Systemd targets replace SysV runlevels.

### Runlevel to Target Mapping

| SysV Runlevel | systemd Target | Purpose |
|---|---|---|
| 0 | poweroff.target | Shut down |
| 1 | rescue.target | Single-user mode (maintenance) |
| 2, 3, 4 | multi-user.target | Multi-user, text mode (no GUI) |
| 5 | graphical.target | Multi-user with GUI |
| 6 | reboot.target | Reboot |

### Managing Targets

```bash
# Current default target
systemctl get-default

# Set default target (what boots by default)
sudo systemctl set-default multi-user.target

# Boot into rescue mode next time
sudo systemctl set-default rescue.target

# Change target right now (without reboot)
sudo systemctl isolate multi-user.target

# List all targets and their state
systemctl list-units --type=target
```

### Emergency vs Rescue Mode

```bash
# rescue.target — single user, basic services, file systems mounted
# emergency.target — only a shell, root fs read-only, nothing else

# Boot into rescue:
sudo systemctl rescue

# Boot into emergency:
sudo systemctl emergency
```

---

## 🔍 Section 7: Journald — systemd's Logging System

journald is the logging component of systemd. It replaces syslog with a structured, binary log format.

### Basic journalctl Usage

```bash
# View all logs (from most recent boot)
journalctl

# Follow new log entries (like tail -f)
journalctl -f

# Show last N lines
journalctl -n 50

# Logs from current boot only
journalctl -b

# Logs from previous boot
journalctl -b -1

# Logs from a specific service
journalctl -u nginx

# Logs from multiple services
journalctl -u nginx -u sshd

# Logs since a specific time
journalctl --since "2024-01-15 10:00:00"
journalctl --since "1 hour ago"
journalctl --since yesterday

# Logs until a time
journalctl --until "2024-01-15 12:00:00"
```

### Filtering by Priority

```bash
# Emergency (0) through Debug (7)
journalctl -p err          # Errors and worse
journalctl -p warning      # Warnings and worse
journalctl -p info         # Info and worse (default)

# Only errors from nginx
journalctl -u nginx -p err
```

### Output Formats

```bash
# JSON output
journalctl -u nginx -o json

# Short (default, one line per entry)
journalctl -u nginx -o short

# Verbose (all fields)
journalctl -u nginx -o verbose

# With no pager (pipe to file)
journalctl -u nginx --no-pager
```

### Journal Size and Persistence

```bash
# Check journal disk usage
journalctl --disk-usage

# Show journal settings
systemctl show systemd-journald

# Limit journal size (in /etc/systemd/journald.conf):
# SystemMaxUse=500M
# MaxRetentionSec=1month
```

By default, journald stores logs in memory (`/run/log/journal`). To make logs persistent:

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

---

## 🔍 Section 8: Analyzing Boot Performance

systemd-analyze is a powerful tool for understanding boot time.

```bash
# Total boot time
systemd-analyze

# Time each unit took to start
systemd-analyze blame

# Dependency tree with timings (critical chain)
systemd-analyze critical-chain

# SVG visualization of boot
systemd-analyze plot > boot.svg

# Boot time per service (sorted)
systemd-analyze blame | head -20
```

### Example Output

```
$ systemd-analyze
Startup finished in 2.345s (kernel) + 8.123s (initrd) + 12.456s (userspace) = 22.924s

$ systemd-analyze blame
          5.234s NetworkManager-wait-online.service
          3.456s apt-daily-upgrade.service
          2.123s fstrim.service
          1.456s man-db.service
          1.234s snapd.service
          ...
```

---

## 🔍 Section 9: Systemd Timers — Modern Cron

systemd timers are the modern replacement for cron. They offer calendar-based and monotonic scheduling.

### Timer Unit Structure

A timer needs two files:

1. **Timer file** (`.timer`) — defines the schedule
2. **Service file** (`.service`) — defines what to run

### Calendar Timer Example

```ini
# /etc/systemd/system/daily-backup.timer
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/daily-backup.service
[Unit]
Description=Daily backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

### Monotonic Timer Example

```ini
[Timer]
OnBootSec=5min       # Run 5 minutes after boot
OnUnitActiveSec=1h   # Run 1 hour after last activation

# Other options:
# OnStartupSec=     — after systemd starts
# OnActiveSec=      — after timer unit becomes active
# OnUnitInactiveSec — after service becomes inactive
```

### Timer Schedule Syntax

```bash
# OnCalendar= syntax:
OnCalendar=*-*-*                      # Every day
OnCalendar=*-*-* 00:00:00            # Daily at midnight
OnCalendar=Mon *-*-* 09:00:00        # Every Monday at 9 AM
OnCalendar=*-*-1..7 04:00:00         # First week of month at 4 AM
OnCalendar=hourly                    # Every hour
OnCalendar=daily                     # Every day
OnCalendar=weekly                    # Every week
OnCalendar=monthly                   # Every month
```

### Managing Timers

```bash
# List all timers
systemctl list-timers

# List all timers (including inactive)
systemctl list-timers --all

# Start/enable a timer
sudo systemctl enable --now daily-backup.timer

# Check timer status
systemctl status daily-backup.timer

# View timer information
systemctl show daily-backup.timer
```

### Systemd Timer vs Cron

| Feature | cron | systemd timer |
|---------|------|---------------|
| Schedule | Fixed minute/hour/day/month | Calendar or relative (monotonic) |
| Dependencies | None | Full systemd dependency system |
| Logging | Mail or syslog | Journald (automatic) |
| Random delay | No | RandomizedDelaySec= |
| Persistent | No | Persistent=yes (catch up after downtime) |
| Missed runs | Lost | Can catch up (Persistent=true) |
| Environment | Limited | Full environment control |

### Add Random Delay

```ini
[Timer]
OnCalendar=daily
RandomizedDelaySec=1h    # Run at a random time within the hour
```

This prevents all daily tasks from running at exactly midnight.

---

## ⭐ Level 3: Advanced — Debugging and Deep Internals

> **Level 3 Goal:** Debug failed services, implement socket activation, manage resource limits with cgroups, and understand systemd's internals including the dependency graph, directory structure, journal binary format, and control groups.

---

## 🔍 Section 10: Debugging Failed Services

### Finding Failed Services

```bash
# Show ALL failed units
systemctl --failed

# Show only failed services
systemctl list-units --type=service --state=failed
```

### Investigating a Failure

```bash
# 1. Check status
systemctl status nginx

# 2. Check journal for the service
journalctl -u nginx -n 50 --no-pager

# 3. Check journal since last boot
journalctl -u nginx -b

# 4. Follow the journal while trying to start
sudo systemctl start nginx
journalctl -u nginx -f
```

### Common Failure Reasons

```bash
# 1. Permission denied
# Check: ExecStart path has correct permissions
# Fix: chmod +x /path/to/executable

# 2. Port already in use
# Check: journalctl -u nginx
# Fix: Change port or stop conflicting service

# 3. Missing dependency
# Check: systemctl list-dependencies nginx

# 4. Timeout (service didn't start in time)
# Fix: Add TimeoutStartSec= in [Service] section
```

### Service Restart Policies

```ini
[Service]
Restart=on-failure    # Restart only on failure (exit code != 0)
Restart=always        # Restart even on clean exit
Restart=on-abnormal   # Restart on signal, timeout, watchdog
Restart=on-abort      # Restart on uncaught signal
Restart=no            # Never restart (default)

# Controls how often to retry
StartLimitBurst=5     # Max failures in interval
StartLimitIntervalSec=10  # Interval in seconds
```

### Manual Reset After Limit

```bash
# If a service hits the start limit:
# "start-limit-hit" — service won't try again
# Reset with:
sudo systemctl reset-failed nginx
```

---

## 🔍 Section 11: Systemd Sockets — Activation on Demand

Socket activation means a service starts only when something connects to its socket.

### How It Works

```
1. systemd creates and listens on the socket
2. Client connects
3. systemd starts the service
4. systemd passes the socket to the service
5. Service handles the client
6. After inactivity, systemd stops the service (optional)
```

### Example: SSH Socket Activation

```bash
# SSH has both sshd.service and sshd.socket
# With socket activation:
# - sshd.socket listens on port 22 at boot
# - sshd.service starts only when someone connects

# Enable socket activation
sudo systemctl disable sshd.service
sudo systemctl enable --now sshd.socket
```

### Creating a Socket-Activated Service

```ini
# /etc/systemd/system/echo.socket
[Unit]
Description=Echo socket

[Socket]
ListenStream=2000
Accept=yes

[Install]
WantedBy=sockets.target
```

```ini
# /etc/systemd/system/echo@.service
[Unit]
Description=Echo service for %i

[Service]
Type=simple
ExecStart=/usr/local/bin/echo-server
StandardInput=socket
StandardOutput=socket
```

---

## 🔍 Section 12: Resource Control with systemd

systemd can limit CPU, memory, and I/O for services using control groups (cgroups).

```ini
[Service]
# CPU limits
CPUAccounting=yes
CPUQuota=50%               # Max 50% of one CPU

# Memory limits
MemoryAccounting=yes
MemoryMax=512M             # Max 512 MB memory
MemoryHigh=256M            # Memory throttle limit
MemoryLow=128M             # Memory guarantee

# I/O limits
IOAccounting=yes
IOWeight=100               # I/O priority (100-1000)

# Process limits
TasksMax=100               # Max number of tasks/threads

# File descriptor limits
LimitNOFILE=4096           # Max open files
LimitNPROC=100             # Max user processes
```

### Check Current Resource Usage

```bash
# Show resource usage for a service
systemctl show nginx -p MemoryCurrent
systemctl show nginx -p CPUUsageNSec

# Show cgroup
systemctl status nginx
# Look at the CGroup section
```

---

## 🧠 Deep Understanding — How systemd Really Works

### The Dependency Graph

systemd doesn't run things in order. It builds a dependency graph:

```
                  multi-user.target
                 /        |         \
          network.target  |    sshd.service
               |          |         |
     NetworkManager   cron.service  |
               |                    |
   network-online.target     network.target (already satisfied)
```

systemd resolves this graph and starts everything in parallel where possible.

### The /etc/systemd/system/ Directory Structure

```bash
ls -la /etc/systemd/system/

# multi-user.target.wants/          ← services enabled for this target
# basic.target.wants/               ← services enabled for basic.target
# network-online.target.wants/      ← services for network readiness
# sockets.target.wants/             ← socket-activated services
# timers.target.wants/              ← timer units
# *.service.d/                      ← drop-in override directories
```

When you `systemctl enable nginx`, systemd creates a symlink:

```
/etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service
```

This is how "enable" works — it's just a symlink!

### The systemd Journal Binary Format

The journal is NOT text files. It's a binary format:

```bash
file /var/log/journal/*/system.journal
# Output: "system.journal: data"

# Advantages:
# - Structured fields (not just text)
# - Signed entries (tamper-evident)
# - Fast indexed search
# - Automatic log rotation

# To export as text to legacy syslog:
journalctl -o export > journal_export.txt
```

### Control Groups (cgroups)

systemd uses cgroups v2 to track and limit processes:

```bash
# Every service gets its own cgroup
ls /sys/fs/cgroup/system.slice/
# nginx.service  sshd.service  cron.service  ...

# Show cgroup of a service
systemctl show -p ControlGroup nginx

# The cgroup ensures:
# - When you stop a service, ALL its child processes die
# - Resource limits apply to the entire process tree
# - Clean accounting of CPU/memory/IO
```

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### ✅ Level 1: Basic Practices

---

### ✅ Practice 1: Explore Your Init System

```bash
mkdir -p ~/linux-course/part12
cd ~/linux-course/part12

# Confirm systemd is your init system
ls -l /sbin/init
cat /proc/1/comm

# Check systemd version
systemctl --version

# How long did boot take?
systemd-analyze
```

---

### ✅ Practice 2: Service Status Deep Dive

```bash
# Pick a running service (sshd, cron, NetworkManager, etc.)
systemctl status cron

# Answer these questions:
# - Is it enabled? (starts at boot?)
# - Is it active? (running right now?)
# - What is the Main PID?
# - How long has it been running?
# - What resources is it using?

# Save the output
systemctl status cron > service_status.txt
```

---

### ✅ Practice 3: Start, Stop, Restart

```bash
# Create a simple test service using cron (safe to experiment with)
sudo systemctl stop cron
systemctl status cron    # Should show inactive

sudo systemctl start cron
systemctl status cron    # Should show active

sudo systemctl restart cron
systemctl status cron    # Should show active again

# Always leave it running
sudo systemctl enable --now cron
```

---

### ✅ Practice 4: Enable and Disable

```bash
# Check if cron is enabled
systemctl is-enabled cron

# Disable it (won't start on next boot)
sudo systemctl disable cron
systemctl is-enabled cron

# Re-enable it
sudo systemctl enable cron
systemctl is-enabled cron
```

---

### ✅ Level 2: Intermediary Practices

---

### ✅ Practice 5: List All Services

```bash
# Count all services
echo "Total service units:"
systemctl list-unit-files --type=service | wc -l

# Count running services
echo "Running services:"
systemctl list-units --type=service --state=running | grep -c running

# Count failed services
echo "Failed services:"
systemctl list-units --type=service --state=failed | grep -c failed

# List all enabled services
systemctl list-unit-files --type=service --state=enabled | head -30
```

---

### ✅ Practice 6: Create a Custom Service

```bash
cd ~/linux-course/part12

# Step 1: Create the script
cat > hello-daemon.sh << 'EOF'
#!/bin/bash
while true; do
    echo "[$(date)] Hello from systemd service"
    sleep 30
done
EOF

chmod +x hello-daemon.sh
sudo cp hello-daemon.sh /usr/local/bin/

# Step 2: Create service file
sudo tee /etc/systemd/system/hello-daemon.service << 'EOF'
[Unit]
Description=Hello Daemon - Learning systemd

[Service]
Type=simple
ExecStart=/usr/local/bin/hello-daemon.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Step 3: Reload systemd
sudo systemctl daemon-reload

# Step 4: Start it
sudo systemctl start hello-daemon
systemctl status hello-daemon

# Step 5: Check the logs
journalctl -u hello-daemon -n 5
```

---

### ✅ Practice 7: Enable/Disable Your Custom Service

```bash
# Enable it to start at boot
sudo systemctl enable hello-daemon
systemctl is-enabled hello-daemon

# Reboot note: Ideally we'd reboot, but for now:
# Just verify it's enabled
systemctl list-unit-files | grep hello
```

---

### ✅ Practice 8: Stop and Remove the Service

```bash
# Stop it
sudo systemctl stop hello-daemon
systemctl status hello-daemon

# Disable it
sudo systemctl disable hello-daemon

# Remove the service file
sudo rm /etc/systemd/system/hello-daemon.service
sudo systemctl daemon-reload

# Remove the script
sudo rm /usr/local/bin/hello-daemon.sh
```

---

### ✅ Practice 9: Explore Targets

```bash
# Current default target
systemctl get-default

# List all targets
systemctl list-units --type=target

# What does multi-user.target require?
systemctl list-dependencies multi-user.target | head -20

# What does graphical.target require?
systemctl list-dependencies graphical.target | head -20

# See the difference (graphical adds display manager)
```

---

### ✅ Practice 10: Journalctl Deep Dive

```bash
# Check journal size and limits
journalctl --disk-usage

# Is journal persistent?
ls -la /var/log/journal/ 2>/dev/null || echo "Journal is NOT persistent"

# Show messages from current boot
journalctl -b --no-pager | wc -l

# Show kernel messages
journalctl -k --no-pager | head -20

# Show messages from the cron service
journalctl -u cron -n 10

# Follow logs for a few seconds
timeout 3 journalctl -f || true
```

---

### ✅ Practice 11: Filter Journal by Time and Priority

```bash
# Errors from today
journalctl --since "00:00:00" -p err --no-pager | head -20

# Warnings from last hour
journalctl --since "1 hour ago" -p warning --no-pager | head -20

# All journal entries for a specific PID
# (pick a PID from systemctl status cron)
systemctl status cron | grep "Main PID"
PID=$(systemctl status cron | grep "Main PID" | awk '{print $3}')
journalctl _PID=$PID -n 10 --no-pager
```

---

### ✅ Practice 12: Boot Analysis

```bash
# Time breakdown
systemd-analyze

# Which services take longest?
systemd-analyze blame | head -15

# Critical chain (dependency path)
systemd-analyze critical-chain

# Generate a plot (if you have a display)
systemd-analyze plot > boot_plot.svg 2>/dev/null
ls -la boot_plot.svg
```

---

### ✅ Practice 13: Create a systemd Timer

```bash
cd ~/linux-course/part12

# Step 1: Create the service (what to run)
sudo tee /etc/systemd/system/hello-timer.service << 'EOF'
[Unit]
Description=Hello Timer Service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Timer ran at $(date)" | systemd-cat -t hello-timer'
EOF

# Step 2: Create the timer (when to run)
sudo tee /etc/systemd/system/hello-timer.timer << 'EOF'
[Unit]
Description=Run hello every minute

[Timer]
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Step 3: Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now hello-timer.timer

# Step 4: Check it
systemctl list-timers --all | grep hello
sleep 70

# Step 5: Check the log
journalctl -t hello-timer -n 5

# Step 6: Disable and remove
sudo systemctl disable --now hello-timer.timer
sudo rm /etc/systemd/system/hello-timer.*
sudo systemctl daemon-reload
```

---

### ✅ Level 3: Advanced Practices

---

### ✅ Practice 14: Investigate Service Dependencies

```bash
# What does NetworkManager depend on?
systemctl list-dependencies NetworkManager

# What depends on network.target?
systemctl list-dependencies --reverse network.target

# What depends on multi-user.target?
systemctl list-dependencies --reverse multi-user.target | head -20
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Service Health Check

```bash
cd ~/linux-course/part12

cat > service_health_check.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="service_health_report.txt"

echo "============================================" > "$REPORT"
echo "  SERVICE HEALTH CHECK REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Check failed services
echo "[*] Checking for failed services..." >> "$REPORT"
FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [ "$FAILED" -eq 0 ]; then
    echo "  No failed services found. ✓" >> "$REPORT"
else
    echo "  WARNING: $FAILED failed service(s) found!" >> "$REPORT"
    systemctl --failed --no-legend >> "$REPORT"
fi
echo "" >> "$REPORT"

# List critical services and their status
echo "[*] Critical service status:" >> "$REPORT"
for svc in sshd cron nginx apache2 httpd NetworkManager systemd-journald; do
    STATUS=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
    ENABLED=$(systemctl is-enabled "$svc" 2>/dev/null || echo "not-found")
    printf "  %-35s Active: %-12s Enabled: %s\n" "$svc" "$STATUS" "$ENABLED" >> "$REPORT"
done
echo "" >> "$REPORT"

# Boot time
echo "[*] Boot performance:" >> "$REPORT"
systemd-analyze 2>/dev/null >> "$REPORT"
echo "" >> "$REPORT"

# Slowest services
echo "[*] Slowest services at boot:" >> "$REPORT"
systemd-analyze blame 2>/dev/null | head -10 >> "$REPORT"
echo "" >> "$REPORT"

# Journal disk usage
echo "[*] Journal disk usage:" >> "$REPORT"
journalctl --disk-usage 2>/dev/null >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x service_health_check.sh
./service_health_check.sh
```

---

## 📋 Summary — Complete Command Reference for Part 12

### Level 1: Basic Commands — Service Management

| Command | Action |
|---------|--------|
| `systemctl start NAME` | Start a service |
| `systemctl stop NAME` | Stop a service |
| `systemctl restart NAME` | Restart a service |
| `systemctl reload NAME` | Reload config without restart |
| `systemctl status NAME` | Show detailed status |
| `systemctl enable NAME` | Enable at boot |
| `systemctl disable NAME` | Disable at boot |
| `systemctl enable --now NAME` | Enable and start |
| `systemctl is-active NAME` | Check if running |
| `systemctl is-enabled NAME` | Check if enabled at boot |
| `systemctl mask NAME` | Prevent any start |
| `systemctl unmask NAME` | Restore after mask |
| `systemctl --failed` | Show all failed units |

### Level 2: Intermediary Commands — Listing, Journalctl, Timers

**Listing and Querying**

| Command | Action |
|---------|--------|
| `systemctl list-units` | List all active units |
| `systemctl list-unit-files` | List all unit files |
| `systemctl list-dependencies NAME` | Show dependency tree |
| `systemctl list-timers` | Show timer units |
| `systemctl get-default` | Show default target |
| `systemctl set-default NAME` | Set default target |
| `systemctl isolate NAME` | Switch to target now |

**Service File Sections**

| Section | Contains |
|---------|----------|
| `[Unit]` | Description, dependencies, ordering |
| `[Service]` | ExecStart, User, Restart, limits |
| `[Install]` | WantedBy, RequiredBy |

**Journalctl**

| Command | Action |
|---------|--------|
| `journalctl` | Show all logs |
| `journalctl -u NAME` | Logs for a specific unit |
| `journalctl -f` | Follow new entries |
| `journalctl -n N` | Show last N lines |
| `journalctl -b` | Current boot only |
| `journalctl -b -1` | Previous boot |
| `journalctl --since TIME` | Since a specific time |
| `journalctl -p PRIORITY` | Filter by priority |
| `journalctl --disk-usage` | Show journal size |

**systemd-analyze**

| Command | Action |
|---------|--------|
| `systemd-analyze` | Show boot time |
| `systemd-analyze blame` | Time per service |
| `systemd-analyze critical-chain` | Dependency timing |
| `systemd-analyze plot` | SVG visualization |

### Level 3: Advanced Commands (No additional commands — see debugging and resource control sections above)

---

## 🚀 What's Coming in Part 13

**Part 13: Scheduling Tasks — cron, at, systemd timers**

You will learn:
- Classic cron — the Unix standard for recurring tasks
- crontab syntax and management
- The `at` command — one-time scheduling
- Systemd timers — the modern alternative
- Best practices for scheduled tasks
- Monitoring and troubleshooting scheduled jobs
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between `systemctl start` and `systemctl enable`?
2. What is a systemd "unit"? Name at least 4 types.
3. Where do system distribution unit files live? Where do admin overrides go?
4. What does `systemctl daemon-reload` do and when must you run it?
5. What is the difference between `Type=simple` and `Type=forking` in a service file?
6. What does `Restart=on-failure` do?
7. How do you view logs for a specific service?
8. What is a systemd target and how does it relate to old SysV runlevels?
9. What is the difference between `journalctl -u nginx` and `tail /var/log/nginx/access.log`?
10. How do you create a systemd timer?
11. What does `systemd-analyze blame` show?
12. What is the difference between masking and disabling a service?
13. How do you prevent a service from being started accidentally?
14. What is a drop-in override and why is it safer than editing the unit file directly?
15. How does systemd track all processes of a service even if they fork?

**Score:** 12/15 correct = ready for Part 13.

---

*Linux SysAdmin Course | Part 12 of ∞ | Reverse Engineering Approach*
*Previous → Part 11: Package Management — apt, dnf, yum, snap*
*Next → Part 13: Scheduling Tasks — cron, at, systemd timers*

[← Previous](part11.md) | [Next →](part13.md)
