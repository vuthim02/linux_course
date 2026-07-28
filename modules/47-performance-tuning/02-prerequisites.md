## 📋 Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 22.04+ / Debian 12+ / RHEL 9+ |
| Access | Root or `sudo` on a physical or virtual machine |
| Packages | `linux-tools-common`, `linux-tools-$(uname -r)`, `perf`, `bpftrace`, `strace`, `stress-ng`, `fio`, `iperf3`, `sysbench`, `numactl` |
| Kernel | 5.x+ recommended (for bpftrace, BTF support) |
| Time | 4–5 hours of hands-on lab work |

### Quick Package Install

```bash
# Debian/Ubuntu
sudo apt install linux-tools-common linux-tools-$(uname -r) bpftrace strace stress-ng fio iperf3 sysbench numactl

# RHEL/Fedora
sudo dnf install perf bpftrace strace stress-ng fio iperf3 sysbench numactl
```


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-performance-tuning-methodology.md)
