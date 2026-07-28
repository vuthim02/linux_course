## 18. Command Reference

### Level 1: Basic Monitoring

| Command | Package | Purpose | Key Flags |
|---|---|---|---|
| `top` | procps-ng | Interactive process viewer | `-b` batch, `-n` iterations, `-p` PID |
| `htop` | htop | Enhanced interactive viewer | `-s` sort, `-t` tree, `-u` user |
| `free` | procps-ng | Memory usage | `-h`, `-g`, `-m`, `-s` seconds |

### Level 2: Intermediary Monitoring

| Command | Package | Purpose | Key Flags |
|---|---|---|---|
| `vmstat` | procps-ng | System-wide snapshot | `delay count`, `-s` stats, `-d` disk |
| `iostat` | sysstat | Per-disk I/O | `-x` extended, `-p` per partition |
| `mpstat` | sysstat | Per-CPU breakdown | `-P ALL`, `-I` interrupts |
| `ss` | iproute2 | Socket stats | `-tulnp`, `-s`, `-i`, `-o` |
| `dstat` | dstat | Aggregated real-time | `-c`, `-d`, `-n`, `--top-cpu` |
| `nmon` | nmon | TUI all-in-one | `-f` capture, `-s` interval, `-c` count |
| `glances` | glances (pip) | Python comprehensive | `-s` server, `-c` client, `-w` web |
| `sar` | sysstat | Historical data collection | `-u`, `-r`, `-b`, `-n DEV` |
| `lnav` | lnav | Log file navigator | Color, SQL, multi-format |
| `journalctl` | systemd | systemd journal | `-xe`, `-u`, `-f`, `-k`, `-p` |
| `ncdu` | ncdu | Interactive disk usage analyzer | `-o` export CSV, `-f` read export |
| `cockpit` | cockpit | Web-based server admin | `cockpit.socket` service, port 9090 |
| `sos` | sos | System diagnostic report | `report`, `collect`, `--batch` |

### Level 3: Advanced Monitoring

| Command | Package | Purpose | Key Flags |
|---|---|---|---|
| `smartctl` | smartmontools | S.M.A.R.T. control | `-a`, `-H`, `-t short/long`, `-l selftest` |
| `badblocks` | e2fsprogs | Disk surface scan | `-sv`, `-svn`, `-w` |
| `perf` | linux-tools | Linux profiling | `top`, `record`, `report`, `stat` |
| `bcc` | bpfcc-tools | BPF-based tracing | `execsnoop`, `biolatency`, `tcptop` |
| `atop` | atop | Advanced process/performance | `-r` replay, `-w` write |
| `collectl` | collectl | High-precision monitoring | `-s` subsystems, `-o` output |

### Quick Installation by Distribution

**Debian/Ubuntu:**
```bash
sudo apt install htop sysstat dstat nmon glances smartmontools lnav atop bpfcc-tools
```

**RHEL/Fedora:**
```bash
sudo dnf install htop sysstat dstat nmon glances smartmontools lnav atop bcc-tools
```





[← Previous](22-13-disk-health-monitoring.md) | [↑ Index](index.md) | [Next →](24-19-15-hands-on-practices.md)
