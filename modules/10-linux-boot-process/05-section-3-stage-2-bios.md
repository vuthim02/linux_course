## 🔍 Section 3: Stage 2 — BIOS vs UEFI

### BIOS (Legacy)

```bash
# BIOS = Basic Input/Output System
# - 16-bit mode
# - Runs in real mode (no memory protection)
# - Reads the Master Boot Record (MBR) from the boot device
# - MBR is 512 bytes, stored in the FIRST sector of the disk
# - MBR contains bootloader code (stage 1) and partition table

# MBR layout:
# Bytes 0-445:   Bootloader code (stage 1)
# Bytes 446-509: Partition table (4 entries, 16 bytes each)
# Bytes 510-511: Boot signature (0x55 0xAA)

# BIOS limitation: MBR can only address disks up to 2TB
```

### UEFI (Modern)

```bash
# UEFI = Unified Extensible Firmware Interface
# - 32-bit or 64-bit mode
# - Can run in protected mode with memory protection
# - Reads EFI System Partition (ESP) — FAT32 formatted
# - ESP contains .efi bootloader files
# - Supports Secure Boot (cryptographic signature verification)

# ESP location:
# - Usually /boot/efi or /boot/EFI
# - Contains: /EFI/ubuntu/grubx64.efi, /EFI/BOOT/bootx64.efi

# UEFI advantages:
# - Faster boot
# - GUI configuration
# - Mouse support
# - Network boot
# - GPT partition tables (supports > 2TB disks)
```

### Checking Your System

```bash
# Check if booting in BIOS or UEFI mode
ls /sys/firmware/efi
# If directory exists = UEFI
# If directory does not exist = BIOS

# Or check kernel boot messages
dmesg | grep -i "efi\|bios"

# Check partition table type
sudo fdisk -l /dev/sda | grep "Disklabel"
# "gpt" = GPT (usually UEFI)
# "dos" = MBR (usually BIOS)
```





[← Previous](04-section-2-stage-1-power.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-boot-configuration.md)
