## 📏 Rules of Thumb

### The Network Configuration Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use ip, not ifconfig** | Modern, always available | Future-proof |
| **Check carrier first** | Physical layer | Debugging |
| **Use nmcli for management** | Consistent interface | Efficiency |
| **Document IP assignments** | Know what's where | Maintainability |

### The "No Network" Checklist

```bash
# 1. Check link status:
ip link show

# 2. Check IP address:
ip addr show

# 3. Check routing:
ip route show

# 4. Check DNS:
cat /etc/resolv.conf

# 5. Check firewall:
iptables -L -n
```

---

**Why these rules matter:** Following these rules helps you configure and troubleshoot networks efficiently.

[← Previous](19-self-test-can-you-answer-these.md) | [↑ Index](index.md)
