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





[← Previous](10-level-2-intermediary-apparmor-profiles.md) | [↑ Index](index.md) | [Next →](12-level-3-advanced-comparing-selinux.md)
