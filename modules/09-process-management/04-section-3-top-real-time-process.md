## 🔍 Section 3: top — Real-Time Process Monitoring

`top` refreshes every few seconds, showing a live view of the system.

```bash
# Start top
top

# Start top sorted by memory
top -o %MEM

# Show only processes of a specific user
top -u alice

# Batch mode (for scripts)
top -b -n 1
```

### Understanding the top Header

```bash
top - 10:30:45 up 3 days,  2:15,  3 users,  load average: 0.08, 0.12, 0.10
Tasks: 245 total,   1 running, 244 sleeping,   0 stopped,   0 zombie
%Cpu(s):  2.5 us,  0.8 sy,  0.0 ni, 96.5 id,  0.2 wa,  0.0 hi,  0.0 si
MiB Mem :   7932.8 total,   2045.6 free,   3245.2 used,   2642.1 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   4289.6 avail Mem
```

| Line | Key Fields | Meaning |
|------|-----------|---------|
| Top | `load average` | 1, 5, 15 minute averages. < cores = healthy |
| Tasks | `running`, `sleeping`, `zombie` | Process counts |
| CPU | `us`, `sy`, `id`, `wa` | User, system, idle, I/O wait |
| Mem | `total`, `used`, `free`, `buff/cache` | RAM usage |
| Swap | `total`, `used` | Swap usage |

### Interactive top Commands

While `top` is running:

| Key | Action |
|-----|--------|
| `q` | Quit |
| `h` | Help |
| `1` | Toggle per-CPU stats |
| `P` | Sort by CPU usage (descending) |
| `M` | Sort by memory usage (descending) |
| `T` | Sort by running time |
| `k` | Kill a process (enter PID, then signal) |
| `r` | Renice a process (change priority) |
| `u` | Show only one user's processes |
| `c` | Toggle full command path |
| `W` | Write current settings to ~/.toprc |

### htop — Enhanced top

```bash
# Install
sudo apt install htop       # Debian/Ubuntu
sudo dnf install htop        # Fedora

# Run
htop
```

`htop` adds:
- Color-coded display
- Mouse support (click to sort, select)
- Tree view (F5)
- Easy kill/renice with arrow keys
- Scroll through all processes
- Vertical and horizontal scrolling





[← Previous](03-section-2-ps-snapshot-of.md) | [↑ Index](index.md) | [Next →](05-section-4-signals-how-to.md)
