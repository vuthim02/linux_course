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



---

[← Previous](08-level-3-advanced-troubleshooting-denials.md) | [↑ Index](index.md) | [Next →](10-level-2-intermediary-apparmor-profiles.md)
