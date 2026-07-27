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



---

[← Previous](05-level-2-intermediary-selinux-contexts.md) | [↑ Index](index.md) | [Next →](07-section-4-selinux-booleans.md)
