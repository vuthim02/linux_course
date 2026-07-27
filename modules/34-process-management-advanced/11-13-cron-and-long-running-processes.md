## 13. Cron and Long-Running Processes — `screen`, `tmux`

### `screen` — Terminal Multiplexer

```
$ screen -S mywork        # create named session
$ screen -ls              # list sessions
$ screen -r mywork        # reattach
$ screen -d -r mywork     # detach elsewhere, reattach here
```

Inside screen:
- `Ctrl+A d` — detach
- `Ctrl+A c` — new window
- `Ctrl+A n` / `Ctrl+A p` — next/previous window
- `Ctrl+A k` — kill window

### `tmux` — Modern Terminal Multiplexer

```
$ tmux new -s mywork        # create named session
$ tmux ls                   # list sessions
$ tmux attach -t mywork     # reattach
$ tmux new -s backup -d     # create session in background
```

Inside tmux:
- `Ctrl+B d` — detach
- `Ctrl+B c` — new window
- `Ctrl+B n` / `Ctrl+B p` — next/previous window
- `Ctrl+B ,` — rename window
- `Ctrl+B %` — split vertical
- `Ctrl+B "` — split horizontal

### Use Case: Long Data Migration

```
$ tmux new -s migration
$ ./migrate_data.sh   # runs for 6 hours
# Ctrl+B d to detach
# Go home, SSH in later
$ tmux attach -t migration
# Check progress
```

### `screen` vs `tmux`

| Feature | screen | tmux |
|---|---|---|
| Split panes | Yes (complex) | Yes (easy) |
| Config file | `~/.screenrc` | `~/.tmux.conf` |
| Scriptable | Minimal | `send-keys`, `new-window` |
| Copy mode | `Ctrl+A [` | `Ctrl+B [` |
| Mouse support | `:termcapinfo xterm*` | `set -g mouse on` |

---



---

[← Previous](10-12-background-foreground-jobs.md) | [↑ Index](index.md) | [Next →](12-level-2-intermediary-finding-processes.md)
