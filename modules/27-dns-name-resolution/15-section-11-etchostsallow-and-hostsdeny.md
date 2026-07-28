## 🔍 Section 11: /etc/hosts.allow and hosts.deny — TCP Wrappers

TCP wrappers (tcpd) is a legacy host-based access control system. It wraps network services to allow or deny connections based on client hostname or IP.

### How TCP Wrappers Work

```
Client connects → inetd/xinetd or tcpd wrapper → checks /etc/hosts.allow → checks /etc/hosts.deny → grants or denies
```

### Format

```
# /etc/hosts.allow
service_list : client_list [: shell_command]

# /etc/hosts.deny
service_list : client_list [: shell_command]
```

### Rules

1. If a rule matches in `hosts.allow` → connection ALLOWED
2. If a rule matches in `hosts.deny` → connection DENIED
3. If neither matches → connection ALLOWED (default)

```bash
# /etc/hosts.allow — allow specific services/hosts
sshd: 192.168.1.0/255.255.255.0
sshd: 10.0.0.0/255.0.0.0
vsftpd: .example.com        # Allow all .example.com hosts

# /etc/hosts.deny — deny everything else
ALL: ALL                     # Default deny for everything
```

### Paranoid Configuration

```bash
# /etc/hosts.deny
ALL: ALL

# /etc/hosts.allow
sshd: 192.168.0.0/16 10.0.0.0/8
```

This denies everything EXCEPT SSH from private networks.

### Checking If a Service Uses TCP Wrappers

```bash
# Check if the binary is linked to libwrap
ldd /usr/sbin/sshd | grep libwrap     # If output: yes, uses wrappers
ldd /usr/sbin/vsftpd | grep libwrap   # Most modern binaries don't

# On modern systems, most services use their own ACLs or firewalls
# TCP wrappers are largely replaced by nftables/iptables
```

### hosts_options — Extended Syntax

```bash
# /etc/hosts.allow (with twist/bark)
sshd: 192.168.1.0/24 : deny           # Explicit deny within allow file
sshd: .evil.com : twist /bin/echo "Connection from %c rejected"
```

### Limitations

- Only works with services compiled against `libwrap`
- Hostname-based rules require reverse DNS (can be spoofed)
- Modern systems use firewalls instead (nftables, ufw, firewalld)
- Most distributions no longer compile services with libwrap

### Checking Current Status

```bash
# Do the files exist?
ls -la /etc/hosts.allow /etc/hosts.deny

# On modern systems, they often look like:
cat /etc/hosts.allow
# ALL: ALL  (or empty with comments)
cat /etc/hosts.deny
# ALL: ALL  (or empty)
```





[← Previous](14-level-3-advanced-resolution-internals.md) | [↑ Index](index.md) | [Next →](16-section-12-custom-hostname-resolution.md)
