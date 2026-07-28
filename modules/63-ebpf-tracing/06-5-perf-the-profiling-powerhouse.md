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





[← Previous](05-4-strace-deep-dive-the.md) | [↑ Index](index.md) | [Next →](07-6-network-tracing-packets-connections.md)
