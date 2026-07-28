## 🔍 Section 1: Security Philosophy

### The CIA Triad

Every security decision you make as a sysadmin traces back to three core principles:

| Principle | Meaning | Example |
|-----------|---------|---------|
| **Confidentiality** | Data is accessible only to authorized parties | File permissions, encryption, access controls |
| **Integrity** | Data is not tampered with by unauthorized parties | File integrity monitoring, checksums, audit logs |
| **Availability** | Systems and data are accessible when needed | Redundancy, backups, DDoS protection, failover |

### Defense in Depth

Never rely on a single security control. Layer them so that if one fails, another catches the threat:

```
┌─────────────────────────────────────────────────────────┐
│                    DEFENSE IN DEPTH                       │
├─────────────────────────────────────────────────────────┤
│  🌐 Network Layer   — Firewall, TCP wrappers, VPN        │
│  🖥️ Host Layer      — SELinux/AppArmor, auditd, AIDE    │
│  👤 User Layer      — PAM, password policies, SSH keys   │
│  📁 Application Layer — Web app firewall, input validation│
│  💾 Data Layer      — Encryption at rest, backups        │
└─────────────────────────────────────────────────────────┘
```

### Least Privilege

Every user, process, and service should have **only the permissions it needs** to function — nothing more.

```bash
# Bad: root for everything
sudo chmod 777 /etc/shadow      # NEVER DO THIS

# Good: specific permissions
sudo usermod -aG www-data deploy
sudo chown root:www-data /var/www
sudo chmod 750 /var/www
```

### Attack Surface Reduction

Every running service, open port, installed package, and enabled kernel feature is a potential attack vector. Remove what you don't need:

```bash
# List all listening ports
ss -tlnp

# Remove unused packages
sudo apt list --installed | grep -E 'telnet|rsh|talk'
sudo apt purge telnetd rsh-server talkd

# Disable unused services
sudo systemctl disable --now cupsd avahi-daemon rpcbind
```

### Security by Design

Build security into the architecture from the start, not as an afterthought:

- Encrypt data in transit (TLS/SSL, SSH)
- Encrypt data at rest (LUKS, eCryptfs)
- Isolate services with containers, VMs, or jails
- Use separate VLANs for different trust levels
- Automate security checks into CI/CD pipelines





[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-cis-benchmarks.md)
