## 📋 Summary — Complete Command Reference for Part 25

### ⭐ Level 1 Commands: Basic Rescue Mode Operations

| Command/Action | Purpose |
|----------------|---------|
| `systemctl rescue` | Boot to rescue mode |
| `systemctl emergency` | Boot to emergency mode |
| GRUB: add `single` | Single-user mode |
| GRUB: add `init=/bin/bash` | Root shell without password |
| `sudo touch /forcefsck` | Force fsck on next boot |
| `sudo smartctl -H /dev/sda` | Check disk health |

### ⭐ Level 2 Commands: Intermediate Recovery Techniques

**Filesystem Repair**

| Command | Action |
|---------|--------|
| `sudo fsck -y /dev/sda1` | Repair filesystem (auto-yes) |
| `sudo fsck -f /dev/sda1` | Force check even if clean |
| GRUB: add `fsck.mode=force` | Force filesystem check at boot |

**GRUB Recovery**

| Command | Action |
|---------|--------|
| `grub-install /dev/sda` | Reinstall GRUB (BIOS) |
| `grub-install --target=x86_64-efi` | Reinstall GRUB (UEFI) |
| `update-grub` | Regenerate GRUB config |
| `exit` (from rescue shell) | Continue boot if possible |

**chroot Recovery**

| Command | Action |
|---------|--------|
| `sudo mount /dev/sda1 /mnt` | Mount root |
| `sudo mount --bind /dev /mnt/dev` | Bind /dev |
| `sudo chroot /mnt /bin/bash` | Enter chroot |
| `sudo umount -R /mnt` | Unmount everything |

### ⭐ Level 3 Commands: Advanced Boot Diagnostics

| Command/Action | Purpose |
|----------------|---------|
| `journalctl -b -1` | View previous boot logs |
| `journalctl -b -p err` | Show boot errors only |
| `dmesg \| grep -i "error\|panic"` | Check kernel messages |
| `lsinitramfs /boot/initrd.img-*` | List initramfs contents |

---



---

[← Previous](13-deep-understanding-how-system-recovery.md) | [↑ Index](index.md) | [Next →](15-final-self-test-can-you-answer.md)
