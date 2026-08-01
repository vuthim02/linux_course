## 📏 Rules of Thumb

### The Firewall Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Default deny** | Block everything first | Security |
| **Allow specific ports** | Only what's needed | Attack surface |
| **Log drops** | Know what's blocked | Debugging |
| **Test rules** | Don't lock yourself out | Accessibility |
| **Document changes** | Know what you did | Maintainability |

### The Port Allowance Rules

| Service | Port | Protocol | When to Allow |
|---------|------|----------|---------------|
| SSH | 22 | TCP | Remote management |
| HTTP | 80 | TCP | Web server |
| HTTPS | 443 | TCP | Secure web |
| DNS | 53 | TCP/UDP | Name resolution |
| SMTP | 25 | TCP | Mail sending |

### The "Locked Out" Prevention

```bash
# 1. Always allow SSH first:
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 2. Use at (scheduled removal):
echo "iptables -F" | at now + 5 minutes

# 3. Test with temporary rule:
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# 4. Keep a backup terminal open
```

### The "Can't Connect" Checklist

```bash
# 1. Check firewall:
iptables -L -n -v

# 2. Check if port is listening:
ss -tlnp | grep :80

# 3. Check from client:
telnet server 80

# 4. Check logs:
journalctl -u firewalld | grep DROP

# 5. Check iptables logs:
dmesg | grep iptables
```

---

**Why these rules matter:** Following these rules keeps your systems secure while maintaining accessibility. The "locked out" prevention alone saves hours of emergency work.

[← Previous](23-level-4-mastery-scenarios.md) | [↑ Index](index.md)
