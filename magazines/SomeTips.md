# 01. Firmware vs Software vs Hardware

## The Three Layers of Computing

Think of a computer like a human body:
- **Hardware** = your physical body (bones, muscles, organs)
- **Firmware** = your DNA (instructions hardcoded into your body)
- **Software** = your thoughts and habits (learned behaviors you can change)

---

## Hardware

Hardware is anything you can **touch**. The physical parts of a computer.

| Component | What It Does |
|-----------|-------------|
| CPU | Processes instructions |
| RAM | Temporary memory for running programs |
| Hard Drive / SSD | Permanent storage for files |
| Motherboard | Connects everything together |
| Network Card | Connects to the internet |
| BIOS/UEFI Chip | Stores firmware |

> Hardware is useless without firmware and software. A CPU without firmware is just a硅片 (silicon chip) doing nothing.

---

## Firmware

Firmware is **software burned into hardware**. It lives on a small chip on the motherboard or device and runs the moment you power on.

### Key Facts
- Written by hardware manufacturers
- Stored on ROM, EEPROM, or flash memory
- You rarely update it (but you should occasionally)
- Controls hardware at the lowest level

### Common Examples

| Device | Firmware Name |
|--------|--------------|
| Motherboard | BIOS or UEFI |
| Hard Drive | Internal controller firmware |
| SSD | SSD firmware (TRIM, wear leveling) |
| Router | Router OS (OpenWrt, DD-WRT) |
| SSD/NVMe | NVMe firmware |

### Check Your Firmware Version

```bash
# Motherboard/BIOS info
sudo dmidecode -s bios-version
sudo dmidecode -s bios-release-date

# UEFI info (if booted in UEFI mode)
ls /sys/firmware/efi/

# Hard drive firmware
sudo hdparm -I /dev/sda | grep "Firmware"

# SSD firmware
sudo smartctl -i /dev/nvme0n1 | grep -i firmware

# Network card firmware
sudo ethtool -i eth0 | grep firmware
```

### Update Firmware

```bash
# Debian/Ubuntu - update BIOS/UEFI
sudo apt install fwupd
sudo fwupdmgr get-updates
sudo fwupdmgr update

# Check pending firmware updates
sudo fwupdmgr get-updates --verbose
```

> ⚠️ **Warning:** Firmware updates can brick your device if interrupted. Only update when necessary and always follow manufacturer instructions.

---

## Software

Software is **programs you install and run**. It lives on your hard drive and loads into RAM when you use it.

### Two Types of Software

| Type | Examples | How to Install |
|------|----------|---------------|
| **System Software** | Kernel, drivers, shell, systemd | Comes with your OS |
| **Application Software** | Firefox, Vim, Docker, Ansible | You install it |

### Key Facts
- Written by developers (not hardware manufacturers)
- Stored on hard drive / SSD
- Can be installed, updated, or removed anytime
- Runs on top of firmware and hardware

### Check Installed Software

```bash
# Debian/Ubuntu - list installed packages
dpkg -l | wc -l

# Red Hat/CentOS - list installed packages
rpm -qa | wc -l

# Flatpak apps
flatpak list | wc -l

# Snap apps
snap list

# Show all running software
ps aux | wc -l
```

### Install / Update / Remove Software

```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade
sudo apt install htop
sudo apt remove firefox

# Red Hat/CentOS
sudo dnf update
sudo dnf install htop
sudo dnf remove firefox
```

---

## The Relationship

```
┌─────────────────────────────────────┐
│  SOFTWARE (Firefox, Vim, Docker)    │  ← You install and use this
├─────────────────────────────────────┤
│  FIRMWARE (BIOS, SSD controller)    │  ← Runs when power on, controls hardware
├─────────────────────────────────────┤
│  HARDWARE (CPU, RAM, Disk)          │  ← Physical parts you can touch
└─────────────────────────────────────┘
```

### Real-World Example: Booting a Computer

1. **Hardware** — You press the power button
2. **Firmware** (BIOS/UEFI) — Runs POST (Power-On Self-Test), finds bootable device
3. **Firmware** — Loads the bootloader (GRUB) from disk
4. **Software** — Bootloader loads the Linux kernel
5. **Software** — Kernel starts `systemd`, which starts all your services
6. **Software** — You see the login screen

---

## Quick Comparison

| Aspect | Hardware | Firmware | Software |
|--------|----------|----------|----------|
| **Touchable?** | Yes | No (lives on chip) | No (files on disk) |
| **Changeable?** | Only by replacing parts | Rarely (flash update) | Easily (apt install/remove) |
| **Written by** | Engineers | Device manufacturers | Developers |
| **Runs when** | Always (powered on) | Power on immediately | You launch it |
| **Example** | RAM stick | BIOS chip | Ubuntu Linux |
| **Failure** | Broken component | Bricked device | Crash / bug |

---

## Why This Matters for SysAdmins

- **Hardware fails** — you replace it
- **Firmware bugs** — you update it (carefully)
- **Software bugs** — you patch it (frequently)

When troubleshooting, always identify which layer the problem is in:
- System won't turn on? → **Hardware**
- System turns on but won't boot? → **Firmware** (BIOS/UEFI) or **Software** (bootloader)
- System boots but crashes? → **Software** (kernel, drivers, apps)
- Performance issues? → Could be any layer — check hardware first, then software

```bash
# Quick hardware check
sudo dmesg | grep -i error

# Check for firmware issues
sudo dmesg | grep -i firmware

# Check for software issues
journalctl -p err -b
```
