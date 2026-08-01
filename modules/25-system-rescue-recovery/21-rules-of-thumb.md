## 📏 Rules of Thumb

### The Rescue Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Have live USB ready** | Emergency access | Safety net |
| **Know GRUB recovery** | Boot fixes | Self-reliance |
| **Check filesystem first** | Before other fixes | Root cause |
| **Backup before rescue** | Don't make it worse | Safety |

### The "Won't Boot" Checklist

```bash
# 1. Try single user mode
# 2. Try init=/bin/bash
# 3. Check filesystem with fsck
# 4. Check fstab
# 5. Check GRUB config
# 6. Boot from live USB
```

---

**Why these rules matter:** Following these rules helps you recover from system failures quickly and safely.

[← Previous](15-final-self-test-can-you-answer.md) | [↑ Index](index.md)
