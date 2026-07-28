## ⭐ Level 1: Basic — Understanding Rescue Modes and Boot Concepts

![Linux Rescue Mode](https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Tux.svg/200px-Tux.svg.png)  
*The Linux penguin — your guide through recovery. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand single-user mode, rescue mode, and emergency mode. Know when and how to boot into each one.

### What You'll Cover
- The Linux boot process: BIOS/UEFI, GRUB, kernel, initramfs, init
- Single-user mode: minimal services for quick fixes
- Rescue mode: full environment with mounted root filesystem
- Emergency mode: memory-only root with minimal tools
- Accessing these modes through GRUB kernel parameters

Every sysadmin eventually faces a server that will not boot. Knowing the difference between single-user, rescue, and emergency mode determines whether you recover in five minutes or hours.

At this level you will learn:

- **Boot process**: BIOS/UEFI loads GRUB, GRUB loads the kernel and initramfs, the kernel mounts the root filesystem and starts init (systemd). Each stage can fail in different ways.
- **Single-user mode**: Boot with `single` or `init 1` appended to the kernel line. Mounts root read-only, starts minimal services. Use for quick fixes like correcting `/etc/fstab`.
- **Rescue mode**: Boot with `rescue` or `systemd.unit=rescue.target`. Mounts root read-only with most drivers loaded. Use when single-user is not enough but the system is mostly intact.
- **Emergency mode**: Boot with `emergency` or `systemd.unit=emergency.target`. Mounts a temporary root in RAM. Use when the root filesystem is corrupt and cannot be mounted.
- **GRUB editing**: Press `e` at the GRUB menu to edit the boot entry. Append parameters to the `linux` line, then Ctrl+X to boot.


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-recovery-boot-modes.md)
