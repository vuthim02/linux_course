## 🔍 Section 8: Perf — Linux Profiler

`perf` uses hardware Performance Monitoring Counters (PMCs) and kernel tracepoints to profile the system with minimal overhead.

### perf stat — Count Events

Counts specific events during a command's execution:

```bash
# Basic CPU cycle count
perf stat ls

# Count specific events
perf stat -e cycles,instructions,cache-misses,branch-misses ./myapp

# Count all available events on a running process
sudo perf stat -p 1234 -e cycles,instructions,cache-misses sleep 10

# System-wide counting for 5 seconds
sudo perf stat -a -e cycles,instructions,cache-misses sleep 5

# Get IPC (Instructions Per Cycle) — lower IPC = less efficient code
# perf stat automatically shows IPC
```

Output example:
```
 Performance counter stats for 'ls':

          1,234,567      cycles                    #    3.45 GHz
          2,345,678      instructions              #    1.90  insn per cycle
             12,345      cache-misses              #    5.2% of all cache refs
              5,678      branch-misses             #    2.1% of all branches

       0.001234567 seconds time elapsed
```

### perf record/report — CPU Profiling

Samples the running program at a fixed frequency and records what it's executing:

```bash
# Profile a command
perf record ./myapp

# Profile an already running process for 10 seconds
sudo perf record -p 1234 -a --sleep 10

# Record with call-graph (dwarf for user-space, fp for kernel)
perf record -g ./myapp
perf record --call-graph dwarf ./myapp

# View the profile
perf report

# Interactive TUI: sort by overhead, zoom into functions
# Press 'h' for help, 'Enter' to zoom into a function
```

### perf top — Live Profiling

Shows live CPU usage, sampled in-kernel:

```bash
# Live view of hottest functions
sudo perf top

# Annotate specific calls
sudo perf top -e cache-misses

# Show user-space symbols too
sudo perf top -a -g
```

### perf list — Available Events

```bash
# List all events
perf list

# List hardware events
perf list hw

# List software events
perf list sw

# List tracepoints
perf list tracepoint

# List PMU events (Intel)
perf list pmu
```

### Flame Graphs

Flame graphs visualize CPU profiles — each rectangle is a function call, width = time spent:

```bash
# Step 1: Record with stack traces
sudo perf record -F 99 -ag -- sleep 60

# Step 2: Generate folded stack output
sudo perf script > /tmp/perf.script

# Step 3: Generate SVG flamegraph
# Requires FlameGraph tools
git clone https://github.com/brendangregg/FlameGraph
cd FlameGraph
./stackcollapse-perf.pl /tmp/perf.script > /tmp/perf.folded
./flamegraph.pl /tmp/perf.folded > /tmp/perf.svg
# Open perf.svg in browser
```

---



---

[← Previous](09-section-7-tuned-automated-performance.md) | [↑ Index](index.md) | [Next →](11-section-9-strace-and-ltrace.md)
