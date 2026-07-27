## 6. `kill` / `killall` — Sending Signals

### `kill` — Signal by PID

```
$ kill <PID>                 # SIGTERM (15) — ask nicely
$ kill -9 <PID>              # SIGKILL — forcible
$ kill -SIGSTOP <PID>        # SIGSTOP — freeze
$ kill -SIGCONT <PID>        # resume
$ kill -1 <PID>              # SIGHUP — often reload config
$ kill -0 <PID>              # 0 = test if process exists (no signal sent)
```

`kill -0` is a zero-cost existence check:

```
if kill -0 "$PID" 2>/dev/null; then
    echo "Process $PID is alive"
fi
```

### `killall` — Signal by Name

```
$ killall nginx               # SIGTERM all 'nginx' processes
$ killall -9 java             # SIGKILL all java processes
$ killall -u tim              # kill everything owned by tim
$ killall -w nginx            # wait for processes to die
```

`killall` matches **process names** (`task->comm`), not command-line args. For that use `pkill -f`.

---



---

[← Previous](07-5-signals-the-kernels-inter-process.md) | [↑ Index](index.md) | [Next →](09-7-nice-renice-scheduling-priority.md)
