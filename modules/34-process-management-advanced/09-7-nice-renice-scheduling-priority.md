## 7. `nice` / `renice` — Scheduling Priority

### Niceness (−20 to 19)

Niceness maps to the `task_struct->prio` field. The kernel's CFS uses this to weight time slices:

| Nice | Kernel Priority | Effect |
|---|---|---|
| -20 | 100 | Highest user priority (fastest CPU share) |
| 0 | 120 | Default |
| 19 | 139 | Lowest priority (minimal CPU share) |

### `nice` — Start with Given Niceness

```
$ nice -n 10 ./cpu_hog.sh        # start with nice 10
$ nice --20 ./urgent_task.sh     # start with nice -20 (needs root)
```

### `renice` — Change Niceness of Running Process

```
$ renice -n 10 -p 1234           # set PID 1234 to nice 10
$ renice -n -5 -u tim            # set all tim's processes to nice -5
$ renice -n 15 -g 500            # set all processes in group 500
```

Only root can set **negative** (higher priority) niceness. Regular users can only increase their own niceness.

### Real-World: Lower Priority for Backup

```
$ nice -n 19 tar czf backup.tar.gz /data
```

### Real-World: Boost Database Priority

```
$ sudo renice -n -5 -u postgres
```

---



---

[← Previous](08-6-kill-killall-sending-signals.md) | [↑ Index](index.md) | [Next →](10-12-background-foreground-jobs.md)
