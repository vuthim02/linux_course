## 📏 Rules of Thumb

### The Repository Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Verify GPG keys** | Trust but verify | Security |
| **Use official repos** | Highest trust | Stability |
| **Test third-party** | Try in staging first | Compatibility |
| **Document sources** | Know what you added | Maintainability |
| **Disable unused repos** | Reduce attack surface | Security |

### The "Package Not Found" Checklist

```bash
# 1. Update package lists:
sudo apt update

# 2. Search for package:
apt search package

# 3. Check if in different repo:
apt-cache showpkg package

# 4. Check if name changed:
apt search | grep -i keyword

# 5. Check if deprecated:
apt-cache show package
```

---

**Why these rules matter:** Following these rules keeps your system secure while allowing you to install needed software.

[← Previous](17-self-test-can-you-answer-these.md) | [↑ Index](index.md)
