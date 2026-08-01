## 📏 Rules of Thumb

### The Golden Rules of Linux Navigation

| Rule | Description | Example |
|------|-------------|---------|
| **When in doubt, pwd** | Always know where you are | `pwd` |
| **Absolute paths for scripts** | Scripts should use absolute paths | `#!/bin/bash` |
| **Relative paths for exploration** | Use relative paths when browsing | `cd ../docs` |
| **Tab completion is your friend** | Press Tab twice for suggestions | `cd /et<Tab><Tab>` |
| **Check before you change** | Always `ls` before modifying | `ls -la /etc/` |

### The "Everything is a File" Rules

| Situation | What It Means |
|-----------|---------------|
| Can't access a file | Check permissions: `ls -la` |
| Can't find a command | Check PATH: `which command` |
| Can't write to disk | Check mount options: `mount` |
| Can't see network | Check interfaces: `ip link` |

### Quick Reference

```bash
# System information:
uname -a           # Kernel info
hostnamectl        # Hostname info
cat /etc/os-release  # Distro info

# File exploration:
ls -la             # All files with details
ls -lhtr           # Recent files last
tree -L 2          # Directory tree (2 levels deep)
find . -name "*.conf"  # Find config files

# Get help:
man command        # Full manual
command --help     # Quick help
info command       # Detailed info
```

### The Sysadmin Mindset

1. **Assume nothing, verify everything** — Don't guess; check
2. **Read error messages completely** — The answer is usually in the next 20 lines
3. **Automate repetitive work** — If you do it twice, script it
4. **Document everything** — Your future self will thank you
5. **Learn concepts, not commands** — Commands change; concepts don't

---

**Why this matters:** These rules form the foundation of good Linux habits. Following them from day one will save you hours of debugging and prevent common mistakes.

[← Previous](16-self-test-can-you-answer-these.md) | [↑ Index](index.md)
