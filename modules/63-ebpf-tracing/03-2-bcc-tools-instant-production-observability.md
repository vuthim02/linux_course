## 2. bcc-tools — Instant Production Observability

### Installation

```bash
# Debian/Ubuntu
sudo apt install bpfcc-tools linux-headers-$(uname -r)

# RHEL/CentOS/Fedora
sudo dnf install bcc-tools bcc-doc

# Tools become available as *-bpfcc commands
ls /usr/sbin/*-bpfcc | head -20
```

### Essential bcc-tools

```
┌──────────────────────────────────────────────────────────────────┐
│  Tool               │  What It Traces             │  Command     │
├─────────────────────┼─────────────────────────────┼──────────────┤
│  execsnoop          │  New process execution      │  execsnoop   │
│  opensnoop          │  File opens (syscalls)      │  opensnoop   │
│  biolatency         │  Block I/O latency          │  biolatency  │
│  biosnoop           │  Each block I/O event       │  biosnoop    │
│  cachestat          │  Page cache hit/miss ratio  │  cachestat   │
│  tcplife            │  TCP connection lifetime    │  tcplife     │
│  tcpretrans         │  TCP retransmissions        │  tcpretrans  │
│  tcpconnect         │  Outgoing TCP connections   │  tcpconnect  │
│  filetop            │  Top files by I/O           │  filetop     │
│  ext4slower         │  Slow ext4 operations       │  ext4slower  │
│  xfsslower          │  Slow XFS operations        │  xfsslower   │
│  funccount          │  Kernel function calls      │  funccount   │
│  profile            │  CPU profiling (stack trace)│  profile     │
│  runqlat            │  Run queue latency          │  runqlat     │
│  oomkill            │  OOM killer invocations     │  oomkill     │
│  vfsstat            │  VFS operations             │  vfsstat     │
└──────────────────────────────────────────────────────────────────┘
```

### Key Tool Examples

```bash
# Trace all new processes
sudo execsnoop-bpfcc
# TIME     PID    PPID   RET    ARGS
# 10:23:01 12345  12340  0      /bin/bash -c sleep 10
# 10:23:01 12346  12345  0      /usr/bin/sleep 10

# Trace file opens (filter by process)
sudo opensnoop-bpfcc -n nginx
# TIME     COMM          PID    FD   ERR  PATH
# 10:23:01 nginx         1234   12   0    /etc/nginx/nginx.conf
# 10:23:01 nginx         1234   -1   2    /etc/nginx/ssl.conf  ← ENOENT

# Block I/O latency histogram
sudo biolatency-bpfcc -D
#     usecs               : count    distribution
#        32 -> 63         : 4500    |****************************************|
#        64 -> 127        : 2100    |**********************                  |
#       128 -> 255        : 890     |***********                             |

# Page cache effectiveness
sudo cachestat-bpfcc 1
# HITS   MISSES  DIRTIES HIT%   CACHED_MB
# 45230  1200    890     97.4   8432     ← healthy
# 21000  8900    340     70.2   8432     ← needs more RAM

# TCP connections with lifetime and bytes
sudo tcplife-bpfcc
# PID    COMM   LADDR:LPORT    RADDR:RPORT    TX_KB  RX_KB  MS
# 1234   nginx  10.0.0.5:80    10.0.0.10:43210  2     45     1200
```

> 🔍 **Reverse Engineering Insight:** bcc-tools are your first line of defense. The 80/20 rule applies: execsnoop, opensnoop, biolatency, cachestat, and tcplife solve 80% of production debugging problems without writing any code.





[← Previous](02-1-what-is-ebpf-the.md) | [↑ Index](index.md) | [Next →](04-3-bpftrace-the-tracing-power.md)
