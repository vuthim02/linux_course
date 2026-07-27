# 🐧 Linux System Administrator — Complete Course
## Part 17 of ∞: SELinux and AppArmor — Mandatory Access Control

---

> **Reverse Engineering Approach:** Standard Linux permissions (owner/group/other) are Discretionary Access Control (DAC) — if you own a file, you decide who can access it. Mandatory Access Control (MAC) adds a second layer: even if the permissions say "yes," the MAC policy can say "no." This is what stops a compromised web server from reading your SSH private keys.

---

## 🎯 What You Will Achieve in Part 17

This module is organized into three progressive levels:

| Level | You Will Learn |
|-------|---------------|
| **⭐ Basic** | Difference between DAC and MAC, SELinux modes (enforcing/permissive/disabled), policies |
| **⭐ Intermediary** | SELinux contexts, booleans, AppArmor profiles, modes, and syntax |
| **⭐ Advanced** | Troubleshooting SELinux denials, creating custom policies, comparing SELinux vs AppArmor internals |

---

## ⭐ Level 1: Basic — Understanding MAC Concepts and SELinux Modes

![SELinux Wordmark](https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/SELinux_wordmark.svg/800px-SELinux_wordmark.svg.png)
*SELinux wordmark, via Wikimedia Commons*

> **Level 1 Goal:** Understand the difference between Discretionary and Mandatory Access Control, and learn the three SELinux modes (enforcing, permissive, disabled).

---

## 🔍 Section 1: DAC vs MAC

### Discretionary Access Control (DAC)

What you already know:

```
File: /etc/shadow
Owner: root
Group: shadow
Permissions: -rw-r-----

The owner (root) can change permissions.
The owner decides who accesses the file.
This is "DISCRETIONARY" — the owner has discretion.
```

### Mandatory Access Control (MAC)

What SELinux/AppArmor add:

```
Even if DAC says "yes" (e.g., file is world-readable),
MAC can say "NO" because:
- The process doesn't have the right security context
- The process isn't allowed to access that type of file
- The process is confined by a profile

This is "MANDATORY" — even root cannot override it.
```

### Why MAC Matters

```
Scenario: A web server (nginx) has a vulnerability.
Attacker exploits it to get a shell as www-data.

DAC only: Attacker reads /etc/shadow (if permissions allow).
           Attacker reads all files www-data can access.
DAC + MAC: SELinux says "nginx is a web server, not allowed
           to read shadow files." Blocked even though
           DAC permissions say yes.
```

### SELinux vs AppArmor

| Feature | SELinux | AppArmor |
|---------|---------|----------|
| Origin | Red Hat / NSA | Canonical / SUSE |
| Labels | Every file, process, port, device | Programs have profiles |
| Policy type | Type Enforcement (TE) | Path-based profiles |
| Granularity | Very fine (everything labeled) | File path patterns |
| Complexity | Higher | Lower |
| Learning curve | Steeper | Gentler |

| Distribution | Default |
|---|---|
| Fedora / RHEL / CentOS | SELinux (enforcing) |
| Debian / Ubuntu | AppArmor (enforcing) |
| openSUSE | AppArmor |
| Arch Linux | None (user chooses) |

---

## 🔍 Section 2: SELinux — Modes and Policies

### Three Modes of SELinux

| Mode | Behavior |
|------|----------|
| **Enforcing** | Policy enforced, denials logged and BLOCKED |
| **Permissive** | Policy not enforced, denials only LOGGED |
| **Disabled** | SELinux turned off completely |

```bash
# Check current mode
getenforce

# Check mode with more detail
sestatus

# Set mode temporarily (until reboot)
sudo setenforce 0    # Permissive
sudo setenforce 1    # Enforcing

# Set mode permanently (in /etc/selinux/config)
sudo cat /etc/selinux/config
```

Output of `sestatus`:

```
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
```

### SELinux Policies

```bash
# Policy types:
# targeted  — Only specific daemons are confined (default)
# minimum   — Minimal policy (subset of targeted)
# mls       — Multi-Level Security (military grade)

# Installed policies
ls /etc/selinux/

# Policy files
ls /etc/selinux/targeted/
```

### Disabling SELinux (Not Recommended)

```bash
# Edit /etc/selinux/config:
# SELINUX=disabled

# Then reboot (SELinux fully disabled)
# Or change to permissive first, then disable later

# Better: Use permissive mode for troubleshooting:
setenforce 0
# Then fix the issue, then setenforce 1
```

---

## ⭐ Level 2: Intermediary — SELinux Contexts, Booleans, and AppArmor

![SELinux Context Labeling](https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/AppArmor_logo.svg/800px-AppArmor_logo.svg.png)
*AppArmor logo, via Wikimedia Commons*

> **Level 2 Goal:** Work with SELinux contexts and booleans for daily administration, and configure AppArmor profiles for common services.

---

## 🔍 Section 3: SELinux Contexts

### The Security Context

Every object (file, process, port, socket) has a security context:

```
user:role:type[:level]

Example for /etc/shadow:
system_u:object_r:shadow_t:s0

system_u  = SELinux user
object_r  = Role (object_r for files, system_r for processes)
shadow_t  = Type (the most important part — defines what can access)
s0        = Sensitivity level (for MLS)
```

### Checking Contexts

```bash
# Check file context
ls -Z /etc/shadow
# system_u:object_r:shadow_t:s0 /etc/shadow

# Check process context
ps -Z | grep sshd
# system_u:system_r:sshd_t:s0-s0:c0.c1023  ... /usr/sbin/sshd

# Check your own context
id -Z

# Check port context
semanage port -l | grep ssh
# ssh_port_t     tcp    22
```

### The Type — The Most Important Part

The **type** determines access:

```
Type: sshd_t
  → Can read: etc_t (config files), shadow_t (if allowed by boolean)
  → Can write: sshd_var_run_t (PID files), var_log_t (logs)
  → Cannot read: httpd_sys_content_t (web files)
  → Cannot connect to: postgresql_port_t (database ports)
```

### File Context Rules

When a file is created, it inherits the context of its parent directory. But specific paths have predefined contexts:

```bash
# List file context rules
sudo semanage fcontext -l | head -20

# Example rules:
# /etc(/.*)?                   all files     system_u:object_r:etc_t:s0
# /var/www(/.*)?               all files     system_u:object_r:httpd_sys_content_t:s0
# /home/[^/]+/www(/.*)?        all files     system_u:object_r:httpd_user_content_t:s0

# Restore default context for a path
sudo restorecon -Rv /var/www/html

# Change context manually
sudo chcon -t httpd_sys_content_t /var/www/html/index.html
```

---

## 🔍 Section 4: SELinux Booleans

Booleans are on/off switches for common policies. They let you adjust SELinux without writing policy.

### Managing Booleans

```bash
# List all booleans
getsebool -a

# List booleans with description
semanage boolean -l | head -30

# Common web server booleans:
# httpd_enable_homedirs       — Allow httpd to read home directories
# httpd_can_network_connect   — Allow httpd to make network connections
# httpd_can_sendmail          — Allow httpd to send mail
# httpd_use_nfs              — Allow httpd to access NFS files

# Get a specific boolean
getsebool httpd_can_network_connect

# Set a boolean (temporary, lost on reboot)
sudo setsebool httpd_can_network_connect on

# Set a boolean (permanent)
sudo setsebool -P httpd_can_network_connect on
```

### Common Booleans for Sysadmins

```bash
# Allow web servers to make outbound connections
sudo setsebool -P httpd_can_network_connect on

# Allow SSH to access home directories (for sftp)
sudo setsebool -P ssh_chroot_rw_homedirs on

# Allow NFS to work with SELinux
sudo setsebool -P nfs_export_all_rw on

# Allow daemons to use DNS
sudo setsebool -P daemons_use_tty on
```

---

## ⭐ Level 3: Advanced — Troubleshooting Denials and MAC Internals

![Mandatory Access Control Diagram](https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/SELinux_wordmark.svg/800px-SELinux_wordmark.svg.png)
*SELinux wordmark, via Wikimedia Commons*

> **Level 3 Goal:** Troubleshoot SELinux denials using audit logs and audit2allow, compare SELinux and AppArmor architectures, and understand the kernel-level MAC implementation.

---

## 🔍 Section 5: Troubleshooting SELinux

### The Audit Log

All SELinux denials are logged to the audit log:

```bash
# Check SELinux denials
sudo grep "AVC" /var/log/audit/audit.log

# Or check with ausearch
sudo ausearch -m avc -ts recent

# Check journald for SELinux messages
journalctl -k | grep -i selinux

# Real-time monitoring of denials
sudo tail -f /var/log/audit/audit.log | grep AVC
```

### Understanding an AVC Denial

```
type=AVC msg=audit(1705312345.123:456):
  avc:  denied  { read } for  pid=12345
  comm="nginx"
  name="shadow"
  dev=sda1 ino=789012
  scontext=system_u:system_r:httpd_t:s0
  tcontext=system_u:object_r:shadow_t:s0
  tclass=file
                  permissive=0

Translation:
  nginx (httpd_t) tried to read a file (shadow_t)
  of class "file"
  This is NOT allowed
  Denial was in enforcing mode (permissive=0)
```

### Using audit2why and audit2allow

```bash
# Explain a denial
sudo grep AVC /var/log/audit/audit.log | audit2why

# Generate policy to allow the denied action
sudo grep AVC /var/log/audit/audit.log | audit2allow -m nginx

# Generate and load a policy module
sudo grep AVC /var/log/audit/audit.log | audit2allow -M nginx_policy
sudo semodule -i nginx_policy.pp
```

### Troubleshooting Steps

```bash
# Step 1: Check if SELinux is blocking
sudo setenforce 0     # Set permissive
# Try the operation again
# If it works, SELinux was the cause

# Step 2: Find the specific denial
sudo ausearch -m avc -ts recent

# Step 3: Fix it
# Option A: Change file context
sudo restorecon -Rv /path/to/file

# Option B: Set a boolean
sudo setsebool -P boolean_name on

# Option C: Create custom policy
sudo grep AVC /var/log/audit/audit.log | audit2allow -M myapp
sudo semodule -i myapp.pp

# Step 4: Re-enforce
sudo setenforce 1
```

### Common SELinux Fixes

```bash
# Problem: "Permission denied" when reading/writing files
# Fix: Restore file context
sudo restorecon -Rv /var/www/html

# Problem: Service can't bind to port
# Fix: Add port to SELinux port list
sudo semanage port -a -t http_port_t -p tcp 8080

# Problem: Service can't connect to network
# Fix: Set boolean
sudo setsebool -P httpd_can_network_connect on

# Problem: Moving files between directories breaks contexts
# Fix: Use cp (creates new file with correct context) instead of mv (keeps context)
# Or: restorecon after mv
sudo mv /home/user/index.html /var/www/html/
sudo restorecon /var/www/html/index.html
```

---

## ⭐ Level 2: Intermediary — AppArmor Profiles and Management

![AppArmor Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/AppArmor_logo.svg/800px-AppArmor_logo.svg.png)
*AppArmor logo, via Wikimedia Commons*

> **Level 2 Goal:** Install, configure, and manage AppArmor profiles for common services, and understand the path-based approach to Mandatory Access Control.

---

## 🔍 Section 6: AppArmor

AppArmor confines programs using profiles that specify what files and capabilities they can access.

### AppArmor Modes

| Mode | Behavior |
|------|----------|
| **Enforce** | Policy enforced, violations BLOCKED logged |
| **Complain** | Policy logged but NOT enforced (learning mode) |
| **Disabled** | Profile unloaded |

```bash
# Check AppArmor status
sudo aa-status

# Check status of specific profiles
sudo aa-status | grep nginx

# List all profiles (enforced)
sudo aa-status --enabled

# List profiles in complain mode
sudo aa-status --complaining

# Set mode
sudo aa-enforce /usr/sbin/nginx    # Set to enforce
sudo aa-complain /usr/sbin/nginx   # Set to complain
sudo aa-disable /usr/sbin/nginx    # Disable profile
```

### AppArmor Profile Structure

```
# /etc/apparmor.d/usr.sbin.nginx
#include <tunables/global>

profile nginx /usr/sbin/nginx {
    #include <abstractions/base>
    #include <abstractions/lxc/container-base>

    # Capabilities
    capability dac_override,
    capability setgid,
    capability setuid,
    capability net_bind_service,

    # Network
    network tcp,

    # Files
    /etc/nginx/** r,
    /var/log/nginx/* w,
    /var/www/html/** r,
    /run/nginx.pid w,

    # Deny everything else
    deny /** w,
}
```

### AppArmor Profile Syntax

```bash
# File access rules:
/path/to/file r,        # Read only
/path/to/file rw,       # Read and write
/path/to/file w,        # Write only
/path/to/file rwkl,     # Read, write, lock, link
/path/to/dir/ r,        # Directory listing
/path/to/dir/** r,      # Recursive, all files
/path/to/dir/* r,       # Non-recursive, immediate children only

# Capabilities (Linux capabilities):
capability dac_override,    # Bypass DAC checks
capability net_bind_service,  # Bind to privileged port (<1024)
capability sys_admin,       # Various admin operations

# Network access:
network tcp,                # TCP networking
network udp,                # UDP networking
network inet tcp,           # IPv4 TCP only

# Execute (running other programs):
/bin/dash ix,              # Inherit profile (transition to target)
/bin/bash px,              # Execute with a different profile
/bin/bash Cx,              # Execute with child profile
```

### Managing AppArmor Profiles

```bash
# Profile locations
ls /etc/apparmor.d/

# Common profiles
# usr.sbin.nginx       — Nginx web server
# usr.sbin.mysqld      — MySQL/MariaDB
# usr.sbin.dhcpd       — DHCP server
# usr.bin.firefox      — Firefox (desktop)
# sbin.dhclient        — DHCP client

# Reload profiles after editing
sudo systemctl reload apparmor

# Or reload a specific profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# Generate a basic profile using aa-genprof
sudo aa-genprof /usr/sbin/nginx
# This runs the program and asks about each denied action
```

### AppArmor Logs

```bash
# AppArmor denials go to:
sudo journalctl -k | grep -i apparmor
sudo grep "apparmor" /var/log/syslog
sudo grep "DENIED" /var/log/syslog

# Watch in real-time
sudo journalctl -kf | grep apparmor

# Example denial:
# audit: type=1400 audit(1705312345.123:456):
#   apparmor="DENIED" operation="open"
#   profile="nginx" name="/etc/shadow"
#   pid=12345 comm="nginx" requested_mask="r"
#   denied_mask="r" fsuid=33 ouid=0
```

---

## ⭐ Level 3: Advanced — Comparing SELinux and AppArmor

![SELinux and AppArmor](https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/SELinux_wordmark.svg/800px-SELinux_wordmark.svg.png)
*SELinux wordmark — the leading MAC implementation on Linux, via Wikimedia Commons*

> **Level 3 Goal:** Compare SELinux and AppArmor side by side in real-world scenarios, and understand which MAC system to use based on your distribution.

---

## 🔍 Section 7: SELinux vs AppArmor — Practical Comparison

### Same Scenario: Nginx Serving Custom Content

**On SELinux (Fedora/RHEL):**

```bash
# You create a custom web directory
mkdir /webroot
echo "<html>Hello</html>" > /webroot/index.html

# Nginx serves it — but gets "permission denied"
sudo restorecon -Rv /webroot    # Fix: Set correct context
# OR
sudo semanage fcontext -a -t httpd_sys_content_t "/webroot(/.*)?"
sudo restorecon -Rv /webroot

# Nginx still can't connect to backend
sudo setsebool -P httpd_can_network_connect on

# Nginx can't listen on custom port
sudo semanage port -a -t http_port_t -p tcp 8080
```

**On AppArmor (Debian/Ubuntu):**

```bash
# Same scenario — nginx can't access /webroot
# Edit /etc/apparmor.d/usr.sbin.nginx:
# Add: /webroot/** r,

# Reload
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# For network access — usually edit profile or use abstractions
```

### Which One Should You Learn?

If you work with:
- **RHEL / Fedora / CentOS / Rocky** → Learn **SELinux** thoroughly
- **Debian / Ubuntu** → Learn **AppArmor** thoroughly
- **Mixed environment** → Learn both at conceptual level

---

## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: MAC Concepts and SELinux Basics

---

### ✅ Practice 1: Check Your MAC System

```bash
mkdir -p ~/linux-course/part17
cd ~/linux-course/part17

# Determine which MAC system is available
if command -v getenforce &>/dev/null; then
    echo "SELinux is available"
    echo "Mode: $(getenforce)"
    sestatus | head -5
elif command -v aa-status &>/dev/null; then
    echo "AppArmor is available"
    sudo aa-status | head -10
else
    echo "No MAC system detected"
    echo "(SELinux or AppArmor may be disabled)"
fi
```

---

### ✅ Practice 2: Check SELinux Mode and Status

```bash
cd ~/linux-course/part17

# Only on systems with SELinux
if command -v getenforce &>/dev/null; then
    echo "=== SELinux Status ==="
    sestatus
    
    echo ""
    echo "=== Current mode ==="
    getenforce
    
    echo ""
    echo "=== SELinux config file ==="
    cat /etc/selinux/config | grep -v "^#" | grep -v "^$"
fi
```

---

### Level 2 Practices: SELinux Contexts, Booleans, and AppArmor

### ✅ Practice 3: Explore File Contexts

```bash
cd ~/linux-course/part17

# Only on systems with SELinux
if command -v getenforce &>/dev/null; then
    echo "=== File contexts for /etc ==="
    ls -Z /etc/passwd /etc/shadow /etc/hosts 2>/dev/null
    
    echo ""
    echo "=== Process contexts ==="
    ps -Z -p 1 2>/dev/null
    ps -Z | head -5
    
    echo ""
    echo "=== Your context ==="
    id -Z
else
    echo "Not on SELinux system"
fi
```

---

### ✅ Practice 4: SELinux Booleans

```bash
cd ~/linux-course/part17

if command -v getenforce &>/dev/null; then
    echo "=== All booleans ==="
    getsebool -a | head -20
    
    echo ""
    echo "=== Common web booleans ==="
    getsebool -a | grep httpd | head -10
    
    echo ""
    echo "=== Boolean descriptions ==="
    sudo semanage boolean -l 2>/dev/null | grep httpd | head -5
else
    echo "Not on SELinux system"
fi
```

---

### ✅ Practice 5: Test SELinux Permissive Mode

```bash
cd ~/linux-course/part17

if command -v getenforce &>/dev/null; then
    CURRENT=$(getenforce)
    echo "Current mode: $CURRENT"
    
    # Check if we can change mode
    if [ "$CURRENT" != "Disabled" ]; then
        echo "Setting to permissive for demonstration..."
        sudo setenforce 0
        getenforce
        
        echo ""
        echo "Setting back to enforcing..."
        sudo setenforce 1
        getenforce
    else
        echo "SELinux is disabled — cannot change mode without reboot"
    fi
fi
```

---

### ✅ Practice 6: AppArmor Status

```bash
cd ~/linux-course/part17

if command -v aa-status &>/dev/null; then
    echo "=== AppArmor Status ==="
    sudo aa-status
    
    echo ""
    echo "=== Profiles directory ==="
    ls /etc/apparmor.d/ 2>/dev/null | head -20
    
    echo ""
    echo "=== Parsing a profile ==="
    if [ -f /etc/apparmor.d/usr.sbin.nginx ]; then
        head -20 /etc/apparmor.d/usr.sbin.nginx
    elif [ -f /etc/apparmor.d/usr.sbin.rsyslogd ]; then
        head -20 /etc/apparmor.d/usr.sbin.rsyslogd
    else
        ls /etc/apparmor.d/ 2>/dev/null | head -10
    fi
else
    echo "AppArmor not installed"
fi
```

---

### Level 3 Practices: Troubleshooting, Profiles, and Auditing

### ✅ Practice 7: Check SELinux Denials (if any)

```bash
cd ~/linux-course/part17

if [ -d /var/log/audit ]; then
    echo "=== Recent SELinux denials ==="
    sudo ausearch -m avc -ts recent 2>/dev/null | head -20 || \
      echo "No recent denials found"
    
    echo ""
    echo "=== Checking audit.log ==="
    sudo tail -5 /var/log/audit/audit.log 2>/dev/null | grep AVC || \
      echo "No AVC denials found"
else
    echo "No audit log directory (SELinux not active or no auditd)"
fi
```

---

### ✅ Practice 8: restorecon — Fix File Contexts

```bash
cd ~/linux-course/part17

# Create a test directory
mkdir -p /tmp/selinux-test
echo "test file" > /tmp/selinux-test/test.txt

# Check its context
ls -Z /tmp/selinux-test/test.txt

# If SELinux is active, restore the default context
if command -v restorecon &>/dev/null; then
    echo ""
    echo "Restoring context..."
    sudo restorecon -Rv /tmp/selinux-test
    ls -Z /tmp/selinux-test/test.txt
fi

# Clean up
rm -rf /tmp/selinux-test
```

---

### ✅ Practice 9: AppArmor Complain Mode

```bash
cd ~/linux-course/part17

if command -v aa-complain &>/dev/null; then
    echo "=== Checking profiles in complain mode ==="
    sudo aa-status --complaining 2>/dev/null || echo "None in complain mode"
    
    echo ""
    echo "=== Putting a profile in complain mode (example) ==="
    # Check if rsyslogd has a profile
    if [ -f /etc/apparmor.d/usr.sbin.rsyslogd ]; then
        echo "Would set: sudo aa-complain /usr/sbin/rsyslogd"
        echo "Would restore: sudo aa-enforce /usr/sbin/rsyslogd"
    fi
fi
```

---

### ✅ Practice 10: Check MAC Context After File Operations

```bash
cd ~/linux-course/part17

# Create test files
echo "original" > /tmp/mac-test-original
ls -Z /tmp/mac-test-original 2>/dev/null || echo "No SELinux context"

# Copy keeps context of destination directory
cp /tmp/mac-test-original /tmp/mac-test-copy
ls -Z /tmp/mac-test-copy 2>/dev/null || echo "No SELinux context"

# Move keeps original context
mv /tmp/mac-test-original /tmp/mac-test-moved
ls -Z /tmp/mac-test-moved 2>/dev/null || echo "No SELinux context"

# Clean up
rm -f /tmp/mac-test-*
```

---

### ✅ Practice 11: Create a Minimal AppArmor Profile

```bash
cd ~/linux-course/part17

# This is a learning exercise — not meant to be loaded
cat << 'EOF' > minimal_apparmor_profile.txt
# Minimal AppArmor profile example
# File would go to: /etc/apparmor.d/usr.local.bin.testapp

#include <tunables/global>

profile testapp /usr/local/bin/testapp {
    #include <abstractions/base>
    #include <abstractions/bash>
    
    # Allow reading config
    /etc/testapp/config r,
    
    # Allow writing logs
    /var/log/testapp/* w,
    
    # Allow network access
    network inet tcp,
    
    # Everything else denied
    deny /** w,
    deny /etc/shadow r,
}
EOF

echo "Profile template created at minimal_apparmor_profile.txt"
```

---

### ✅ Practice 12: Check SELinux Port Contexts

```bash
cd ~/linux-course/part17

if command -v semanage &>/dev/null; then
    echo "=== Port contexts ==="
    sudo semanage port -l | grep -E "ssh|http|mysql" | head -10
    
    echo ""
    echo "=== All port types ==="
    sudo semanage port -l | head -30
else
    echo "semanage not available (not on SELinux system)"
fi
```

---

### ✅ Practice 13: SELinux Troubleshooting Simulation

```bash
cd ~/linux-course/part17

# Create a simulated SELinux problem and fix
cat << 'EOF'
Simulated SELinux troubleshooting workflow:

PROBLEM: Nginx shows "Permission denied" when accessing /webroot

STEP 1: Check SELinux status
  $ getenforce
  Enforcing

STEP 2: Check file context
  $ ls -Z /webroot/
  unconfined_u:object_r:user_home_t:s0 index.html
  # Wrong context! Should be httpd_sys_content_t

STEP 3: Fix file context
  $ sudo semanage fcontext -a -t httpd_sys_content_t "/webroot(/.*)?"
  $ sudo restorecon -Rv /webroot
  $ ls -Z /webroot/
  system_u:object_r:httpd_sys_content_t:s0 index.html

STEP 4: Verify fix
  Problem solved!

ALTERNATIVE: Use restorecon directly
  $ sudo restorecon -Rv /webroot
  # Works if /webroot is already defined in the policy
EOF
```

---

### ✅ Practice 14: Check if a Specific Service is Confined

```bash
cd ~/linux-course/part17

# Check SSH daemon confinement
if command -v getenforce &>/dev/null; then
    echo "=== SSH context (SELinux) ==="
    ps -Z -C sshd 2>/dev/null || ps -Z $(pgrep -o sshd) 2>/dev/null
fi

if command -v aa-status &>/dev/null; then
    echo ""
    echo "=== SSH profile (AppArmor) ==="
    sudo aa-status | grep -i ssh
fi

echo ""
echo "=== Checking other confined processes ==="
if command -v getenforce &>/dev/null; then
    ps -Z | grep -E "nginx|httpd|mysqld|postgres|named" 2>/dev/null | head -5 || \
      echo "No confined daemons running"
fi
```

---

### ✅ Practice 15: Real SysAdmin Scenario — MAC Security Audit

```bash
cd ~/linux-course/part17

cat > mac_security_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="mac_security_report.txt"

echo "============================================" > "$REPORT"
echo "  MAC SECURITY AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: MAC System
echo "1. MANDATORY ACCESS CONTROL SYSTEM" >> "$REPORT"
if command -v getenforce &>/dev/null; then
    echo "  System: SELinux" >> "$REPORT"
    echo "  Mode: $(getenforce)" >> "$REPORT"
    sestatus >> "$REPORT" 2>/dev/null
elif command -v aa-status &>/dev/null; then
    echo "  System: AppArmor" >> "$REPORT"
    sudo aa-status >> "$REPORT" 2>/dev/null
else
    echo "  None detected" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 2: SELinux Booleans (if applicable)
echo "2. SELINUX BOOLEANS (non-default)" >> "$REPORT"
if command -v getsebool &>/dev/null; then
    sudo semanage boolean -l 2>/dev/null | grep -E "\(on  \-1\)|\(off  -1\)" | \
      head -20 >> "$REPORT" || echo "  No non-default booleans" >> "$REPORT"
else
    echo "  N/A" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 3: AppArmor Profiles (if applicable)
echo "3. APPARMOR PROFILES" >> "$REPORT"
if [ -d /etc/apparmor.d ]; then
    ls /etc/apparmor.d/ >> "$REPORT"
else
    echo "  N/A" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 4: Recent MAC denials
echo "4. RECENT MAC DENIALS (last 24h)" >> "$REPORT"
if [ -f /var/log/audit/audit.log ]; then
    sudo ausearch -m avc -ts today 2>/dev/null | grep -c "denied" | \
      awk '{print "  " $1 " SELinux denials today"}' >> "$REPORT" || \
      echo "  0 SELinux denials" >> "$REPORT"
elif [ -f /var/log/syslog ]; then
    grep "apparmor" /var/log/syslog 2>/dev/null | grep "DENIED" | wc -l | \
      awk '{print "  " $1 " AppArmor denials today"}' >> "$REPORT" || \
      echo "  0 AppArmor denials" >> "$REPORT"
else
    echo "  No MAC denial logs found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 5: Confined services
echo "5. CONFINED SERVICES" >> "$REPORT"
if command -v ps &>/dev/null; then
    ps -Z 2>/dev/null | awk 'NR>1 {print $5, $6}' | sort | uniq -c | sort -rn | head -10 >> "$REPORT" || \
      echo "  Could not retrieve" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x mac_security_audit.sh
./mac_security_audit.sh
```

---

## 🧠 Deep Understanding — How MAC Really Works

### SELinux Type Enforcement

The core of SELinux is a set of rules:

```
allow SOURCE_TYPE TARGET_TYPE:CLASS { PERMISSIONS };
```

Example:
```
allow httpd_t shadow_t:file { read };
```

This means: "A process with type httpd_t is ALLOWED to read a file with type shadow_t."

By default, **everything is denied**. Policy files explicitly allow specific operations.

### The SELinux Policy Database

```bash
# The compiled policy is stored in:
ls /etc/selinux/targeted/policy/

# The source policy (if installed) is in:
ls /etc/selinux/targeted/src/

# Policy modules (custom additions)
ls /etc/selinux/targeted/modules/active/modules/

# Current loaded modules
sudo semodule -l | head -20
```

### AppArmor Path-Based Enforcement

AppArmor doesn't label files. It uses file system paths:

```
Rule: /etc/shadow r,
Allows: Reading /etc/shadow

Rule: /etc/shadow w,
Allows: Writing /etc/shadow

No rule for /etc/shadow = DENIED
```

### SELinux Users and Roles

SELinux has its own user system, separate from Linux users:

```bash
# Map Linux users to SELinux users
semanage login -l

# Default mapping:
# Linux user → SELinux user
# root       → unconfined_u (root is NOT confined by default)
# __default__→ unconfined_u (regular users are not confined)

# To confine specific users:
semanage login -a -s user_u username
```

---

## 📋 Summary — Command Reference for Part 17

### Level 1 — Basic MAC Commands

| Command | Action |
|---------|--------|
| `getenforce` | Show current SELinux mode |
| `setenforce 0\|1` | Set permissive (0) or enforcing (1) |
| `sestatus` | Full SELinux status and policy info |
| `ls -Z FILE` | Show file context |
| `ps -Z` | Show process contexts |
| `id -Z` | Show current user/role/type context |
| `cat /etc/selinux/config` | View permanent SELinux configuration |

### Level 2 — Intermediary Configuration and Daily Use

| Command | Action |
|---------|--------|
| `restorecon -Rv DIR` | Restore default file contexts recursively |
| `chcon -t TYPE FILE` | Change file context type |
| `getsebool -a` | List all SELinux booleans |
| `setsebool -P BOOL on` | Set boolean persistently |
| `semanage fcontext -l` | List file context rules |
| `semanage boolean -l` | List booleans with descriptions |
| `semanage port -l` | List port contexts |
| `aa-status` | Show all AppArmor profiles |
| `aa-enforce PROG` | Set profile to enforce mode |
| `aa-complain PROG` | Set profile to complain mode |
| `aa-disable PROG` | Disable AppArmor profile |
| `systemctl reload apparmor` | Reload all AppArmor profiles |
| `cat /etc/apparmor.d/PROFILE` | View AppArmor profile contents |

### Level 3 — Advanced Troubleshooting and Policy Management

| Command | Action |
|---------|--------|
| `ausearch -m avc` | Search audit log for AVC denials |
| `audit2why` | Explain why a denial occurred |
| `audit2allow` | Generate a policy module from denial |
| `semodule -i MOD.pp` | Install a custom policy module |
| `semodule -l` | List all loaded policy modules |
| `semodule -r MOD` | Remove a policy module |
| `aa-genprof PROG` | Interactively generate AppArmor profile |
| `apparmor_parser -r PROFILE` | Reload a specific AppArmor profile |
| `semanage permissive -a TYPE` | Put a domain in permissive mode |

---

## 🚀 What's Coming in Part 18

**Part 18: Environment Variables and Shell Configuration**

You will learn:
- What environment variables are and how they work
- Important environment variables (PATH, HOME, USER, etc.)
- Shell config files (.bashrc, .bash_profile, .profile, /etc/profile)
- Creating aliases and shell functions
- Setting variables system-wide vs per-user
- 15 hands-on practices

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between DAC and MAC?
2. What are the three modes of SELinux?
3. What does `getenforce` show and what are the possible outputs?
4. What is an SELinux "context" and what are its four components?
5. What command restores SELinux file contexts to their defaults?
6. What is an SELinux boolean and how do you make the change permanent?
7. How do you check the SELinux context of a running process?
8. What are the two modes of AppArmor?
9. Where are AppArmor profiles stored?
10. How does AppArmor profile syntax differ from SELinux policy?
11. What command checks AppArmor status?
12. How do you find SELinux denials in the audit log?
13. What does `audit2allow` do?
14. Why does moving a file sometimes break SELinux but copying does not?
15. What is the `restorecon` command used for?

**Score:** 12/15 correct = ready for Part 18.

---

*Linux SysAdmin Course | Part 17 of ∞ | Reverse Engineering Approach*
*Previous → Part 16: Firewalls — iptables, firewalld, nftables*
*Next → Part 18: Environment Variables and Shell Configuration*

[← Previous](part16.md) | [Next →](part18.md)
