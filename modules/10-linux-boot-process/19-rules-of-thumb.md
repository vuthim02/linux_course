## 📏 Rules of Thumb

### The Boot Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Never edit grub.cfg directly** | It gets regenerated | Changes lost |
| **Use /etc/default/grub** | User-editable config | Persistent changes |
| **Always run update-grub** | Regenerate config | Apply changes |
| **Test fstab before reboot** | `mount -a` | Prevent boot failure |
| **Use UUID in fstab** | Device names change | Stability |

### The systemd Rules

| Rule | Description | Why |
|------|-------------|-----|
| **systemctl daemon-reload** | After changing unit files | Reload configuration |
| **Check status first** | `systemctl status service` | See what's wrong |
| **Check logs second** | `journalctl -u service` | See errors |
| **Restart after config change** | `systemctl restart service` | Apply changes |

### The "Won't Boot" Checklist

```bash
# 1. Check GRUB menu:
#    Press 'e' to edit boot entry

# 2. Try single user mode:
#    Add 'single' to kernel line

# 3. Try init=/bin/bash:
#    Add 'init=/bin/bash' to kernel line

# 4. Check fstab:
#    Boot from live USB, check /etc/fstab

# 5. Check filesystem:
#    fsck /dev/sda1

# 6. Check logs:
#    journalctl -b    # From live USB
```

### The systemd Unit File Location Rules

```bash
# System-wide units:
/etc/systemd/system/          # Admin-created
/run/systemd/system/          # Runtime units
/usr/lib/systemd/system/      # Package-installed

# Priority: /etc > /run > /usr/lib
# (Admin overrides package defaults)
```

### The GRUB Recovery Rules

```bash
# 1. Edit GRUB entry at boot:
#    Press 'e' at GRUB menu

# 2. Find the 'linux' line:
#    Edit parameters

# 3. Common recovery options:
single          # Single user mode
init=/bin/bash  # Root shell
rw              # Read-write root
nomodeset       # Disable GPU drivers

# 4. Press Ctrl+X to boot

# 5. After fixing, update GRUB:
update-grub
```

---

**Why these rules matter:** The boot process is critical — a mistake here can make your system unbootable. Following these rules prevents most boot-related emergencies.

[← Previous](18-self-test-can-you-answer-these.md) | [↑ Index](index.md)
