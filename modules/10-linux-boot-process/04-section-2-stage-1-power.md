## 🔍 Section 2: Stage 1 — Power On

When you press the power button:

```bash
1. Power supply sends POWER_GOOD signal to motherboard
2. CPU resets and loads the firmware (BIOS/UEFI) from ROM
3. CPU starts executing the firmware code
4. Firmware initializes essential hardware:
   - CPU and memory controllers
   - System clock
   - Interrupt controllers
   - Basic I/O (keyboard, display)
```

At this point, nothing Linux-specific has happened. The firmware doesn't know or care about Linux.





[← Previous](03-section-1-the-boot-process.md) | [↑ Index](index.md) | [Next →](05-section-3-stage-2-bios.md)
