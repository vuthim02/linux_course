## ⭐ Level 3: Advanced — Console Internals and Recovery

![Serial port — DB-9 connector for serial console access](https://upload.wikimedia.org/wikipedia/commons/7/7c/Serial_port.jpg)

*Serial port (DB-9 connector) — used for out-of-band console access (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Understand the Linux TTY subsystem internals, master console recovery techniques, and handle emergency access scenarios.

### What You'll Cover
- The TTY subsystem: kernel, line discipline, and terminal emulator layers
- Pseudo-terminal (PTY) allocation and SSH sessions
- Console recovery: booting to single-user mode
- Using a serial console for headless server rescue
- Emergency access when the system won't boot

The Linux TTY subsystem has three layers: the kernel driver (which handles keyboard input and screen output), the line discipline (which processes special characters like Ctrl+C), and the terminal emulator (which renders text). Understanding this stack explains why certain keystrokes behave the way they do.

At this level you will master:

- **PTY allocation**: When you open an SSH session, the server allocates a PTY from `/dev/ptmx`. The master side is held by sshd, the slave side (`/dev/pts/0`) is your terminal. This is why `tty` in SSH shows `/dev/pts/0`, not `/dev/tty1`.
- **Console recovery**: If the system is unresponsive, you can boot into single-user mode by editing the GRUB entry and appending `single` or `init=/bin/bash` to the kernel line. This drops you to a root shell with minimal services.
- **Serial console rescue**: For servers without physical access, configure a serial console via BIOS/UEFI settings and connect via a serial-to-USB adapter. Set `console=ttyS0,115200` in the kernel parameters to redirect console output.
- **Emergency access**: When GRUB is broken, boot from a Live USB, mount your root partition, `chroot` into it, and reinstall GRUB. When the filesystem is corrupt, boot into the initramfs and run `fsck` on unmounted partitions.


[← Previous](08-section-5-console-management.md) | [↑ Index](index.md) | [Next →](10-deep-understanding-tty-subsystem-and.md)
