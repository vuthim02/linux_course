# 🐧 Linux System Administrator — Complete Course
## Part 63 of ∞: eBPF & Modern Tracing — Observing the Invisible

---

> **Reverse Engineering Approach:** When `top` tells you CPU is busy but not what's consuming it, when a process stalls mysteriously, when you need to see every network packet or disk I/O without recompiling the kernel — traditional tools fall short. eBPF is the kernel's programmable superpower, and bpftrace, bcc-tools, strace, and perf are your lenses into the invisible world of kernel execution. This part takes you from zero to tracing anything on a running Linux system without ever touching the source code.

---

## 🎯 What You Will Achieve

- Understand the eBPF architecture, verifier, JIT compilation, and map data structures
- Use bcc-tools for instant production-safe observability (execsnoop, opensnoop, biolatency, cachestat)
- Write bpftrace one-liners and scripts for custom kernel tracing
- Master strace with filtering, timing, following children, and statistics
- Use perf for CPU profiling, cache miss analysis, branch prediction, and flame graphs
- Trace network packets with tcptrace, tc, and XDP basics
- Monitor filesystem I/O with ext4slower, xfsslower, and filetop
- Debug real-world production issues: slow I/O, memory leaks, CPU spikes
- Choose the right tracing tool for any debugging scenario

---

## 1. What is eBPF — The Kernel's Programmable Engine

### The Big Picture

eBPF (extended Berkeley Packet Filter) lets you run **sandboxed programs inside the kernel** without modifying kernel source or loading modules.

```
┌──────────────────────────────────────────────────────────────────┐
│                        USER SPACE                                 │
│   bpftrace  │  bcc-tools  │  perf  │  iproute2  │  Custom Tool  │
│      └────────────┴───────────┴─────────┴──────────────┘          │
│                          bpf() syscall                             │
├──────────────────────────────────────────────────────────────────┤
│                        KERNEL SPACE                               │
│   ┌─────────────────────────────────────────────────────┐        │
│   │               eBPF Verifier                          │        │
│   │   (Validates program safety before loading)         │        │
│   └──────────────────┬──────────────────────────────────┘        │
│   ┌──────────────────▼──────────────────────────────────┐        │
│   │               eBPF Maps (shared data structures)    │        │
│   └──────────────────┬──────────────────────────────────┘        │
│   ┌──────────────────▼──────────────────────────────────┐        │
│   │               JIT Compiler (bytecode → native)      │        │
│   └──────────────────┬──────────────────────────────────┘        │
│   ┌──────────────────▼──────────────────────────────────┐        │
│   │   Hook Points: kprobe │ tracepoint │ XDP │ tc │ LSM │        │
│   └─────────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

### eBPF Program Lifecycle

```
Write program (C/bpftrace) → Compile to bytecode → bpf() syscall
    → VERIFIER checks (no loops, no OOB, no null deref, bounded)
    → JIT compile to native x86_64/arm64
    → Attach to hook point → Execute on every event
    → Read results from eBPF maps → Detach and unload
```

### Kernel Version Requirements

```
┌─────────────────────────────────────────────────────────────┐
│  Feature              │  Minimum Kernel Version              │
├───────────────────────┼──────────────────────────────────────┤
│  Basic eBPF           │  3.18                               │
│  kprobes/uprobes      │  4.1                                │
│  BPF maps (hash/array)│  4.1                                │
│  Tracepoints          │  4.7                                │
│  BPF Type Format (BTF)│  4.18                               │
│  Ring buffers         │  5.8                                │
│  CO-RE (portable)     │  5.4                                │
└─────────────────────────────────────────────────────────────┘
```

### eBPF Maps — Shared Data Structures

```
┌─────────────────────────────────────────────────────────────┐
│  Map Type          │  Use Case            │  Key → Value    │
├────────────────────┼──────────────────────┼─────────────────┤
│  HASH              │  Counters, lookup    │  u32 → u64     │
│  ARRAY             │  Per-CPU stats       │  u32 → u64     │
│  RINGBUF           │  Streaming events    │  event → user  │
│  PERF_EVENT        │  Perf output         │  event → user  │
│  LRU_HASH          │  Bounded caches      │  u32 → u64     │
│  STACK_TRACE       │  Stack traces        │  tid → stack   │
└─────────────────────────────────────────────────────────────┘
```

```bash
sudo bpftool prog list          # List loaded eBPF programs
sudo bpftool map list           # List eBPF maps
sudo bpftool map dump id <ID>   # Show map contents
```

> 🔍 **Reverse Engineering Insight:** The eBPF verifier is the key innovation. It performs static analysis of your bytecode before it ever runs in the kernel. You can write custom tracing code and load it on production systems with confidence — the kernel guarantees it cannot crash or corrupt data.

⚠️ **Warning:** Most production tracing tools require kernel 4.15+ and ideally 5.4+. Check with `uname -r` first.

---

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

---

## 3. bpftrace — The Tracing Power Tool

### Installation

```bash
sudo apt install bpftrace       # Debian/Ubuntu
sudo dnf install bpftrace       # RHEL/Fedora
bpftrace --version
```

### One-Liners — Instant Answers

```bash
# Count syscalls by process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-16s %-6d %s\n", comm, pid, str(args->filename)); }'

# Measure VFS read latency
bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; } kretprobe:vfs_read /@start[tid]/ { @us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'

# Count signals sent per process
bpftrace -e 'tracepoint:signal:signal_generate { @[comm, args->sig] = count(); }'

# Monitor OOM kills
bpftrace -e 'kprobe:oom_kill_process { printf("OOM KILL: %s (PID %d)\n", comm, pid); }'

# CPU profiling (100 Hz sampling)
bpftrace -e 'profile:hz:100 { @[kstack] = count(); }'

# Page faults per process
bpftrace -e 'software:page-faults:1000000 { @[comm] = count(); }'
```

### Writing bpftrace Scripts

```bash
#!/usr/bin/env bpftrace
/* slowio.bt — Find slow I/O operations (> 10ms) */

tracepoint:block:block_rq_issue {
    @start[args->dev, args->sector] = nsecs;
}

tracepoint:block:block_rq_complete /@start[args->dev, args->sector]/ {
    $latency_us = (nsecs - @start[args->dev, args->sector]) / 1000;
    if ($latency_us > 10000) {
        printf("%-8d %-16s %d usecs %s\n", pid, comm, $latency_us, args->rwbs);
    }
    delete(@start[args->dev, args->sector]);
}
```

### Probe Types

```bash
# tracepoint: stable kernel tracing points (recommended for production)
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s -> %s\n", comm, str(args->filename)); }'

# kprobe: kernel function entry (dynamic, use when no tracepoint exists)
bpftrace -e 'kprobe:tcp_connect { printf("tcp_connect by %s\n", comm); }'

# kretprobe: kernel function return
bpftrace -e 'kretprobe:tcp_connect { printf("returned %d\n", retval); }'

# uprobe: userspace function entry
bpftrace -e 'uprobe:/usr/bin/bash:readline { printf("bash readline: %s\n", str(arg0)); }'

# interval: periodic output
bpftrace -e 'interval:s:5 { print(@hits); }'
```

> 🔍 **Reverse Engineering Insight:** bpftrace follows the awk pattern: `probe /filter/ { action }`. The filter is critical for performance — without it, every event triggers your action. In production, always add filters to reduce overhead.

⚠️ **Warning:** Poorly written bpftrace programs can consume significant CPU. Start minimal, add complexity gradually, and monitor with `top`.

---

## 4. strace Deep Dive — The Syscall Detective

### Filtering and Focus

```bash
# Trace only specific syscalls
strace -e trace=open,openat,read,write,close nginx

# Trace only network calls
strace -e trace=network curl https://example.com

# Trace only errors
strace -ef trace=open,openat command

# Exclude noisy syscalls
strace -e trace=!futex,!mmap,!mprotect,!brk command

# Show file descriptor paths
strace -y command
# openat(AT_FDCWD, "/etc/hosts", O_RDONLY) = 3</etc/hosts>
```

### Following Children and Timing

```bash
# Follow child processes (essential for forking daemons)
strace -f -T nginx
# [pid 1234] futex(..., FUTEX_WAIT_PRIVATE, ...) = 0 <0.000234>
# [pid 1235] epoll_wait(3, ...)                = 1 <0.001234>

# Summary with timing per syscall
strace -c -f command
# % time     seconds  usecs/call     calls    errors syscall
# ------ ----------- ----------- --------- --------- --------
#  45.00    0.002340         234        10           read
#  30.00    0.001560         156        10           write

# Absolute timestamps
strace -tt command
# 14:23:01.123456 execve("/bin/ls", ["ls"], ...) = 0

# Microsecond timing per syscall
strace -T command
# read(3, "\177ELF...", 832) = 832 <0.000045>
```

### Practical strace Recipes

```bash
# Find the slow syscall
strace -T command 2>&1 | sort -t'<' -k2 -rn | head -10

# What files does a program look for?
strace -e trace=file -f command 2>&1 | grep "no such file"

# What network connections does it make?
strace -e trace=connect,sendto,recvfrom -f command

# Find permission denied issues
strace -ef trace=file,connect command 2>&1 | grep EACCES

# Count total I/O bytes
strace -e trace=read,write -c command 2>&1

# Redirect to files (essential for long traces)
strace -o trace.log -ff -f command   # Creates trace.log.<pid> files
```

> 🔍 **Reverse Engineering Insight:** strace uses ptrace, causing 10-100x overhead — **3 context switches per syscall**. Use it for debugging, never in production for extended periods. For production, use bpftrace or perf.

⚠️ **Warning:** `strace -p <pid>` on a production process causes noticeable latency spikes. Use with time limits.

---

## 5. perf — The Profiling Powerhouse

### Installation and CPU Profiling

```bash
sudo apt install linux-tools-common linux-tools-$(uname -r)

# Profile system for 10 seconds at 99 Hz
sudo perf record -a -g --call-graph dwarf -F 99 -- sleep 10

# Analyze
sudo perf report                    # Interactive
sudo perf report --stdio | head -30  # Text output

# Profile specific process
sudo perf record -p <PID> -g -F 99 -- sleep 10
```

### Hardware Counters with perf stat

```bash
# Basic counters
perf stat ls
# 1.23 msec task-clock
# 3,456,789      cycles
# 5,678,901      instructions      #    1.64  insn per cycle
# 45,678      branch-misses     #    3.70% of all branches

# Cache and branch analysis
perf stat -e cycles,instructions,cache-references,cache-misses,branch-instructions,branch-misses -r 5 command

# Live profiling
sudo perf top -g
sudo perf top -p $(pgrep nginx)
```

### Generating Flame Graphs

```bash
# Install FlameGraph tools
git clone https://github.com/brendangregg/FlameGraph /tmp/FlameGraph
export PATH=$PATH:/tmp/FlameGraph

# Record and generate flame graph
sudo perf record -a -g -F 99 -- sleep 10 && \
  perf script | stackcollapse-perf.pl | flamegraph.pl > /tmp/flamegraph.svg

xdg-open /tmp/flamegraph.svg
```

> 🔍 **Reverse Engineering Insight:** perf stat tells you IF you have a performance problem (high cache misses, poor branch prediction). perf record + flame graphs tell you WHERE the problem is. Always stat first, then record.

⚠️ **Warning:** `perf record -F 99` adds ~1-3% CPU. For production, use `-F 49` or lower. High frequency (`-F 999`) causes 5-10% overhead.

---

## 6. Network Tracing — Packets, Connections, and Latency

```bash
# Trace TCP retransmits (the #1 network performance killer)
sudo tcpretrans-bpfcc

# Outgoing TCP connections
sudo tcpconnect-bpfcc

# TCP accept events (server-side)
sudo tcpaccept-bpfcc

# TCP connection lifetime with byte counts
sudo tcplife-bpfcc

# DNS resolution latency
sudo gethostlatency-bpfcc
```

### Network Simulation with tc

```bash
# Add latency
sudo tc qdisc add dev eth0 root netem delay 100ms

# Add packet loss
sudo tc qdisc add dev eth0 root netem loss 5%

# Combine delay + loss + corruption
sudo tc qdisc add dev eth0 root netem delay 50ms 10ms loss 2% corruption 1%

# View and remove rules
tc -s qdisc show dev eth0
sudo tc qdisc del dev eth0 root
```

### XDP Basics — Line-Rate Packet Processing

```
NIC Driver → XDP Program (runs BEFORE kernel sk_buff)
    Actions: PASS (to kernel) | DROP | TX (send back) | REDIRECT
    10-100x faster than iptables for filtering/DDoS mitigation
```

```bash
# Attach XDP program
sudo ip link set dev lo xdp obj xdp_drop.o sec xdp

# View XDP programs
sudo bpftool net list

# Remove XDP program
sudo ip link set dev lo xdp off
```

---

## 7. Filesystem Tracing — Know Every I/O Operation

```bash
# Trace ext4 operations slower than 10ms
sudo ext4slower-bpfcc 10
# COMM       PID    T  BYTES   LAT(ms) FILENAME
# mysqld     1234   R  4096    23.45   users.ibd

# Trace XFS operations slower than 5ms
sudo xfsslower-bpfcc 5

# Which files are being read/written
sudo filetop-bpfcc
# TIME     COMM      T FILE        BYTES   READS  WRITES
# 10:23:01 mysqld    R users.ibd   1048576  256    0

# VFS operation counts
sudo vfsstat-bpfcc
# READ    WRITE   FSYNC   OPEN    CLOSE
# 12345   6789    234     567     567

# Trace fsync with latency
bpftrace -e '
kprobe:vfs_fsync_range { @start[tid] = nsecs; }
kretprobe:vfs_fsync_range /@start[tid]/ {
    $ms = (nsecs - @start[tid]) / 1000000;
    if ($ms > 10) printf("%s pid=%d latency=%d ms\n", comm, pid, $ms);
    delete(@start[tid]);
}'
```

> 🔍 **Reverse Engineering Insight:** When a database is "slow," the answer is almost always in the I/O path. ext4slower/xfsslower instantly show WHICH files are slow and by HOW MUCH — something `iostat` and `iotop` cannot tell you.

---

## 8. Real-World Debugging Scenarios

### Scenario 1: "The Server Is Slow" — Systematic Approach

```bash
# 1. Is it CPU, memory, I/O, or network?
uptime && vmstat 1 5 && iostat -xz 1 5

# 2. If CPU-bound → who's consuming?
sudo perf record -a -g -F 99 -- sleep 10 && sudo perf report --stdio | head -20

# 3. If I/O-bound → what's slow?
sudo biolatency-bpfcc -D && sudo ext4slower-bpfcc 10 && sudo filetop-bpfcc

# 4. If network-bound → what's happening?
sudo tcpretrans-bpfcc && sudo tcplife-bpfcc

# 5. If memory-bound → what's using it?
sudo cachestat-bpfcc 1 && sudo oomkill-bpfcc
```

### Scenario 2: Slow Disk I/O

```bash
sudo biolatency-bpfcc -D          # Overall I/O latency
sudo ext4slower-bpfcc 5           # Which files are slow
sudo biosnoop-bpfcc               # Per-I/O events
sudo cachestat-bpfcc 1            # Page cache effectiveness
# Low cache hit rate → need more RAM
# One slow file → fragmented or bad block
# High disk util → disk at capacity
```

### Scenario 3: Memory Leak Detection

```bash
sudo memleak-bpfcc -p $(pgrep myapp) -a
sudo perf record -e page-faults -a -g -F 99 -- sleep 30
sudo perf report
```

### Scenario 4: CPU Spike Investigation

```bash
top -b -d 1 | head -30                    # Who during spike
sudo perf record -a -g -F 99 -- sleep 30  # Profile it
sudo runqlat-bpfcc                         # Scheduling latency
```

### Scenario 5: Network Connection Issues

```bash
sudo tcpretrans-bpfcc              # Retransmits
sudo tcplife-bpfcc                 # Connection patterns
ss -ant | awk '{print $1}' | sort | uniq -c | sort -rn  # State counts

# Deep dive: DNS resolution issues
sudo gethostlatency-bpfcc

# Connection leak (too many TIME_WAIT)
ss -ant | awk '{print $1}' | sort | uniq -c | sort -rn
# If TIME_WAIT count is very high, check:
# - net.ipv4.tcp_tw_reuse
# - Connection pool sizing
# - Keep-alive configuration
```

### Scenario 6: Debugging a Hanging Process

```bash
# Process seems stuck — what's it doing?
PID=$(pgrep stuck_process)

# Option 1: perf top on the process
sudo perf top -p $PID

# Option 2: bpftrace — what syscall is it blocked in?
bpftrace -e '
tracepoint:raw_syscalls:sys_enter /pid == '$PID'/ {
    printf("%s syscall=%d args=%d %d %d\n", comm, args->id, args->args[0], args->args[1], args->args[2]);
}'

# Option 3: strace (use with caution on production)
sudo timeout 5 strace -p $PID -T

# Option 4: Check stack trace
cat /proc/$PID/stack

# Option 5: perf record for 3 seconds
sudo perf record -p $PID -g --call-graph dwarf -- sleep 3
sudo perf report --stdio | head -20
```

### Scenario 7: Container Performance Debugging

```bash
# Find the container's PID
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' my_container)

# Profile the container
sudo perf record -p $CONTAINER_PID -g -F 99 -- sleep 10
sudo perf report

# Trace syscalls inside container
sudo strace -p $CONTAINER_PID -c -T

# bcc-tools work on containerized processes too
sudo execsnoop-bpfcc    # Shows container processes by name
sudo opensnoop-bpfcc    # Shows file access inside containers
sudo biolatency-bpfcc   # Shows container I/O latency
```

---

## 9. When to Use Which Tool — Decision Matrix

### Tool Comparison

```
┌────────────┬──────────┬────────────┬─────────────┬────────────────┐
│ Tool       │ Overhead │ Production │ Flexibility │ Learning Curve │
├────────────┼──────────┼────────────┼─────────────┼────────────────┤
│ bcc-tools  │ Very Low │ Safe       │ Low (fixed) │ Easy           │
│ bpftrace   │ Very Low │ Safe*      │ Very High   │ Medium         │
│ perf       │ Low      │ Safe       │ High        │ Medium         │
│ strace     │ HIGH     │ Unsafe**   │ Medium      │ Easy           │
│ XDP/bpf    │ Very Low │ Safe       │ Very High   │ Hard           │
└────────────┴──────────┴────────────┴─────────────┴────────────────┘
```

### Scenario → Tool Mapping

```
┌───────────────────────────────────┬─────────────────────────────┐
│ Scenario                          │ Best Tool                   │
├───────────────────────────────────┼─────────────────────────────┤
│ "What process just started?"      │ execsnoop (bcc)             │
│ "Who is opening /etc/shadow?"     │ opensnoop (bcc)             │
│ "Why is disk I/O slow?"           │ biolatency + ext4slower     │
│ "Why is CPU pegged at 100%?"      │ perf record + flame graph   │
│ "Where are cache misses?"         │ perf stat + perf record     │
│ "Are there TCP retransmits?"      │ tcpretrans (bcc)            │
│ "What syscall is slow?"           │ strace -T                    │
│ "What kernel function is slow?"   │ bpftrace + kprobe           │
│ "Trace my custom event"           │ bpftrace                    │
│ "Profile for flame graph"         │ perf record + FlameGraph    │
│ "How effective is page cache?"    │ cachestat (bcc)             │
│ "Why did OOM kill happen?"        │ oomkill (bcc)               │
│ "What is this process doing now?" │ perf top -p <PID>           │
└───────────────────────────────────┴─────────────────────────────┘
```

### The Tracing Hierarchy (Least → Most Invasive)

```
1. Standard tools: top, iostat, vmstat, ss     ← start here
2. bcc-tools: execsnoop, opensnoop, biolatency ← production-safe
3. perf: record, stat, top, flame graphs       ← CPU profiling
4. bpftrace: custom probes, scripts            ← when bcc-tools don't answer
5. strace: syscall tracing                     ← last resort, high overhead
6. ftrace/debugfs: raw kernel tracing          ← when all else fails
```

> 🔍 **Reverse Engineering Insight:** Golden rule: start with the least invasive tool. Don't use strace when top would do. Don't write a bpftrace script when a bcc-tool already exists. Each layer adds overhead — move down only when the previous layer fails.

---

## 🛠️ Hands-On Practices

### Practice 1: Install and Verify Tracing Tools

```bash
# Install all tracing tools
sudo apt install bpfcc-tools bpftrace linux-tools-common linux-tools-$(uname -r)

# Verify installations
bpftrace --version
perf --version

# Check kernel eBPF support — all should show =y or =m
grep -E "CONFIG_BPF|CONFIG_BPF_SYSCALL|CONFIG_BPF_JIT|CONFIG_BPF_EVENTS" \
    /boot/config-$(uname -r)

# Count available bcc-tools
ls /usr/sbin/*-bpfcc | wc -l

# List current eBPF programs loaded on the system
sudo bpftool prog list | head -10
```

✅ **Expected**: All tools installed, kernel supports eBPF, bpftool shows existing programs

### Practice 2: execsnoop — Catch Every New Process

```bash
# Terminal 1: Start tracing
sudo execsnoop-bpfcc

# Terminal 2: Generate activity
sleep 1 &
ls /tmp &
python3 -c "print('hello')" &
for i in {1..5}; do sleep 0.1 & done

# Wait, then Ctrl+C in Terminal 1
```

✅ **Expected**: See all spawned processes with PID, PPID, and full command line

### Practice 3: opensnoop — Track File Access

```bash
# Start tracing file opens
sudo opensnoop-bpfcc

# In another terminal
cat /etc/hostname
python3 -c "open('/etc/hosts').read()"

# Filter by process name
sudo opensnoop-bpfcc -n python3

# Filter by path (find who reads a specific file)
sudo opensnoop-bpfcc -f /etc/shadow
```

✅ **Expected**: Every file open syscall with process name, PID, path, and error codes

### Practice 4: biolatency — Disk I/O Latency Profile

```bash
# Generate I/O
fio --name=test --directory=/tmp --rw=randread --bs=4k --size=100M --runtime=10 &
# Measure
sudo biolatency-bpfcc -D 10
```

✅ **Expected**: Latency histogram showing I/O distribution across devices

### Practice 5: bpftrace One-Liners

```bash
# Count syscalls per process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s opens %s\n", comm, str(args->filename)); }'

# Measure function latency
bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; } kretprobe:vfs_read /@start[tid]/ { @us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'
```

✅ **Expected**: Kernel visibility output showing syscall counts and file access patterns

### Practice 6: perf stat — Hardware Counter Analysis

```bash
perf stat sort -n /usr/share/dict/words > /dev/null
perf stat grep -c "the" /usr/share/dict/words
perf stat dd if=/dev/zero of=/dev/null bs=4k count=10000
```

✅ **Expected**: Hardware counter differences between CPU-bound, I/O-bound, and memory-bound workloads

### Practice 7: perf record + Flame Graph

```bash
git clone https://github.com/brendangregg/FlameGraph /tmp/FlameGraph
export PATH=$PATH:/tmp/FlameGraph
sudo perf record -a -g -F 99 -- sleep 10
sudo perf script | stackcollapse-perf.pl | flamegraph.pl > /tmp/flamegraph.svg
```

✅ **Expected**: Flame graph SVG showing CPU time distribution across call stacks

### Practice 8: strace Deep Dive

```bash
# Find what a process accesses
strace -e trace=file -f curl http://localhost 2>&1 | head -20

# Syscall summary
sudo timeout 10 strace -c -f -p $(pgrep nginx) 2>&1

# Find permission issues
strace -e trace=file command 2>&1 | grep EACCES
```

✅ **Expected**: Syscall tracing with timing, file access, and error details

### Practice 9: Network Tracing

```bash
sudo tcpretrans-bpfcc &
for i in {1..50}; do curl -s http://localhost > /dev/null 2>&1 &; done
wait; kill %1

sudo tcplife-bpfcc &
for i in {1..10}; do curl -s http://example.com > /dev/null 2>&1 &; done
wait; kill %1
```

✅ **Expected**: TCP retransmit events and connection lifetimes with byte counts

### Practice 10: Filesystem Tracing

```bash
sudo ext4slower-bpfcc 5 &
dd if=/dev/zero of=/tmp/slowfile bs=1M count=100 oflag=direct
cat /tmp/slowfile > /dev/null
sudo vfsstat-bpfcc &
ls /var/log/ && cat /etc/hosts
kill %1 %2 2>/dev/null
```

✅ **Expected**: Slow I/O events with filenames, latencies, and VFS operation counts

### Practice 11: bpftrace Script — Zombie Detector

```bash
cat > /tmp/zombies.bt << 'EOF'
#!/usr/bin/env bpftrace
tracepoint:sched:sched_process_exit /args->exit_state == 32/ {
    printf("ZOMBIE: PID=%d COMM=%s\n", pid, comm);
}
interval:s:5 { printf("--- check ---\n"); }
EOF
sudo bpftrace /tmp/zombies.bt
```

✅ **Expected**: Script detects zombie process creation events

### Practice 12: perf top — Live Function Profiling

```bash
sudo perf top -g &
# Let it run while you do work in other terminals
kill %1
```

✅ **Expected**: Live view of kernel and userspace functions consuming CPU

### Practice 13: Cache Miss Investigation

```bash
perf stat -e cache-references,cache-misses -r 3 python3 -c "
data = list(range(1000000))
sum(data[i] for i in range(0, len(data), 64))
"
```

✅ **Expected**: Sequential access shows low cache miss rate vs random access

### Practice 14: End-to-End Production Debugging

```bash
cat > /tmp/slow_app.py << 'PYEOF'
import os, time, random
while True:
    with open("/tmp/app_log.txt", "a") as f:
        f.write(f"entry {time.time()}\n")
    if random.random() < 0.1:
        os.system("dd if=/dev/zero of=/tmp/app_data bs=4K count=10 oflag=direct 2>/dev/null")
    time.sleep(0.01)
PYEOF
python3 /tmp/slow_app.py &
APP_PID=$!

sudo execsnoop-bpfcc &
sudo opensnoop-bpfcc -p $APP_PID &
perf stat -p $APP_PID -- sleep 3
sudo biolatency-bpfcc -D 3

kill $APP_PID 2>/dev/null
pkill -f "execsnoop\|opensnoop\|biolatency" 2>/dev/null
rm -f /tmp/app_log.txt /tmp/app_data /tmp/slow_app.py
```

✅ **Expected**: Complete investigation using multiple tools to understand the slow application

### Practice 15: Custom bpftrace Dashboard

```bash
cat > /tmp/dashboard.bt << 'EOF'
#!/usr/bin/env bpftrace
BEGIN { printf("=== System Tracing Dashboard ===\n"); }
tracepoint:raw_syscalls:sys_enter { @syscalls[comm] = count(); }
tracepoint:block:block_rq_complete { @disk[comm] = count(); }
tracepoint:sched:sched_process_exec {
    printf("[%s] New: %s (PID %d)\n", strftime("%H:%M:%S", nsecs), args->filename, pid);
}
interval:s:5 {
    printf("\n--- Syscalls ---\n"); print(@syscalls, 10);
    printf("\n--- Disk Ops ---\n"); print(@disk, 5);
    clear(@syscalls); clear(@disk);
}
EOF
sudo bpftrace /tmp/dashboard.bt
```

✅ **Expected**: Multi-probe dashboard showing syscalls, disk ops, and new processes

---

## Deep Understanding

### ptrace vs eBPF Performance

```
strace (ptrace):
  Process → Kernel (ptrace) → strace (read)
  = 3 context switches per syscall = 10-100x overhead

eBPF (bpftrace/bcc):
  Process → Kernel (eBPF runs in-line) → result in map
  = 0 context switches = <1% overhead
```

### When bpftrace Beats strace (and Vice Versa)

```
Use bpftrace when:
  - Tracing kernel functions (kprobes)
  - High-frequency events (>1000/sec)
  - Aggregation needed (histograms, counts)
  - Multiple processes simultaneously
  - Cannot attach to process (permissions)

Use strace when:
  - Need full syscall arguments and data buffers
  - Tracing a single short-lived process
  - Understanding a program's system interaction
  - Debugging a script (low frequency, low overhead acceptable)
```

### Probe Stability

```
┌────────────┬──────────────────┬────────────┬─────────────────┐
│ Probe Type │ Where Defined    │ Stability  │ Overhead        │
├────────────┼──────────────────┼────────────┼─────────────────┤
│ tracepoint │ Kernel (static)  │ STABLE ABI │ Very Low        │
│ kprobe     │ Any kernel fn    │ UNSTABLE   │ Very Low        │
│ uprobe     │ Userspace binary │ MODERATE   │ Low (breakpoint)│
│ profile    │ Timer interrupt  │ STABLE     │ Fixed (1-999Hz) │
│ software   │ Kernel counters  │ STABLE     │ Very Low        │
│ hardware   │ CPU PMU          │ HW-dependent│ Very Low       │
└────────────┴──────────────────┴────────────┴─────────────────┘

Production rule: ALWAYS prefer tracepoints when available.
Only use kprobes/uprobes when no tracepoint covers your need.
```

### Common Pitfalls and How to Avoid Them

```
Pitfall 1: Unfiltered bpftrace in production
  BAD:  bpftrace -e 'kprobe:* { @[kstack] = count(); }'
  GOOD: bpftrace -e 'kprobe:tcp_sendmsg /comm == "nginx"/ { @[kstack] = count(); }'

Pitfall 2: Using strace on long-running processes
  BAD:  strace -p $(pgrep postgres)  # hours
  GOOD: sudo timeout 10 strace -c -p $(pgrep postgres)

Pitfall 3: Forgetting -f with strace on forking processes
  BAD:  strace command  # misses child processes
  GOOD: strace -f command  # follows all children

Pitfall 4: Profiling too briefly
  BAD:  perf record -F 99 -- sleep 1  # too short
  GOOD: perf record -F 99 -- sleep 30  # capture full behavior

Pitfall 5: Ignoring perf report overhead percentages
  Always check "Overhead" column — the top 3-5 functions
  tell you 80% of the performance story.
```

> 🔍 **Reverse Engineering Insight:** Use tracepoints for production (stable, fast). Use kprobes for kernel functions without tracepoints. Use uprobes for userspace. Use profile for CPU sampling. Tracepoints are your safe default.

---

## Command Reference

| Task | Command |
|------|---------|
| List eBPF programs | `sudo bpftool prog list` |
| List eBPF maps | `sudo bpftool map list` |
| Trace new processes | `sudo execsnoop-bpfcc` |
| Trace file opens | `sudo opensnoop-bpfcc` |
| Disk I/O latency | `sudo biolatency-bpfcc -D` |
| Page cache stats | `sudo cachestat-bpfcc 1` |
| TCP connections | `sudo tcplife-bpfcc` |
| TCP retransmits | `sudo tcpretrans-bpfcc` |
| Slow ext4 ops | `sudo ext4slower-bpfcc 10` |
| Top files by I/O | `sudo filetop-bpfcc` |
| VFS operations | `sudo vfsstat-bpfcc` |
| CPU profiling | `sudo perf record -a -g -F 99 -- sleep 10` |
| Perf report | `sudo perf report --stdio` |
| Hardware counters | `perf stat -e cycles,instructions,cache-misses command` |
| CPU live profile | `sudo perf top -g` |
| Flame graph | `perf script \| stackcollapse-perf.pl \| flamegraph.pl > out.svg` |
| Syscall filter | `strace -e trace=file,net -T command` |
| Syscall summary | `strace -c command` |
| Follow children | `strace -f -T -p <PID>` |
| bpftrace one-liner | `bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'` |
| Kernel fn trace | `bpftrace -e 'kprobe:tcp_connect { printf("%s\n", comm); }'` |
| Userspace trace | `bpftrace -e 'uprobe:/bin/ls:main { printf("main()\n"); }'` |
| Network sim | `sudo tc qdisc add dev eth0 root netem delay 100ms` |
| Remove tc rules | `sudo tc qdisc del dev eth0 root` |
| XDP attach | `sudo ip link set dev eth0 xdp obj prog.o sec xdp` |
| XDP remove | `sudo ip link set dev eth0 xdp off` |
| Check eBPF support | `cat /boot/config-$(uname -r) \| grep BPF` |
| Install bcc-tools | `sudo apt install bpfcc-tools` |
| Install bpftrace | `sudo apt install bpftrace` |
| Install perf | `sudo apt install linux-tools-$(uname -r)` |

---

## What's Coming in Part 64

```
┌─────────────────────────────────────────────────────────┐
│   Part 64: Linux Namespaces — Containers Without Docker │
├─────────────────────────────────────────────────────────┤
│   • What namespaces are and why they exist               │
│   • PID, network, mount, UTS, IPC, user namespaces      │
│   • Creating namespaces with unshare                     │
│   • nsenter for attaching to existing namespaces         │
│   • Container runtimes: containerd, CRI-O                │
│   • Building a mini-container from scratch               │
│   • Rootless containers and user namespace mapping       │
│   • Security implications of namespace escape            │
│   • Real-world: debugging inside containers              │
│   • Podman vs Docker namespace architecture              │
└─────────────────────────────────────────────────────────┘
```

---

## Self-Test

1. What is eBPF and what problem does it solve?
2. What does the eBPF verifier check before allowing a program to load?
3. What is the difference between a kprobe and a tracepoint?
4. Why is strace considered high-overhead for production use?
5. What bcc-tool would you use to find slow disk I/O operations?
6. What does `perf stat -e cache-misses` tell you?
7. How do you generate a flame graph with perf?
8. What is the key advantage of XDP over iptables for packet filtering?
9. What bpftrace one-liner counts syscalls per process?
10. When would you use `uprobe` instead of `kprobe`?
11. What does `cachestat` show and why is it important?
12. How do you trace TCP retransmissions on a production server?
13. What does `biolatency -D` show that `iostat` does not?
14. How do you profile a specific process with perf record?
15. What is the recommended tracing tool hierarchy (least to most invasive)?

**Answers:**
1. eBPF = extended Berkeley Packet Filter; programmable sandboxed code running inside the kernel for safe, high-performance tracing and observability
2. No infinite loops, no out-of-bounds memory access, no null dereferences, bounded execution, valid helper calls, max 1M instructions
3. Tracepoint = static, stable kernel hook points defined in source code; kprobe = dynamic probes on any kernel function name (may change between versions)
4. strace uses ptrace which causes 3 context switches per syscall, adding 10-100x overhead on the traced process
5. `ext4slower-bpfcc` (or `xfsslower-bpfcc` for XFS) — shows filesystem operations slower than a threshold
6. Hardware cache miss count — high numbers indicate poor memory access patterns causing CPU stalls
7. `perf record -a -g -F 99 -- sleep N` then `perf script | stackcollapse-perf.pl | flamegraph.pl > out.svg`
8. XDP runs before kernel allocates sk_buff, processing packets at line rate; iptables processes after full stack allocation
9. `bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'`
10. uprobe traces userspace functions in binaries/libraries; kprobe traces kernel functions only
11. Page cache hit/miss ratio — low hit rate means working set exceeds RAM, causing excessive disk I/O
12. `sudo tcpretrans-bpfcc` — shows retransmit events with connection details and state
13. biolatency shows actual I/O latency distribution (histogram); iostat shows throughput and utilization averages
14. `sudo perf record -p <PID> -g --call-graph dwarf -- sleep 10` then `sudo perf report`
15. Standard tools → bcc-tools → perf → bpftrace → strace → ftrace → kernel modules

**Score:** 12/15 correct = ready for Part 64.

---

*Linux SysAdmin Course | Part 63 of ∞ | Reverse Engineering Approach*
*Previous → Part 62: Memory Management*
*Next → Part 64: Linux Namespaces*

[← Previous](part62.md) | [Next →](part64.md)