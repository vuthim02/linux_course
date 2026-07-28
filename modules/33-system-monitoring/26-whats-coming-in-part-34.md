## What's Coming in Part 34

```
🐧 Linux System Administrator — Complete Course
Part 34 of ∞: Process Management
```

**Topics:**
- Process lifecycle (fork, exec, exit, wait)
- Process states (R, S, D, T, Z, X) and what forces each transition
- Signals — full catalog (SIGHUP to SIGRTMAX), default actions, which can be caught
- `kill`, `pkill`, `killall`, `pgrep` — every signal-sending tool
- `nice`/`renice` — priority manipulation and scheduler policies
- `nohup`, `disown`, `setsid` — escaping the terminal
- `screen` and `tmux` — terminal multiplexers for session persistence
- `/proc/<pid>/` deep dive — every directory entry explained
- Process limits — `ulimit`, `limits.conf`, `systemd` resource control
- OOM killer — score adjustment, why certain processes die first
- Cgroups v2 — process grouping, resource constraints, pressure stall information (PSI)

### How Part 33 Connects
Monitoring tells you *what* is happening; process management tells you *why* and lets you fix it. When `top` shows a CPU spike, you need `ps`, `pgrep`, and `kill` to identify and control the offending process. When memory is exhausted, understanding the OOM killer determines which process survives.


[← Previous](25-20-self-test.md) | [↑ Index](index.md) | [Next →](27-footer.md)
