## 10. `nmon` — All-in-One Ncurses Monitor

`nmon` (Nigel's Monitor) presents system statistics in a ncurses TUI with single-key toggles.

```
$ nmon
```

### Interactive Keys

| Key | Function |
|---|---|
| `c` | CPU utilization (per-core bar chart) |
| `m` | Memory and swap (bar + numbers) |
| `d` | Disks (per-disk I/O rates) |
| `k` | Kernel (load, context switches, uptime) |
| `n` | Network (per-interface) |
| `N` | NFS |
| `j` | Filesystem usage |
| `t` | Top processes (consuming CPU) |
| `h` | Help |
| `q` | Quit |

### Capture Mode (for scripting)

```
$ nmon -f -s 5 -c 120
```

Captures data every 5 seconds for 10 minutes, writing to a `.nmon` file.

---



---

[← Previous](13-9-dstat-versatile-real-time-aggregator.md) | [↑ Index](index.md) | [Next →](15-11-glances-python-power-monitor.md)
