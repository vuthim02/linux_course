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





[← Previous](12-level-3-advanced-comparing-selinux.md) | [↑ Index](index.md) | [Next →](14-practice-section-15-hands-on-exercises.md)
