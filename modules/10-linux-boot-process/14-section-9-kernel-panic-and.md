## 🔍 Section 9: Kernel Panic and System Recovery

### Kernel Panic

A **kernel panic** is the kernel's way of saying "I cannot recover from this error." It stops everything.

```bash
# What you see:
# Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
# or:
# Kernel panic - not syncing: Attempted to kill init!
```

### Common Causes of Kernel Panic

```bash
# 1. Missing or wrong root filesystem
#    - Wrong root= parameter in GRUB
#    - initramfs missing required drivers
#    - Filesystem corruption

# 2. Hardware failure
#    - Bad RAM (run memtest86)
#    - Failing disk

# 3. Kernel bug or incompatible driver
#    - Try booting an older kernel from GRUB

# 4. Out of memory (OOM)
#    - System ran out of memory and killed a critical process
```

### Recovery Methods

```bash
# Method 1: Boot an older kernel
# At GRUB menu → Advanced options → Select previous kernel

# Method 2: Boot to recovery mode
# At GRUB menu → Advanced options → Recovery mode

# Method 3: Edit kernel parameters at GRUB
# Press 'e' at GRUB, add 'single' or 'init=/bin/bash'

# Method 4: Use Live USB
# Boot from USB, mount root, chroot, fix the problem
```

---



---

[← Previous](13-section-8-grub-rescue-and.md) | [↑ Index](index.md) | [Next →](15-deep-understanding-the-initramfs-and.md)
