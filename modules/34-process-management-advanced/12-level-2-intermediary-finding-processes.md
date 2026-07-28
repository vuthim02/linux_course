## ⭐ Level 2: Intermediary — Finding Processes, Limits, and OOM

![Linux process state diagram showing transitions between states](https://upload.wikimedia.org/wikipedia/commons/e/e4/Linux_kernel_process_states.png)

> *"When servers crash at 3 AM, you don't have time to browse through a forest view. You need `pgrep`, `pkill`, and `ulimit` memorized. The OOM killer isn't random — it's math. Learn the formula, and you can control who survives."*

### What You'll Cover
- `pgrep` and `pkill`: finding processes by name, user, or pattern
- Resource limits: `ulimit`, `/etc/security/limits.conf`, systemd `LimitNOFILE`
- OOM killer: how it scores processes, `oom_score_adj` tuning
- `/proc/<pid>/` deep dive: status, fd, maps, limits, environ
- Persistent processes: `nohup`, `disown`, `setsid`, `screen`, `tmux`
- Background process management and detachment

At this level you move from listing processes to finding, limiting, and protecting them.

At this level you will practice:

- **`pgrep`/`pkill`**: `pgrep -u www-data nginx` finds nginx processes running as www-data. `pkill -HUP nginx` sends SIGHUP to all nginx processes for config reload. `pgrep -a nginx` shows the full command line. These are faster and more scriptable than `ps | grep`.
- **Resource limits**: `ulimit -a` shows current limits. `ulimit -n 65535` sets open file limits. For persistent limits, edit `/etc/security/limits.conf`: `www-data soft nofile 65535`. Systemd services use `LimitNOFILE=65535` in unit files.
- **OOM killer**: The kernel kills processes when memory is exhausted. Each process has an `oom_score` (0-1000, higher = more likely to be killed). Protect critical processes: `echo -1000 > /proc/$(pidof sshd)/oom_score_adj`. The OOM killer considers process size, runtime, and user limits.
- **`/proc/<pid>/`**: `status` shows memory and thread counts. `fd/` shows open file descriptors (symlinks to files). `maps` shows memory layout. `limits` shows resource limits. `environ` shows environment variables. This is the raw data behind `ps`.
- **Persistent processes**: `nohup command &` survives terminal close. `disown %1` removes a job from the shell's job table. `setsid command` starts a new session. For long-running services, use systemd — `nohup` is for temporary tasks.


[← Previous](11-13-cron-and-long-running-processes.md) | [↑ Index](index.md) | [Next →](13-4-pgrep-pkill-finding-and.md)
