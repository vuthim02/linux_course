## 9. `dstat` — Versatile Real-Time Aggregator

`dstat` combines `vmstat`, `iostat`, `netstat`, and `ifstat` into a single configurable view.

```
$ dstat
You did not select any stats, using -cdngy by default.
----total-cpu-usage---- -dsk/total- -net/total- ---paging-- ---system--
usr sys idl wai hiq siq| read  writ| recv  send|  in   out | int   csw
  5   2  92   1   0   0|  45k   67k| 123k  456k|   0     0 |1234  5678
  4   2  93   1   0   0|  32k   55k| 110k  420k|   0     0 |1189  5432
```

### Key Options

| Option | Meaning |
|---|---|
| `-c` | CPU stats |
| `-d` | Disk I/O |
| `-n` | Network |
| `-g` | Page (swap) stats |
| `-y` | System (interrupts, context switches) |
| `-l` | Load average |
| `-m` | Memory |
| `--output file.csv` | Write CSV to file |
| `--top-cpu` | Show top CPU consumer |
| `--top-io` | Show process doing the most I/O |
| `--top-mem` | Show top memory consumer |

### Real-World Examples

```
$ dstat -tc --top-cpu 2
$ dstat -td --top-io --top-bio 2
$ dstat -tcmdngy --output /tmp/performance.csv 5 120
$ dstat -tn --top-cpu --top-io --top-mem 2
```

### Plugins

```
$ dstat --list
```

Plugins include `dstat-freespace`, `dstat-mysql`, `dstat-nginx`, `dstat-sendmail`, `dstat-thermal`, `dstat-top-oom`.





[← Previous](12-8-ss-socket-statistics-modern.md) | [↑ Index](index.md) | [Next →](14-10-nmon-all-in-one-ncurses-monitor.md)
