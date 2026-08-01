# Golden Content Master Reference — Linux System Administration

> A consolidated collection of golden quotes, tricks, mnemonics, formulas, and rules of thumb across all 66 modules.

---

## Table of Contents

1. [Golden Quotes](#golden-quotes)
2. [Tricks & Mnemonics](#tricks--mnemonics)
3. [Formulas & Calculations](#formulas--calculations)
4. [Rules of Thumb](#rules-of-thumb)

---

# Golden Quotes

## UNIX Philosophy & Linux Foundations

> "Everything is a file."
> — **Ken Thompson & Dennis Ritchie**, *UNIX philosophy*

> "Do one thing and do it well."
> — **Doug McIlroy**, *UNIX philosophy*

> "Talk is cheap. Show me the code."
> — **Linus Torvalds**, *Linux Kernel Mailing List*

> "Bad programmers worry about the code. Good programmers worry about data structures and their relationships."
> — **Linus Torvalds**

> "Software is like sex: it's better when it's free."
> — **Linus Torvalds**

> "Only wimps use tape backup: real men just send their hard drives to the U.S. and let them sort it out."
> — **Linus Torvalds**

> "I'm not a visionary. I'm an engineer."
> — **Linus Torvalds**

> "The Linux philosophy is 'Laugh in the face of danger'. Oops. Wrong one. 'Do it yourself'. That one."
> — **Linus Torvalds**

## System Administration

> "The only constant in IT is change."
> — **Common sysadmin wisdom**

> "It works on my machine" is not a deployment strategy.
> — **DevOps proverb**

> "Automate everything you do more than once."
> — **Sysadmin rule**

> "The first rule of any technology used in a business is that automation applied to an efficient operation will magnify the efficiency. The second is that automation applied to an inefficient operation will magnify the inefficiency."
> — **Bill Gates**

> "Availability is the absence of unavailability."
> — **SRE wisdom**

> "Hope is not a strategy."
> — **Google SRE Book**

> "The three most important things in IT: backups, backups, backups."
> — **Sysadmin proverb**

## Security

> "Security is not a product; it is a process."
> — **Bruce Schneier**, *Applied Cryptography*

> "Security is always excessive until it's not enough."
> — **Roberto Nacci**

> "The attacker needs to be right only once. The defender needs to be right every time."
> — **Security axiom**

> "Trust, but verify."
> — **Ronald Reagan** (applied to IT)

> "Least privilege is the art of saying 'no' to power."
> — **Security principle**

## Networking & Infrastructure

> "The network is reliable." — **Fallacies of Distributed Computing** (L. Peter Deutsch)

> "Latency is everywhere, and once you can't hide it, you can make it your friend."
> — **Baron Schwartz**, *High Performance MySQL*

> "There are only two hard things in Computer Science: cache invalidation and naming things."
> — **Phil Karlton**

> "Premature optimization is the root of all evil."
> — **Donald Knuth**

## Containers & Cloud

> "Containers are not lightweight VMs. They are process isolation."
> — **Container wisdom**

> "Treat your servers like cattle, not pets."
> — **DevOps proverb**

> "If it's not in source control, it doesn't exist."
> — **DevOps principle**

> "Move fast and break things."
> — **Mark Zuckerberg** (but not in production)

> "You build it, you run it."
> — **Werner Vogels**, *Amazon CTO*

## Monitoring & Reliability

> "You can't fix what you can't see."
> — **Monitoring wisdom**

> "The four golden signals: latency, traffic, errors, saturation."
> — **Google SRE Book**

> "Alert on symptoms, not causes."
> — **SRE principle**

> "Hope is not a strategy."
> — **Google SRE Book**

> "The cost of downtime is not just technical — it's reputational."
> — **Business continuity principle**

---

# Tricks & Mnemonics

## Module 02: Terminal Navigation

### LHTR = Long, Human, Time, Reverse
The four most useful `ls` flags:
```bash
ls -lhtr   # Long format, human-readable, sort by time, reverse (newest last)
```

### Path Mnemonics
- `.` = "here" (current directory)
- `..` = "up one" (parent directory)
- `~` = "home" (your home directory)
- `-` = "back" (previous directory)

## Module 03: Permissions

### UGO = User, Group, Others
The three permission buckets:
```bash
chmod u+x file    # User: add execute
chmod g+w file    # Group: add write
chmod o-r file    # Others: remove read
```

### rwx = 421
The permission calculation:
```bash
r = 4    # read
w = 2    # write
x = 1    # execute

# Common combinations:
644 = rw-r--r--    # Regular files
755 = rwxr-xr-x    # Executables/scripts
700 = rwx------    # Private (SSH keys)
600 = rw-------    # Private config
```

### Permission String Decoder
```
-rwxr-xr-x
│├─┤├─┤├─┤
│ │  │  └── Others: r-x = 5
│ │  └───── Group:  r-x = 5
│ └──────── Owner:  rwx = 7
└────────── Type:   - = file, d = directory
```

## Module 05: Pipes & Redirection

### 0-1-2 = stdin, stdout, stderr
```bash
command < input.txt        # 0: stdin from file
command > output.txt       # 1: stdout to file
command 2> errors.txt      # 2: stderr to file
command > all.txt 2>&1     # Both stdout and stderr to file
```

### GREATER = Overwrite, GREATER-GREATER = Append
```bash
> file.txt    # Overwrites (dangerous!)
>> file.txt   # Appends (safer)
```

### TEE = Split output
```bash
command | tee output.txt    # Show on screen AND save to file
```

## Module 07: Finding Things

### grep Options: IRC-VL
```bash
-i    # Case Insensitive
-r    # Recursive
-c    # Count matches
-v    # Invert (exclude matches)
-l    # Filenames only
-n    # Line Numbers
```

### find + xargs Pattern
```bash
# Safe for filenames with spaces:
find . -name "*.log" -print0 | xargs -0 rm

# Count lines in all .log files:
find . -name "*.log" -print0 | xargs -0 wc -l
```

### find Time Math
```bash
-mtime -7    # Modified in last 7 days
-mtime +30   # More than 30 days ago
-mtime -1    # Modified today
```

## Module 09: Process Management

### Signal Numbers: 1-9-15
```bash
kill -1 PID     # SIGHUP: reload config
kill -9 PID     # SIGKILL: force kill (last resort)
kill -15 PID    # SIGTERM: graceful shutdown (default)
```

### Kill Sequence
```bash
# Step 1: Ask nicely
kill PID

# Step 2: Wait 5 seconds
sleep 5

# Step 3: Force if still running
kill -9 PID
```

### Process State Codes
```
R = Running
S = Sleeping (interruptible)
D = Uninterruptible sleep (I/O)
Z = Zombie (completed, not reaped)
T = Stopped
```

## Module 10: Boot Process

### PBGSL = Power, BIOS, GRUB, Systemd, Login
```bash
1. Power On → BIOS/UEFI (POST)
2. BIOS → GRUB bootloader
3. GRUB → Kernel + initramfs
4. Kernel → systemd (PID 1)
5. systemd → Login prompt
```

### systemd Targets (replacing runlevels)
```bash
multi-user.target    # Runlevel 3 (text mode)
graphical.target     # Runlevel 5 (GUI)
rescue.target        # Runlevel 1 (single user)
emergency.target     # Minimal shell
```

## Module 11: Package Management

### Debian = apt = .deb
```bash
apt update          # Update package lists
apt upgrade         # Install updates
apt install pkg     # Install package
apt remove pkg      # Remove (keep config)
apt purge pkg       # Remove everything
```

### Red Hat = dnf = .rpm
```bash
dnf check-update    # Check for updates
dnf upgrade         # Install updates
dnf install pkg     # Install package
dnf remove pkg      # Remove package
rpm -qa             # List all packages
```

### The Cardinal Rule
```bash
# ALWAYS update lists before upgrading:
apt update && apt upgrade -y

# NOT:
apt upgrade -y    # This may fail or use stale lists
```

## Module 15: SSH

### 700-600-644 = SSH Permission Trinity
```bash
chmod 700 ~/.ssh              # Directory: owner only
chmod 600 ~/.ssh/id_ed25519   # Private key: owner only
chmod 644 ~/.ssh/id_ed25519.pub  # Public key: readable
```

### SSH Key Types
```bash
# Ed25519 (recommended):
ssh-keygen -t ed25519 -C "email@example.com"

# RSA (legacy compatibility):
ssh-keygen -t rsa -b 4096 -C "email@example.com"
```

## Module 18: Environment Variables

### E-B-R = Startup File Order
```bash
# Login shell reads:
/etc/profile           # E: System-wide
~/.bash_profile        # B: User (or .bash_login or .profile)
~/.bashrc              # R: Shell config

# Interactive non-login reads:
~/.bashrc              # Only this
```

### Golden Rule
```bash
# ~/.bashrc    = aliases, functions, prompt (behavior)
# ~/.bash_profile = environment variables, PATH (identity)
```

## Module 21: Time Synchronization

### NTP Offset Formula
```
offset = ((T2-T1) + (T3-T4)) / 2

T1: Client sends request
T2: Server receives request
T3: Server sends response
T4: Client receives response
```

### chronyc Status Symbols
```bash
*    # Current sync source
+    # Candidate (good)
-    # Rejected
?    # Unreachable
x    # Selected, but distance exceeded
```

## Module 27: DNS

### DNS Record Types: ACMENST
```bash
A       # Address (IPv4)
CNAME   # Canonical Name (alias)
MX      # Mail exchange
NS      # Nameserver
SOA     # Start of Authority
TXT     # Text record (SPF, DKIM)
AAAA    # IPv6 address
PTR     # Pointer (reverse DNS)
```

### dig vs getent
```bash
# dig bypasses /etc/hosts (queries DNS directly):
dig example.com

# getent uses nsswitch (checks hosts file first):
getent hosts example.com
```

## Module 30: RAID

### RAID Levels Mnemonic
```
0 = Zero protection (all risk)
1 = One copy (mirror)
5 = One parity drive
6 = Two parity drives
10 = Mirror + Stripe (best performance)
```

### Write Penalty
```
RAID 5: 4x write penalty
  (read old data + read old parity + write new data + write new parity)

RAID 6: 6x write penalty
  (read old data + read old parity1 + read old parity2
   + write new data + write new parity1 + write new parity2)
```

## Module 36: Advanced Shell Scripting

### awk Key Variables: NR-NF-FS
```bash
NR    # Number of Records (line number)
NF    # Number of Fields (field count)
FS    # Field Separator (input)
OFS   # Output Field Separator
$0    # Entire line
$NF   # Last field
$1    # First field
```

### sed Cycle
```bash
# Every line goes through:
Read → Execute → Print

# Common operations:
sed 's/old/new/'       # Replace first occurrence
sed 's/old/new/g'      # Replace all occurrences
sed -n '10,20p'        # Print lines 10-20
sed '/pattern/d'        # Delete matching lines
```

### Unique Lines Idiom
```bash
# Like sort -u, but preserves order:
awk '!seen[$0]++' file
```

## Module 43: DHCP

### DORA = Discover, Offer, Request, Acknowledge
```
1. DISCOVER: Client broadcasts "I need an IP"
2. OFFER: Server responds "Here's IP X"
3. REQUEST: Client says "I accept IP X"
4. ACKNOWLEDGE: Server confirms "IP X is yours"
```

### Key DHCP Options
```
1  = Subnet Mask
3  = Router (Gateway)
6  = DNS Servers
12 = Hostname
15 = Domain Name
42 = NTP Servers
51 = Lease Time
```

## Module 46: Monitoring & Alerting

### rate() vs irate()
```promql
# rate() - smooth average (for alerting):
rate(http_requests_total[5m])

# irate() - instantaneous (for graphs):
irate(http_requests_total[5m])
```

### Metric Types
```promql
Counter   # Only goes up (or resets to 0)
Gauge     # Goes up and down
Histogram # Bucket distribution
Summary   # Pre-computed quantiles
```

### Four Golden Signals (Google SRE)
```
1. Latency     # How long requests take
2. Traffic     # Demand on your system
3. Errors      # Rate of failed requests
4. Saturation  # How "full" your system is
```

## Module 49: Security

### CIA = Confidentiality, Integrity, Availability
```
Confidentiality: Only authorized users can access
Integrity: Data cannot be tampered with
Availability: System is accessible when needed
```

### Mount Hardening: NEN
```bash
# /etc/fstab mount options:
nosuid    # N: No SUID/SGID
noexec    # E: No execution
nodev     # N: No device files

# Example:
/data  ext4  defaults,nosuid,noexec,nodev  0  2
```

### SUID/SGID Check
```bash
# Find all SUID binaries:
find / -perm -4000 -type f 2>/dev/null

# Find all SGID binaries:
find / -perm -2000 -type f 2>/dev/null
```

## Module 52: Kubernetes

### Control Plane: ECAS
```
etcd                 # E: Distributed state store
Controller Manager   # C: Reconciliation loops
API Server           # A: REST gateway
Scheduler            # S: Pod placement
```

### Worker Node: KKC
```
kubelet        # K: Node agent
kube-proxy     # K: Network rules
containerd     # C: Container runtime
```

### Service Types: CNLE
```
ClusterIP      # C: Internal only (default)
NodePort       # N: Static port on all nodes
LoadBalancer   # L: Cloud load balancer
ExternalName   # E: DNS CNAME
```

### CrashLoopBackOff Backoff
```
10s → 20s → 40s → 80s → 160s → 300s (max)
```

---

# Formulas & Calculations

## Permission Calculation
```
Permission = (r×4) + (w×2) + (x×1)

Example:
rwxr-xr-- = (7)(5)(4) = 754
rw-r--r-- = (6)(4)(4) = 644
rwx------ = (7)(0)(0) = 700
```

## RAID Capacity
```
RAID 0:  Total = N drives        (no redundancy)
RAID 1:  Total = N/2 drives      (full mirror)
RAID 5:  Total = (N-1) drives    (single parity)
RAID 6:  Total = (N-2) drives    (double parity)
RAID 10: Total = N/2 drives      (mirror + stripe)
```

## RAID Write Penalty
```
RAID 5: 4x write penalty
RAID 6: 6x write penalty
RAID 10: 1x write penalty (no parity calculation)
```

## Load Average
```
Healthy:  load < CPU cores
Saturated: load > CPU cores
Overloaded: load > CPU cores × 2

Example: 4-core CPU
  load 2.0  = 50% utilized
  load 4.0  = 100% utilized
  load 8.0  = 200% overloaded
```

## Memory Calculations
```
Available RAM = Total - (Buffers + Cached + Slab)
Swap usage = SwapTotal - SwapFree

Memory pressure indicator:
  If si/so > 0 sustained → need more RAM
  Swap is 1000x slower than RAM
```

## Disk I/O
```
I/O Utilization = (active_time / measurement_time) × 100%

Healthy: %util < 70%
Warning: %util 70-90%
Critical: %util > 90%

IOPS = operations per second
Throughput = IOPS × block_size
```

## Network Throughput
```
TCP throughput ≈ (window_size / RTT)

Theoretical max: bandwidth × RTT = Bandwidth-Delay Product

Example: 1 Gbps link, 10ms RTT
  BDP = 1 Gbps × 0.01s = 10 Mbit = 1.25 MB
```

## NTP Offset
```
offset = ((T2 - T1) + (T3 - T4)) / 2
delay = (T4 - T1) - (T3 - T2)

T1: Client sends request
T2: Server receives request
T3: Server sends response
T4: Client receives response
```

## Buffer Pool Hit Rate
```
Hit Rate = (read_requests - reads) / read_requests × 100

Healthy: > 99%
Warning: 95-99%
Critical: < 95%
```

## OOM Score
```
OOM_score = process_memory / total_memory × 100

Higher score = more likely to be killed
Adjustable via: /proc/PID/oom_score_adj
Range: -1000 to 1000
```

## Disk Space
```
Reserved for root: 5% (ext4 default)
Available to users: 95%

Check actual available:
  df -h          # Shows available space
  df -ih         # Shows inode availability
```

## Process Priority (nice)
```
nice range: -20 to 19
Default: 0
Lower nice = higher priority

Priority = base_priority + nice
Root can set negative nice;普通用户只能设置0-19
```

## Cron Time Fields
```
┌───────── minute (0-59)
│ ┌───────── hour (0-23)
│ │ ┌───────── day of month (1-31)
│ │ │ ┌───────── month (1-12)
│ │ │ │ ┌───────── day of week (0-7, 0=7=Sunday)
│ │ │ │ │
* * * * * command
```

## PromQL CPU Utilization
```promql
# CPU utilization percentage:
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory used percentage:
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk used percentage:
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100

# HTTP error rate:
rate(http_requests_total{code=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100
```

## Kubernetes CrashLoopBackOff
```
Backoff sequence:
10s → 20s → 40s → 80s → 160s → 300s (max)

Total wait time before restart:
Attempt 1: 10s
Attempt 2: 20s (30s total)
Attempt 3: 40s (70s total)
Attempt 4: 80s (150s total)
Attempt 5: 160s (310s total)
Attempt 6+: 300s each
```

---

# Rules of Thumb

## General System Administration

| Rule | Description |
|------|-------------|
| **Try graceful first** | SIGTERM before SIGKILL |
| **Preview before delete** | Check find results before -delete |
| **Update before upgrade** | apt update before apt upgrade |
| **Quote variables** | Always double-quote "$variable" |
| **Log everything** | Document changes and reasons |
| **Test in staging** | Never deploy未经测试代码 |
| **Backup before change** | cp file file.bak.$(date) |
| **Check logs first** | Most problems are logged |

## Performance Tuning

| Rule | Description |
|------|-------------|
| **Load < cores** | Healthy system |
| **Swap = emergency** | If sustained swap, add RAM |
| **Buffer pool > 99%** | Database hit rate |
| **%util < 70%** | Healthy disk I/O |
| **Context switches < 100K** | Normal for most systems |

## Security

| Rule | Description |
|------|-------------|
| **Least privilege** | Give only what's needed |
| **Defense in depth** | Layer security controls |
| **Default deny** | Block everything, allow what's needed |
| **Audit SUID regularly** | Common escalation vector |
| **Use key-based SSH** | Never password auth for servers |
| **700-600-644** | SSH directory, private key, public key |

## Networking

| Rule | Description |
|------|-------------|
| **Check firewall first** | Most connectivity issues |
| **Check DNS second** | Name resolution problems |
| **Check MTU third** | Packet fragmentation |
| **Check routing fourth** | Packets not reaching destination |

## Storage

| Rule | Description |
|------|-------------|
| **RAID is not backup** | RAID protects against disk failure |
| **3-2-1 backup rule** | 3 copies, 2 media types, 1 offsite |
| **Test restores** | Backup is useless if can't restore |
| **5% reserved for root** | ext4 default, prevents total lockout |
| **LVM for flexibility** | Allows online resize |

## Containers & Kubernetes

| Rule | Description |
|------|-------------|
| **One process per container** | Keep containers focused |
| **Use health checks** | Liveness and readiness probes |
| **Resource limits** | Always set CPU/memory limits |
| **Rolling updates** | Zero-downtime deployments |
| **Check logs --previous** | For CrashLoopBackOff debugging |

## Monitoring & Alerting

| Rule | Description |
|------|-------------|
| **Alert on symptoms** | Not causes |
| **rate() for alerts** | Smoothed average |
| **irate() for graphs** | Instantaneous spikes |
| **Four golden signals** | Latency, Traffic, Errors, Saturation |
| **Record rules** | Pre-compute expensive queries |

## Time Synchronization

| Rule | Description |
|------|-------------|
| **Kerberos = 5 min** | Clock must be within 5 minutes |
| **Chrony for VMs** | Better than ntpd in virtualized environments |
| **Check chronyc sources** | * = synced, + = candidate |

---

## Quick Reference Card

### Most Used Commands
```bash
# System info:
uname -a              # Kernel info
hostnamectl           # Hostname info
uptime                # Load average
free -h               # Memory usage
df -h                 # Disk usage
du -sh *              # Directory sizes

# Process management:
ps auxf               # Process tree
top -o %MEM           # Top by memory
htop                  # Interactive top
kill -TERM PID        # Graceful shutdown
kill -9 PID           # Force kill

# Networking:
ip addr               # IP addresses
ip route              # Routing table
ss -tlnp              # Listening ports
curl -I http://url    # HTTP headers
dig domain            # DNS lookup

# File operations:
ls -lhtr              # Recent files first
find . -name "*.log"  # Find files
grep -r "pattern" .   # Search contents
tar czf archive.tar.gz dir/  # Create archive
tar xzf archive.tar.gz       # Extract archive
```

### Emergency Commands
```bash
# System won't boot:
single                # GRUB: boot to single user
init=/bin/bash        # GRUB: drop to shell

# Disk full:
df -h                 # Check usage
du -sh /* | sort -rh  # Find large dirs
journalctl --vacuum-size=100M  # Clean logs

# Process stuck:
ps aux | grep D       # Find uninterruptible processes
kill -9 PID           # Force kill

# Network down:
ip link set eth0 up   # Enable interface
systemctl restart NetworkManager  # Restart networking
```

---

*This file is a master reference. Detailed content for each module is in the module's own golden-quotes.md, tricks-and-mnemonics.md, formulas-and-calculations.md, and rules-of-thumb.md files.*
