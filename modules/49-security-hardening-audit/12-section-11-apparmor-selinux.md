## 🔍 Section 11: AppArmor / SELinux

### AppArmor Overview

**AppArmor** (Application Armor) is a Mandatory Access Control (MAC) system implemented as a Linux Security Module (LSM). It confines programs to a set of listed files, capabilities, and network access defined in **profiles**.

```
Process (e.g., nginx) → AppArmor check → Allowed/Denied
                              │
                    (profile in /etc/apparmor.d/)
```

### AppArmor Status and Management

```bash
# Check if AppArmor is enabled and running
sudo aa-status
# Output:
# apparmor module is loaded.
# 34 profiles are loaded.
# 30 profiles are in enforce mode.
#    /usr/sbin/nginx
#    /usr/sbin/mysqld
# 4 profiles are in complain mode.

# List profiles by mode
sudo aa-status | grep -E 'enforce|complain'

# Get detailed status of a specific profile
sudo aa-status --profile /usr/sbin/nginx
```

### AppArmor Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| **Enforce** | Denies actions not in profile, logs to audit.log | Production |
| **Complain** | Logs violations but allows them | Testing/development |
| **Disabled** | Profile not loaded | Recovery |

```bash
# Set profile to enforce
sudo aa-enforce /usr/sbin/nginx

# Set profile to complain
sudo aa-complain /usr/sbin/mysqld

# Disable a profile
sudo aa-disable /usr/sbin/test-app

# Reload all profiles after changes
sudo systemctl reload apparmor

# Or reload a specific profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```

### Creating an AppArmor Profile

```bash
# Generate a profile in complain mode first
sudo aa-genprof /usr/bin/custom-app

# This will:
# 1. Ask you to run the application in another terminal
# 2. Log all denied actions
# 3. Prompt you to allow/deny each action

# Alternative: Use aa-easyprof for simple profiles
sudo aa-easyprof /usr/bin/custom-app
```

### Sample AppArmor Profile

```bash
# /etc/apparmor.d/usr.sbin.nginx
sudo tee /etc/apparmor.d/usr.sbin.nginx > /dev/null << 'EOF'
#include <tunables/global>

/usr/sbin/nginx {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Capabilities
  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability dac_override,
  capability chown,
  capability kill,

  # Network access
  network inet tcp,
  network inet6 tcp,

  # Files and directories
  /usr/sbin/nginx mr,
  /etc/nginx/** r,
  /var/log/nginx/* w,
  /var/www/** r,
  /run/nginx.pid w,
  /run/nginx.pid rw,
  /var/lib/nginx/** rwk,
  /tmp/nginx/* rw,

  # Deny write to system configs
  deny /etc/passwd w,
  deny /etc/shadow w,
  deny /etc/nginx/nginx.conf w,
}
EOF
```

### SELinux Overview

**SELinux** (Security-Enhanced Linux) is a more granular MAC system developed by the NSA. Every process and file has a **security context** (label), and rules define which contexts can access which resources.

### SELinux Modes

```bash
# Check current mode
getenforce
# Enforcing | Permissive | Disabled

# Set mode (temporary, until reboot)
sudo setenforce 1     # Enforcing
sudo setenforce 0     # Permissive

# Permanent change — edit /etc/selinux/config:
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

### SELinux Context — Security String

Every file and process has a context with four fields:

```
user:role:type:level (optional MLS/MCS range)

Example:
unconfined_u:object_r:httpd_sys_content_t:s0

Breakdown:
- unconfined_u    — SELinux user
- object_r        — Role
- httpd_sys_content_t — Type (the most important part)
- s0              — Sensitivity level (MLS/MCS)
```

### Common SELinux Commands

```bash
# Check context of a file
ls -Z /var/www/html/index.html
# unconfined_u:object_r:httpd_sys_content_t:s0 /var/www/html/index.html

# Check context of a process
ps -Z $(pgrep httpd) | head -5
# system_u:system_r:httpd_t:s0  1234 ?  00:00:00 httpd

# Change file context
sudo chcon -t httpd_sys_content_t /var/www/html/index.html

# Restore default context (from policy)
sudo restorecon -v /var/www/html/index.html

# List all file contexts for a directory
sudo semanage fcontext -l | grep /var/www

# Set default context for a path
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/www(/.*)?"
sudo restorecon -Rv /srv/www
```

### SELinux Booleans

SELinux booleans are tunable policy switches that allow/deny specific behaviors without writing new policies:

```bash
# List all booleans
sudo getsebool -a

# Check a specific boolean
sudo getsebool httpd_can_network_connect

# Set a boolean (temporary)
sudo setsebool httpd_can_network_connect on

# Set persistently
sudo setsebool -P httpd_can_network_connect on

# Common web server booleans:
# httpd_can_network_connect — Allow httpd to connect to network (proxies)
# httpd_can_sendmail       — Allow httpd to send email
# httpd_enable_homedirs    — Allow httpd to access user home dirs
# httpd_use_nfs            — Allow httpd to access NFS mounts
# ssh_sysadm_login         — Allow SSH login as sysadm_r
```

### SELinux Policy Modules

```bash
# List installed modules
sudo semodule -l

# Install a new module
sudo semodule -i mymodule.pp

# Remove a module
sudo semodule -r mymodule

# Create a custom module from audit log
sudo grep httpd /var/log/audit/audit.log | sudo audit2allow -M myhttpdmodule
sudo semodule -i myhttpdmodule.pp
```

### Troubleshooting SELinux Denials

```bash
# Check for denials in real time
sudo tail -f /var/log/audit/audit.log | grep AVC

# Use sealert for human-readable messages
sudo sealert -a /var/log/audit/audit.log

# Show all denials in summary
sudo ausearch -m AVC -ts today | audit2why

# Generate policy to allow denials
sudo ausearch -m AVC -ts today | audit2allow -M mymodule
```

### Choosing: AppArmor vs SELinux

| Factor | AppArmor | SELinux |
|--------|----------|---------|
| **Complexity** | Simple, path-based | Complex, label-based |
| **Granularity** | File paths + capabilities | Types, roles, users, levels |
| **Ease of use** | Beginner-friendly | Steep learning curve |
| **Default on** | Ubuntu, Debian, OpenSUSE | RHEL, CentOS, Fedora |
| **Policy language** | Profile syntax (simple) | TE (Type Enforcement) |
| **MLS/MCS** | Limited | Full support |

---



---

[← Previous](11-section-10-kernel-hardening.md) | [↑ Index](index.md) | [Next →](13-section-12-ssh-hardening.md)
