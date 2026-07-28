## 4. `pgrep` / `pkill` — Finding and Signaling by Pattern

These tools search `/proc/*/comm` or the full command line for a pattern.

### `pgrep`

```
$ pgrep -u root sshd
900
950

$ pgrep -x bash
952

$ pgrep -f "python.*server"
1200
```

| Option | Meaning |
|---|---|
| `-u <user>` | Match only processes owned by user |
| `-x` | Exact name match |
| `-f` | Match full command line (not just comm) |
| `-n` | Newest match only |
| `-o` | Oldest match only |
| `-l` | Show PID and process name |
| `-a` | Show PID and full command line |
| `-c` | Count matches |

### `pkill`

Same matching as `pgrep`, but sends a signal (default SIGTERM).

```
$ pkill -x bash                # kill all bash shells (careful!)
$ pkill -f "python server.py"  # kill by full cmdline match
$ pkill -u tim -9              # SIGKILL everything owned by tim
$ pkill -SIGSTOP -f "make"     # STOP all make processes
```

**The pattern is a regex** by default. `pkill -x bash` matches exactly `bash`. `pkill bash` matches `bash`, `bashful`, `bash-4.4`.

### Safe Usage

`pkill -f` is powerful and dangerous — it matches the entire command line. Always test with `pgrep -l -f <pattern>` first.





[← Previous](12-level-2-intermediary-finding-processes.md) | [↑ Index](index.md) | [Next →](14-8-ulimit-per-process-resource-limits.md)
