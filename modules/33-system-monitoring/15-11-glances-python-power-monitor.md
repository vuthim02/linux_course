## 11. `glances` — Python Power Monitor

`glances` is a cross-platform monitoring tool written in Python. It is the most feature-rich CLI monitor available.

```
$ glances
```

### Server/Client Mode

```
# On server (default port 61209)
$ glances -s

# On client
$ glances -c <server-ip>
```

### Export Modes

```
$ glances --export csv --export-csv-file /tmp/glances.csv
$ glances --export json
$ glances -w             # Web interface
$ curl http://localhost:61208/api/3/cpu
```

### Container Awareness

```
$ glances --docker
```

Shows per-container CPU, memory, network, and I/O.

---



---

[← Previous](14-10-nmon-all-in-one-ncurses-monitor.md) | [↑ Index](index.md) | [Next →](16-14-log-based-monitoring.md)
