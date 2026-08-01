## 🔍 Section 1: What Is systemd?

**systemd** is the init system and service manager for almost every modern Linux distribution.

### The Problem systemd Solves

Before systemd (SysV init):

```
Boot sequence:
1. Kernel starts PID 1 (/sbin/init)
2. PID 1 runs /etc/rc.d/rc.sysinit
3. Runs startup scripts in /etc/rc.d/rc3.d/ one at a time
4. Each script starts or stops things (S01network, S55sshd, K90crond)
5. Everything is sequential — slow
6. No dependency tracking — scripts just ran in order
```

With systemd:

```
Boot sequence:
1. Kernel starts PID 1 (/lib/systemd/systemd)
2. systemd reads dependency graph
3. Starts services in PARALLEL where possible
4. Tracks what depends on what
5. Much faster boot, cleaner management
```

### Why the Name "systemd"?

- "systemd" = System D (daemon)
- Follows Unix convention: daemons end with 'd'
- The 'd' is lowercase to distinguish from "System D" (a pun)

```bash
# systemd is always PID 1
ps -p 1 -o pid,comm,cmd
```

Output:
```
  PID COMMAND CMD
    1 systemd /sbin/init
```

Note: `/sbin/init` is a symlink to `systemd` on modern systems.

### Distributions Using systemd

| Distribution | Uses systemd since |
|---|---|
| Ubuntu | 15.04 (2015) |
| Debian | 8 (2015) |
| Fedora | 15 (2011) |
| RHEL / CentOS | 7 (2014) |
| Arch Linux | 2012 |
| openSUSE | 12.1 (2011) |

**Notics:**
- 1. ps -p \<PID> -o \<format> where \<format> is a comma-separated list of keywords (e.g., pid,comm,cmd,ppid,%cpu,%mem,user).


[← Previous](02-level-1-basic-systemd-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-2-systemctl-the-main.md)
