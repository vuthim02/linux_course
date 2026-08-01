## 📏 Rules of Thumb

### The SSH Security Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use key-based auth** | Never passwords for servers | Security |
| **Use Ed25519** | More secure than RSA | Future-proof |
| **Disable root login** | `PermitRootLogin no` | Security |
| **Disable password auth** | `PasswordAuthentication no` | Prevent brute force |
| **Use SSH config** | Simplify connections | Efficiency |

### The SSH Permission Rules

| Path | Permission | Why |
|------|------------|-----|
| `~/.ssh` | 700 | Only owner can access |
| Private key | 600 | Only owner can read |
| Public key | 644 | Can be world-readable |
| `authorized_keys` | 600 | Only owner can modify |
| `known_hosts` | 644 | Can be world-readable |

### The "Can't Connect" Checklist

```bash
# 1. Check if SSH is running:
systemctl status sshd

# 2. Check firewall:
sudo iptables -L -n | grep 22

# 3. Check port:
ss -tlnp | grep 22

# 4. Check DNS:
ssh -v user@hostname

# 5. Check key permissions:
ls -la ~/.ssh/
```

### The "Permission Denied" Checklist

```bash
# 1. Check key permissions:
ls -la ~/.ssh/id_ed25519

# 2. Fix permissions:
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh

# 3. Check server logs:
journalctl -u sshd

# 4. Check authorized_keys:
ssh user@server "cat ~/.ssh/authorized_keys"

# 5. Use verbose mode:
ssh -vvv user@server
```

---

**Why these rules matter:** SSH is the gateway to your servers. Following these rules keeps your systems secure and accessible.

[← Previous](24-level-4-mastery-scenarios.md) | [↑ Index](index.md)
