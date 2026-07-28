## 12. Background / Foreground Jobs

### Job Control Basics

```
$ sleep 100 &
[1] 12345
$ sleep 200 &
[2] 12346
```

### `jobs` — List Background Jobs

```
$ jobs
[1]-  Running                 sleep 100 &
[2]+  Running                 sleep 200 &
```

### `fg` — Bring to Foreground

```
$ fg %1
sleep 100
```

### `bg` — Continue Stopped Job in Background

```
$ sleep 300
^Z
[1]+  Stopped                 sleep 300
$ bg %1
[1]+ sleep 300 &
```

### `nohup` — Immune to HUP Signal

```
$ nohup long_running_script.sh &
[1] 12400
$ exit
```

After logout, output goes to `nohup.out`.

### `disown` — Remove Job From Shell's Job Table

```
$ long_running_script.sh &
[1] 12500
$ disown %1
```

The process is now disconnected from the shell. SIGHUP on logout will NOT reach it.

### `setsid` — Create New Session

```
$ setsid long_running_script.sh
```

The new process is not part of the current terminal's session, so it survives logout without needing `nohup`.

### Foreground vs Background — What Actually Happens

```
Foreground:
  PID   PGID   SID   CMD
  952   952    952   bash
 1300   952    952   sleep 100    ← same PGID, same SID as shell

Background &:
  PID   PGID   SID   CMD
 1301  1301    952   sleep 100    ← different PGID, same SID

nohup / setsid:
  PID   PGID   SID   CMD
 1302  1302   1302   sleep 100    ← different PGID, different SID (immune)
```





[← Previous](09-7-nice-renice-scheduling-priority.md) | [↑ Index](index.md) | [Next →](11-13-cron-and-long-running-processes.md)
