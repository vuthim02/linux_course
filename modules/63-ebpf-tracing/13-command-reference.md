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





[← Previous](12-deep-understanding.md) | [↑ Index](index.md) | [Next →](14-whats-coming-in-part-64.md)
