## 🔍 Section 1: The Boot Process Overview

The Linux boot process has 6 stages:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ POWER ON │───►│  BIOS/   │───►│  GRUB    │───►│  KERNEL  │───►│   INIT   │───►│  LOGIN   │
│          │    │  UEFI    │    │  BOOT    │    │          │    │ (SYSTEMD)│    │  PROMPT  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
 Stage 1         Stage 2         Stage 3         Stage 4         Stage 5         Stage 6
 Hardware        Firmware        Bootloader      OS Kernel      Userspace       Ready
```

| Stage | Duration | What Happens |
|-------|----------|-------------|
| 1. Power On | < 1s | Power supply stabilizes, CPU resets, starts firmware |
| 2. BIOS/UEFI | 1-5s | POST, hardware detection, boot device selection |
| 3. GRUB | 1-3s | Loads kernel and initramfs into memory |
| 4. Kernel | 2-10s | Initializes hardware, mounts root filesystem |
| 5. systemd | 5-30s | Starts services, reaches target (multi-user/graphical) |
| 6. Login | — | Display manager or console login prompt |

---



---

[← Previous](02-level-1-basic-foundations-of.md) | [↑ Index](index.md) | [Next →](04-section-2-stage-1-power.md)
