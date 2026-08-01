## 📏 Rules of Thumb

### The DNS Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use getent for real resolution** | Checks hosts file | Accuracy |
| **Use dig for DNS queries** | Bypasses hosts file | Direct |
| **Check /etc/hosts first** | Often the problem | Quick fix |
| **Check nsswitch.conf** | Resolution order | Understanding |

### The "DNS Not Working" Checklist

```bash
# 1. Check /etc/resolv.conf:
cat /etc/resolv.conf

# 2. Check /etc/hosts:
cat /etc/hosts

# 3. Test with dig:
dig example.com

# 4. Test with getent:
getent hosts example.com

# 5. Check DNS server:
ping $(head -1 /etc/resolv.conf | awk '{print $2}')
```

---

**Why these rules matter:** DNS issues are common and confusing. Following these rules helps you diagnose them systematically.

[← Previous](21-self-test-can-you-answer-these.md) | [↑ Index](index.md)
