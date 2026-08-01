## 📏 Rules of Thumb

### The Editor Selection Rules

| Situation | Use | Why |
|-----------|-----|-----|
| Quick config edit | `nano` | Simple, intuitive |
| Script editing | `vim` | Powerful, efficient |
| Emergency (vim not found) | `vi` | Always available |
| Large files | `vim` or `less` | Memory efficient |
| Remote SSH | `vim` | No GUI needed |

### The Vim Learning Path

```
Phase 1: Survive
  Learn: i, ESC, :wq, :q!
  Goal: Can edit and save files

Phase 2: Navigate
  Learn: h,j,k,l, w,b, 0,$
  Goal: Can move without arrow keys

Phase 3: Edit
  Learn: dd, yy, p, u, /, %
  Goal: Can edit efficiently

Phase 4: Master
  Learn: macros, registers, splits
  Goal: Power user
```

### The nano Rules

```bash
# nano is always available:
nano /etc/hosts

# Key shortcuts (shown at bottom):
Ctrl+O    # Save (Write Out)
Ctrl+X    # Exit
Ctrl+K    # Cut line
Ctrl+U    # Paste (Uncut)
Ctrl+W    # Search
Ctrl+\    # Search and Replace
```

### The Configuration File Rules

| Rule | Description |
|------|-------------|
| **Always backup before editing** | `cp file file.bak` |
| **Use visudo for sudoers** | Syntax checking prevents lockout |
| **Check syntax after editing** | `apachectl configtest`, `named-checkconf` |
| **Restart service after config change** | `systemctl restart service` |
| **Use drop-in directories** | `/etc/sudoers.d/` instead of main file |

### The "Can't Save" Checklist

```bash
# 1. Check if file is read-only:
ls -la /path/to/file

# 2. Check if you have write permission:
groups

# 3. Check if disk is full:
df -h

# 4. Check if filesystem is read-only:
mount | grep /path

# 5. Try with sudo:
sudo vim /path/to/file
```

---

**Why these rules matter:** Choosing the right editor for the situation and knowing how to use it saves time and prevents mistakes. Start with nano, graduate to vim.

[← Previous](22-self-test-can-you-answer-these.md) | [↑ Index](index.md)
