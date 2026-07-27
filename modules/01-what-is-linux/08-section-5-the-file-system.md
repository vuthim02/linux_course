## 🔍 Section 5: The File System — Everything Is a File

This is the most important idea in Linux:

> **In Linux, EVERYTHING is a file.**

Your keyboard? A file.
Your hard drive? A file.
Your network connection? A file.
Running processes? Files.

This makes Linux incredibly powerful — you can control anything by reading or writing files.

### The Linux File System Tree

Linux organizes all files in a single **tree** starting from `/` (called "root"):

```
/                        ← The root (top of everything)
├── bin/                 ← Essential commands (ls, cp, mv...)
├── boot/                ← Files needed to start Linux
├── dev/                 ← Hardware devices as files
├── etc/                 ← System configuration files
├── home/                ← User home directories
│   └── yourname/        ← YOUR personal space (~)
├── lib/                 ← System libraries
├── media/               ← External drives (USB, CD)
├── mnt/                 ← Manually mounted drives
├── opt/                 ← Optional/third-party software
├── proc/                ← Running processes as files (virtual)
├── root/                ← Home directory of the root user
├── sbin/                ← System admin commands
├── srv/                 ← Service data (web, FTP)
├── sys/                 ← Hardware info as files (virtual)
├── tmp/                 ← Temporary files (cleared on reboot)
├── usr/                 ← User programs and libraries
└── var/                 ← Variable data: logs, databases, mail
```

### Most Important Directories for a SysAdmin

| Directory | Why You Care |
|---|---|
| `/etc` | ALL system config lives here. Learn this deeply. |
| `/var/log` | ALL system logs. You debug here. |
| `/home` | Where user data lives. |
| `/proc` | Live info about running system (CPU, memory, processes). |
| `/dev` | Hardware devices. Disks are `/dev/sda`, `/dev/sdb`, etc. |
| `/tmp` | Temporary. Never store important things here. |

---



---

[← Previous](07-level-2-intermediary-navigating-the.md) | [↑ Index](index.md) | [Next →](09-section-6-users-and-permissions.md)
