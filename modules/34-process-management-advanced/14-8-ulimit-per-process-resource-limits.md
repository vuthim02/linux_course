## 8. `ulimit` — Per-Process Resource Limits

`ulimit` controls resource limits stored in `task_struct->signal->rlim`. Each resource has a soft limit (current boundary) and a hard limit (ceiling that only root can raise).

### Viewing Limits

```
$ ulimit -a
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
open files                      (-n) 1024
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 15497
virtual memory          (kbytes, -v) unlimited
```

### Key Limits

| Limit | Flag | Typical Default | Why It Matters |
|---|---|---|---|
| `open files` | `-n` | 1024 | Web servers/DBs need far more |
| `stack size` | `-s` | 8192 KB | Deep recursion overflows it |
| `core file size` | `-c` | 0 | Must be > 0 to get core dumps |
| `max user processes` | `-u` | ~15000 | Prevents fork bombs |
| `file size` | `-f` | unlimited | Prevent runaway log fills |

### Setting Limits

```
$ ulimit -n 4096                  # set open file limit (soft)
$ ulimit -c unlimited             # enable core dumps
$ ulimit -u 500                   # max 500 processes for this shell
```

### `/etc/security/limits.conf`

```
# /etc/security/limits.conf
*           soft    nproc          4096
*           hard    nproc          16384
@admins     soft    nofile         16384
@admins     hard    nofile         65536
```

### systemd Limits

```
[Service]
LimitNOFILE=65536
LimitNPROC=4096
LimitCORE=infinity
```

### Why `nofile` Matters

Every socket, open file, pipe, and epoll FD consumes a slot in `task->files->fdt->fd[]`. The default 1024 is too low for databases and web servers.

```
$ sudo cat /proc/$(pgrep -x mysqld)/limits
```

### Fork Bomb Protection

```
$ ulimit -u 500
$ :(){ :|:& };:     # fork bomb at 500 processes → EAGAIN
```

---



---

[← Previous](13-4-pgrep-pkill-finding-and.md) | [↑ Index](index.md) | [Next →](15-9-oom-killer-out-of-memory-resolution.md)
