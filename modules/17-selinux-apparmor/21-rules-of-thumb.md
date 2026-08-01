## 📏 Rules of Thumb

### The SELinux Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Don't disable it** | Configure properly | Security |
| **Use setenforce 0 temporarily** | For testing | Debugging |
| **Check audit logs first** | Find the real issue | Understanding |
| **Use semanage for persistence** | Not chcon | Durability |
| **Use restorecon** | Fix contexts | Correctness |

### The "SELinux Denied" Checklist

```bash
# 1. Check audit logs:
ausearch -m avc -ts recent

# 2. Check file context:
ls -Z /path/to/file

# 3. Check port context:
semanage port -l | grep http

# 4. Set boolean:
setsebool -P httpd_can_network_connect on

# 5. Restore context:
restorecon -Rv /path/to/directory
```

### The SELinux Troubleshooting Pattern

```
1. See "Permission denied"
2. Check: is it DAC (standard permissions)?
3. Check: is it SELinux?
   a. ls -Z to see context
   b. ausearch to see denial
4. Fix: setsebool, chcon, or semanage
5. Test: restorecon and verify
```

---

**Why these rules matter:** SELinux is complex but valuable. Following these rules helps you use it properly instead of disabling it.

[← Previous](18-self-test-can-you-answer-these.md) | [↑ Index](index.md)
