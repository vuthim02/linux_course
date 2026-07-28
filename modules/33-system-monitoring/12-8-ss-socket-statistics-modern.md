## 8. `ss` — Socket Statistics (Modern `netstat`)

`ss` dumps socket statistics. It reads from kernel netlink interfaces, making it faster and more detailed than `netstat`.

### Basic Usage

```
$ ss -tuln      # All listening TCP/UDP sockets, numeric
Netid  State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port
tcp    LISTEN  0       128     0.0.0.0:22           0.0.0.0:*
tcp    LISTEN  0       128     127.0.0.1:3306       0.0.0.0:*
udp    UNCONN  0       0       0.0.0.0:5353         0.0.0.0:*
```

### Key Options

| Option | Meaning |
|---|---|
| `-t` | TCP sockets |
| `-u` | UDP sockets |
| `-l` | Listening sockets only |
| `-n` | Numeric (no DNS resolution) |
| `-p` | Show process (PID + name) |
| `-a` | All sockets (listening + established) |
| `-s` | Summary statistics |
| `-i` | Internal TCP info (ssthresh, cwnd, rtt) |

### Established Connections

```
$ ss -tpn
State      Recv-Q  Send-Q  Local Address:Port      Peer Address:Port              Process
ESTAB      0       0       10.0.0.5:22             192.168.1.10:54321             users:(("sshd",pid=1234,fd=3))
ESTAB      0       0       10.0.0.5:3306           10.0.0.20:45678                users:(("mysqld",pid=5678,fd=17))
```

### Monitoring Connection States

For web servers, watch `TIME-WAIT` and `CLOSE-WAIT`:

```
$ ss -t state time-wait
$ ss -t state close-wait
```

- **TIME-WAIT** — Normal for short-lived connections. Many is fine but can exhaust port ranges.
- **CLOSE-WAIT** — The remote peer closed, but local app hasn't called `close()`. This is a **socket leak**.





[← Previous](11-6-mpstat-per-cpu-breakdown.md) | [↑ Index](index.md) | [Next →](13-9-dstat-versatile-real-time-aggregator.md)
