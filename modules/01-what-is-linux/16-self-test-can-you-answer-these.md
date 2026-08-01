## 📝 Self-Test — Can You Answer These?

Before moving to Part 2, answer these without looking:

1. What does `$` vs `#` mean at the end of a prompt?
2. What is the difference between the **kernel** and the **shell**?
3. Where do system configuration files live?
4. Where do system logs live?
5. What command shows you who you are?
6. What does `/proc` contain and where does its data come from?
7. What does `cat /etc/hostname` do?
8. What is the **PATH** variable used for?

If you can answer 6 out of 8, you are ready for Part 2.


## Answer Key

### Q1: What does `$` vs `#` mean at the end of a prompt?
**Answer:** `$` indicates a regular user shell; `#` indicates the root (superuser) shell.

### Q2: What is the difference between the kernel and the shell?
**Answer:** The kernel is the core of the OS that manages hardware, memory, and processes. The shell is a user-facing program (like bash) that interprets commands and communicates with the kernel.

### Q3: Where do system configuration files live?
**Answer:** `/etc/` is the primary directory for system-wide configuration files.

### Q4: Where do system logs live?
**Answer:** `/var/log/` contains system logs. On systemd systems, `journalctl` provides structured logging via journald.

### Q5: What command shows you who you are?
**Answer:** `whoami` (or `id` for UID/GID details).

### Q6: What does `/proc` contain and where does its data come from?
**Answer:** `/proc` is a virtual filesystem that provides real-time kernel and process information. Data is generated on-the-fly by the kernel, not stored on disk.

### Q7: What does `cat /etc/hostname` do?
**Answer:** Displays the system's hostname (the name assigned to this machine on the network).

### Q8: What is the PATH variable used for?
**Answer:** PATH is an environment variable containing a colon-separated list of directories the shell searches when you type a command without an absolute path.


[← Previous](15-whats-coming-in-part-2.md) | [↑ Index](index.md) | [Next →](../02-terminal/01-what-you-will-achieve-in.md)
