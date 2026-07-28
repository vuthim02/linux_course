## 3. `pstree` — Visualizing Process Hierarchy

```
$ pstree
systemd─┬─ModemManager───2*[{ModemManager}]
        ├─NetworkManager───2*[{NetworkManager}]
        ├─sshd───sshd───sshd───bash───pstree
        └─systemd-journald
```

### Useful Options

| Option | Effect |
|---|---|
| `-p` | Show PIDs |
| `-T` | Hide threads (show only processes) |
| `-a` | Show command line arguments |
| `-u` | Show UID transitions |
| `-s <pid>` | Show only ancestors of the given PID |
| `-n` | Sort by PID (numeric) |

```
$ pstree -p -s $$
systemd(1)───sshd(900)───sshd(950)───sshd(951)───bash(952)───pstree(1300)
```





[← Previous](05-2-ps-snapshot-of-the.md) | [↑ Index](index.md) | [Next →](07-5-signals-the-kernels-inter-process.md)
