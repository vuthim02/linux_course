## 🛠️ Hands-On Practices

### Practice 1: CPU Governor Tuning

**Goal:** Observe the impact of CPU frequency scaling on benchmark performance.

```bash
# 1. Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 2. Run a sysbench CPU benchmark with current governor
sysbench cpu run

# 3. Switch to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 4. Re-run benchmark
sysbench cpu run

# 5. Switch to powersave
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 6. Run benchmark again
sysbench cpu run

# 7. Record the events/sec for each governor
```

**Observation:** performance governor should show higher throughput (at the cost of power and heat).

---

### Practice 2: taskset CPU Affinity

**Goal:** Bind a CPU-intensive process to specific cores and measure the difference.

```bash
# 1. Launch a CPU-intensive task on all cores
stress-ng --cpu 4 --timeout 30 &

# 2. Check where it's running
ps -eo pid,comm,psr | grep stress-ng

# 3. Launch another stress-ng with affinity to a single core
taskset -c 3 stress-ng --cpu 1 --timeout 30 &

# 4. Observe that it stays on CPU 3
ps -eo pid,comm,psr | grep stress-ng

# 5. Benchmark: time a task with and without affinity
time taskset -c 0 sysbench cpu run
time sysbench cpu run   # compare
```

---

### Practice 3: Tune Swappiness

**Goal:** Observe how swappiness changes memory pressure behavior.

```bash
# 1. Check current swappiness
sysctl vm.swappiness

# 2. Allocate memory and observe swap
stress-ng --vm 2 --vm-bytes 90% --timeout 120 &

# 3. In another terminal watch swap activity
vmstat 1

# 4. Now set swappiness to 100 (aggressive swap)
sudo sysctl vm.swappiness=100

# 5. Run the stress again and watch swap usage increase
# 6. Reset to 10 (avoid swapping)
sudo sysctl vm.swappiness=10

# 7. Repeat — compare swap in/out columns from vmstat
```

---

### Practice 4: Benchmarking with sysbench

**Goal:** Run a complete suite of sysbench benchmarks and document results.

```bash
# CPU test
sysbench cpu --cpu-max-prime=20000 run

# Memory test
sysbench memory --memory-block-size=1M --memory-total-size=10G run

# Thread test
sysbench threads --thread-yields=1000 --thread-locks=8 run

# Mutex test
sysbench mutex --mutex-num=1024 --mutex-locks=50000 run

# File I/O test
sysbench fileio --file-total-size=2G prepare
sysbench fileio --file-test-mode=rndrw --file-total-size=2G run
sysbench fileio --file-total-size=2G cleanup
```

**Deliverable:** A table with benchmark name, throughput, and latency values.

---

### Practice 5: Tune I/O Scheduler

**Goal:** Compare I/O performance under different I/O schedulers.

```bash
# 1. Check available schedulers
cat /sys/block/sda/queue/scheduler

# 2. Run fio with current scheduler
fio --name=bench --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --numjobs=4 --runtime=30 --group_reporting --output=result_$(cat /sys/block/sda/queue/scheduler | awk '{print $1}').json

# 3. Switch to each scheduler and rerun
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
echo kyber | sudo tee /sys/block/sda/queue/scheduler
echo bfq | sudo tee /sys/block/sda/queue/scheduler
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# 4. Compare IOPS and latency from JSON output
grep -A5 '"iops"' result_*.json
```

---

### Practice 6: Analyze with perf record/report

**Goal:** Profile a CPU-bound workload and identify the hottest code path.

```bash
# 1. Create a CPU-bound script
cat > /tmp/cpuburn.py << 'EOF'
import math
for i in range(10000000):
    math.sqrt(i) * math.sin(i) * math.cos(i)
EOF

# 2. Record with perf
perf record python3 /tmp/cpuburn.py

# 3. View report
perf report

# 4. Record with call-graph
perf record -g python3 /tmp/cpuburn.py
perf report -g

# 5. Annotate the hottest function
# In perf report, select a function and press 'a' for annotation
```

---

### Practice 7: strace a Slow Command

**Goal:** Find which system call is responsible for a slow operation.

```bash
# 1. Find a slow operation (e.g., find)
time find /usr -name "*.txt"

# 2. strace with timing
strace -T -o /tmp/find.strace find /usr -name "*.txt"

# 3. Sort by longest syscall
awk -F'[<>]' '{if ($2 != "") print $2, $0}' /tmp/find.strace | sort -rn | head -10

# 4. Show summary
strace -c find /usr -name "*.txt"

# 5. Identify the bottleneck
# Look for syscalls with high total time or high count
```

---

### Practice 8: bpftrace One-Liner for Block I/O Latency

**Goal:** Generate a latency histogram of block I/O operations.

```bash
# 1. Run the bpftrace one-liner for block I/O latency
sudo bpftrace -e 'kprobe:blk_account_io_start { @start[tid] = nsecs; }
    kprobe:blk_account_io_done /@start[tid]/ {
        @usecs = hist((nsecs - @start[tid]) / 1000);
        delete(@start[tid]);
    }'

# 2. In another terminal, generate I/O
dd if=/dev/zero of=/tmp/test bs=1M count=1000 oflag=direct

# 3. Observe the histogram output in the bpftrace terminal

# 4. Try with different I/O patterns:
fio --name=realtest --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --runtime=30
```

---

### Practice 9: fio Benchmark

**Goal:** Create a comprehensive disk benchmark report.

```bash
# Sequential read
fio --name=seqread --ioengine=libaio --direct=1 --rw=read --bs=1M --size=4G --numjobs=1 --runtime=30 --output-format=json --output=seqread.json
jq '.jobs[0].read' seqread.json

# Random read 4K
fio --name=randread --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=2G --numjobs=4 --runtime=30 --output-format=json --output=randread.json
jq '.jobs[0].read' randread.json

# Mixed 70/30
fio --name=mixed --ioengine=libaio --direct=1 --rw=randrw --rwmixread=70 --bs=8K --size=2G --numjobs=4 --runtime=30 --output-format=json --output=mixed.json
jq '.jobs[0].read, .jobs[0].write' mixed.json

# Latency percentiles (99th, 99.9th)
fio --name=latency --ioengine=libaio --direct=1 --rw=randread --bs=4K --size=1G --runtime=30 --lat_percentiles=1 --percentile_list=50:90:99:99.9:99.99 --output-format=json --output=latency.json
jq '.jobs[0].read.clat.percentile' latency.json
```

---

### Practice 10: iperf3 Network Test

**Goal:** Measure network throughput between two machines.

```bash
# On Server A (1.2.3.4):
iperf3 -s

# On Client B:
iperf3 -c 1.2.3.4 -t 30
iperf3 -c 1.2.3.4 -t 30 -P 4          # 4 parallel streams
iperf3 -c 1.2.3.4 -t 30 -R            # reverse mode
iperf3 -c 1.2.3.4 -t 30 -u -b 1000M   # UDP test

# Check for packet loss in UDP mode
# If retr (retransmits) > 0 in TCP mode, tune buffers:
sudo sysctl net.core.rmem_max=134217728
sudo sysctl net.core.wmem_max=134217728
sudo sysctl net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl net.ipv4.tcp_wmem="4096 65536 134217728"
```

---

### Practice 11: stress-ng Test

**Goal:** Stress the system and monitor thermal and performance throttling.

```bash
# 1. Check baseline temperature and frequency
watch -n 1 "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq; sensors"

# 2. Run mixed stress
stress-ng --cpu 4 --cpu-method all --vm 2 --vm-bytes 80% --hdd 1 --hdd-bytes 4G --timeout 120 --metrics-brief --perf

# 3. Monitor in another terminal
mpstat -P ALL 1
vmstat 1
sensors

# 4. Check the perf stats at the end
# stress-ng --perf shows cycles, instructions, cache misses

# 5. Test with different governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
stress-ng --cpu 4 --timeout 30 --metrics-brief
```

---

### Practice 12: NUMA Binding with numactl

**Goal:** Measure the performance difference between NUMA-local and cross-NUMA memory access.

```bash
# 1. Show NUMA topology
numactl --hardware

# 2. Allocate memory on local node and benchmark
numactl --cpunodebind=0 --membind=0 sysbench memory run

# 3. Allocate memory on remote node
numactl --cpunodebind=0 --membind=1 sysbench memory run

# 4. Interleave allocation
numactl --interleave=all sysbench memory run

# 5. Compare latency and throughput
# (Remote memory access is typically 1.5-2x slower)
```

---

### Practice 13: Tune Network Kernel Parameters

**Goal:** Measure network throughput before and after kernel tuning.

```bash
# 1. Baseline measurement with iperf3
iperf3 -c 192.168.1.100 -t 30 -P 4 > /tmp/baseline.txt

# 2. Apply network tuning
cat <<EOF | sudo tee /etc/sysctl.d/90-network-performance.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_budget = 600
net.core.somaxconn = 65536
net.ipv4.tcp_congestion_control = bbr
EOF
sudo sysctl --system

# 3. Re-run iperf3
iperf3 -c 192.168.1.100 -t 30 -P 4 > /tmp/tuned.txt

# 4. Compare throughput
grep "SUM" /tmp/baseline.txt /tmp/tuned.txt
```

---

### Practice 14: Capacity Planning Simulation

**Goal:** Project resource needs based on current growth.

```bash
# 1. Collect current stats
echo "=== Current Metrics ==="
echo "CPU load: $(uptime | awk '{print $NF}')"
echo "Memory: $(free -m | awk '/Mem:/ {print $3/$2 * 100}')% used"
echo "Disk: $(df -h / | awk 'NR==2 {print $5}')"

# 2. Simulate growth rates
cat <<'EOF' | python3
current_cpu = 55  # percent
current_mem = 62  # percent
current_disk = 45 # percent
monthly_growth = 0.05
months = 0
while current_cpu < 80 and current_mem < 80 and current_disk < 80:
    months += 1
    current_cpu *= (1 + monthly_growth)
    current_mem *= (1 + monthly_growth)
    current_disk *= (1 + monthly_growth)

print(f"At {monthly_growth*100}% monthly growth:")
print(f"  CPU threshold in: {months} months")
print(f"  Memory threshold: {current_mem:.1f}%")
print(f"  CPU threshold: {current_cpu:.1f}%")
print(f"  Disk threshold: {current_disk:.1f}%")
EOF

# 3. Write a capacity plan
echo "Action: Upgrade CPU by ${months} months"
```

---

### Practice 15: Full System Performance Audit

**Goal:** Produce a complete system performance audit document.

```bash
#!/bin/bash
# system_performance_audit.sh — Run this with sudo

AUDIT_DIR="/tmp/perf_audit_$(date +%Y%m%d)"
mkdir -p "$AUDIT_DIR"

echo "=== SYSTEM PERFORMANCE AUDIT ===" | tee "$AUDIT_DIR/audit.txt"
echo "Date: $(date)" | tee -a "$AUDIT_DIR/audit.txt"
echo "Hostname: $(hostname)" | tee -a "$AUDIT_DIR/audit.txt"
echo "Kernel: $(uname -r)" | tee -a "$AUDIT_DIR/audit.txt"

# 1. CPU Info
echo -e "\n--- CPU ---" | tee -a "$AUDIT_DIR/audit.txt"
lscpu | tee -a "$AUDIT_DIR/audit.txt"
mpstat -P ALL 1 3 | tee -a "$AUDIT_DIR/audit.txt"

# 2. Memory Info
echo -e "\n--- MEMORY ---" | tee -a "$AUDIT_DIR/audit.txt"
free -h | tee -a "$AUDIT_DIR/audit.txt"
cat /proc/meminfo | grep -E "(MemTotal|MemFree|Cached|SwapTotal|SwapFree|HugePages_Total)" | tee -a "$AUDIT_DIR/audit.txt"
echo "Swappiness: $(cat /proc/sys/vm/swappiness)" | tee -a "$AUDIT_DIR/audit.txt"

# 3. Disk Info
echo -e "\n--- DISK ---" | tee -a "$AUDIT_DIR/audit.txt"
lsblk | tee -a "$AUDIT_DIR/audit.txt"
iostat -x 1 3 | tee -a "$AUDIT_DIR/audit.txt"
for d in /sys/block/sd* /sys/block/nvme*; do
    if [ -d "$d" ]; then
        dev=$(basename "$d")
        echo "$dev scheduler: $(cat $d/queue/scheduler)" | tee -a "$AUDIT_DIR/audit.txt"
        echo "$dev nr_requests: $(cat $d/queue/nr_requests)" | tee -a "$AUDIT_DIR/audit.txt"
        echo "$dev read_ahead: $(blockdev --getra /dev/$dev)" | tee -a "$AUDIT_DIR/audit.txt"
    fi
done

# 4. Network Info
echo -e "\n--- NETWORK ---" | tee -a "$AUDIT_DIR/audit.txt"
ip addr show | tee -a "$AUDIT_DIR/audit.txt"
ip link show | tee -a "$AUDIT_DIR/audit.txt"
for iface in $(ip -br link | awk '{print $1}' | grep -v lo); do
    echo "--- $iface ---" | tee -a "$AUDIT_DIR/audit.txt"
    ethtool "$iface" 2>/dev/null | head -20 | tee -a "$AUDIT_DIR/audit.txt"
    ethtool -g "$iface" 2>/dev/null | tee -a "$AUDIT_DIR/audit.txt"
    ethtool -S "$iface" 2>/dev/null | grep -E "(drop|error|miss)" | tee -a "$AUDIT_DIR/audit.txt"
done

# 5. Kernel Parameters
echo -e "\n--- KEY SYSCTL ---" | tee -a "$AUDIT_DIR/audit.txt"
for param in vm.swappiness vm.dirty_ratio vm.dirty_background_ratio \
    vm.vfs_cache_pressure vm.overcommit_memory vm.nr_hugepages \
    net.core.rmem_default net.core.wmem_default net.core.rmem_max net.core.wmem_max \
    net.ipv4.tcp_rmem net.ipv4.tcp_wmem net.core.netdev_budget net.core.somaxconn \
    kernel.sched_migration_cost_ns; do
    echo "$param = $(sysctl -n $param 2>/dev/null || echo 'N/A')" | tee -a "$AUDIT_DIR/audit.txt"
done

# 6. Running Services
echo -e "\n--- TOP RESOURCE CONSUMERS ---" | tee -a "$AUDIT_DIR/audit.txt"
ps aux --sort=-%cpu | head -10 | tee -a "$AUDIT_DIR/audit.txt"
echo "" | tee -a "$AUDIT_DIR/audit.txt"
ps aux --sort=-%mem | head -10 | tee -a "$AUDIT_DIR/audit.txt"

# 7. perf quick stat (30 seconds)
echo -e "\n--- PERF STAT (30s system-wide) ---" | tee -a "$AUDIT_DIR/audit.txt"
perf stat -a -- sleep 30 2>&1 | tee -a "$AUDIT_DIR/audit.txt"

echo -e "\nAudit saved to $AUDIT_DIR/audit.txt"
echo "Now review the findings and write recommendations."
```

**Audit deliverable — Recommendation Report Template:**

```
# Performance Audit Report: $(hostname)


---

[← Previous](15-section-13-capacity-planning.md) | [↑ Index](index.md) | [Next →](17-date-date.md)
