## 9. OOM Killer — Out-of-Memory Resolution

When the kernel runs out of memory and swap, `__alloc_pages_slowpath()` fails to find a page. The kernel invokes the OOM killer via `out_of_memory()` → `select_bad_process()`.

### `oom_score`

Every task has an `oom_score` (0-1000) visible in `/proc/PID/oom_score`. The higher the number, the more likely the process gets killed.

```
$ cat /proc/1/oom_score
0
$ cat /proc/$$/oom_score
1
```

### How `select_bad_process()` Works

One `oom_badness()` function assigns a score:

```
oom_score = (total_rss + total_swap + page_table_pages) * 1000 / total_memory
          - oom_score_adj
```

Factors that increase the score: large RSS, large swap usage, many page table pages.
Factors that reduce the score: being root, being init (PID 1 is immune — `oom_score_adj` of -1000).

### `oom_score_adj`

Ranges from -1000 (OOM immune) to +1000 (always kill me first).

```
$ cat /proc/$$/oom_score_adj
0
$ sudo bash -c 'echo -1000 > /proc/1/oom_score_adj'   # already set for init
$ sudo bash -c 'echo 1000 > /proc/$$/oom_score_adj'    # this shell dies first
```

### `oom_adj` (Legacy)

Older interface; range -17 (immune) to +15 (highest kill priority). Maps internally to `oom_score_adj * 8`.

### OOM Killer Message

```
[pid]   uid  total_vm   rss  pgtables_bytes oom_score_adj name
[ 4567] 1000   131072  65000   500K             0         stress

Tasks: 28 total, 1 running, 27 sleeping, 0 stopped, 0 zombie
Memory: 1024000K total, 1024000K used, 0K free, 0K swap used
Killed process 4567 (stress) total-vm:524288kB, rss:260000kB, pgtables:500kB
```

### Systemd `OOMScoreAdjust`

```
[Service]
OOMScoreAdjust=-500
```

### Safe Guard: `vm.overcommit_memory`

```
sysctl vm.overcommit_memory
0 = heuristic overcommit (default)
1 = always overcommit
2 = don't overcommit (sum of RSS + swap)
```





[← Previous](14-8-ulimit-per-process-resource-limits.md) | [↑ Index](index.md) | [Next →](16-10-proc-filesystem-the-kernels.md)
