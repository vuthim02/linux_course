## 15 Hands-On Practices

### Practice 1: Read and Interpret /proc/meminfo

```bash
# Comprehensive memory analysis
echo "=== Memory Analysis ==="
echo ""
echo "Total RAM: $(awk '/MemTotal/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Available: $(awk '/MemAvailable/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Free:      $(awk '/MemFree/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo ""
echo "=== Breakdown ==="
awk '/^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapCached|Active|Inactive|Dirty|Writeback|Shmem|Slab|SReclaimable|SUnreclaim|SwapTotal|SwapFree)/{printf "%-20s %10.1f MB\n", $1, $2/1024}' /proc/meminfo
```

✅ **Expected**: Complete memory breakdown showing total, available, cache, slab, and swap usage

### Practice 2: Monitor Page Cache with vmstat

```bash
# Watch page cache activity over 30 seconds
echo "=== Page Cache Activity (30s) ==="
vmstat 1 30
# Key columns: free, buff, cache, si, so, bi, bo
# bi = blocks in (disk reads → page cache)
# bo = blocks out (dirty pages → disk)
# If bi is high: lots of cache misses (cold start)
# If bi is low: cache is working (hits)
```

✅ **Expected**: Clear view of page cache behavior — low bi/bo indicates good cache hit ratio

### Practice 3: Drop Caches and Observe Impact

```bash
# Before dropping
echo "=== Before Drop ==="
free -h | grep -E "total|Mem|Swap"
echo ""
time dd if=/var/log/syslog of=/dev/null bs=1M
echo ""

# Drop caches
echo 3 | sudo tee /proc/sys/vm/drop_caches

# After dropping — first read will be slow
echo "=== After Drop ==="
free -h | grep -E "total|Mem|Swap"
echo ""
time dd if=/var/log/syslog of=/dev/null bs=1M
echo ""

# Second read (now cached again)
echo "=== Second Read (Cached) ==="
time dd if=/var/log/syslog of=/dev/null bs=1M
```

✅ **Expected**: First read after drop is slow (disk I/O), second read is fast (cache hit)

### Practice 4: Create and Configure Swap

```bash
# Create a 4GB swap file
sudo fallocate -l 4G /swapfile_test
sudo chmod 600 /swapfile_test
sudo mkswap /swapfile_test
sudo swapon -p 5 /swapfile_test

# Verify
sudo swapon --show
# NAME             TYPE    SIZE USED PRIO
# /swapfile_test   file     4G   0B    5

# Monitor swap usage
watch -n 2 'free -h | grep Swap'

# Clean up
sudo swapoff /swapfile_test
sudo rm /swapfile_test
```

✅ **Expected**: Swap file created, activated with priority 5, visible in `swapon --show`

### Practice 5: Set Up zram

```bash
# Create zram device
sudo modprobe zram
echo lz4 | sudo tee /sys/block/zram0/comp_algorithm
echo 4G | sudo tee /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon -p 100 /dev/zram0

# Verify zram is active
sudo swapon --show
# NAME       TYPE       SIZE USED PRIO
# /dev/zram0 partition    4G   0B  100

# Check compression ratio (after some usage)
cat /sys/block/zram0/mm_stat | awk '{printf "Original: %.1f GB\nCompressed: %.1f GB\nRatio: %.1f:1\n", $1/1073741824, $2/1073741824, $1/$2}'

# Load test
stress-ng --vm 2 --vm-bytes 2G --vm-method all -t 30s

# Check compression after load
cat /sys/block/zram0/mm_stat | awk '{printf "Compression ratio: %.1f:1\n", $1/$2}'
```

✅ **Expected**: zram active at priority 100, compression ratio 2:1 or better

### Practice 6: Read NUMA Topology

```bash
# Full NUMA topology
echo "=== NUMA Topology ==="
numactl --hardware
echo ""
echo "=== NUMA Statistics ==="
numastat
echo ""
echo "=== NUMA Distances ==="
lscpu | grep -A 10 "NUMA"
echo ""
echo "=== Per-CPU NUMA Node ==="
lscpu | grep "NUMA node"
```

✅ **Expected**: Clear view of NUMA nodes, CPUs per node, distances, and memory per node

### Practice 7: Test NUMA Memory Placement

```bash
# Run on local node
numactl --cpunodebind=0 --membind=0 stress-ng --vm 1 --vm-bytes 1G -t 10s &
PID1=$!
sleep 2

# Run on remote node (interleaved)
numactl --interleave=all stress-ng --vm 1 --vm-bytes 1G -t 10s &
PID2=$!
sleep 2

# Compare NUMA statistics
echo "=== NUMA Hit/Miss ==="
numastat
echo ""
echo "=== Memory placement for stress-ng processes ==="
cat /proc/$PID1/numa_maps | head -5
cat /proc/$PID2/numa_maps | head -5

wait $PID1 $PID2 2>/dev/null
```

✅ **Expected**: Local allocation shows lower NUMA miss rate; interleaved shows balanced allocation

### Practice 8: Control OOM Killer

```bash
# Create a test process
sleep 3600 &
TEST_PID=$!

# Check its OOM score
echo "=== Default OOM Score ==="
echo "PID: $TEST_PID"
echo "OOM Score: $(cat /proc/$TEST_PID/oom_score)"
echo "OOM Score Adj: $(cat /proc/$TEST_PID/oom_score_adj)"

# Protect the process
echo -1000 | sudo tee /proc/$TEST_PID/oom_score_adj
echo ""
echo "=== Protected OOM Score ==="
echo "OOM Score: $(cat /proc/$TEST_PID/oom_score)"
echo "OOM Score Adj: $(cat /proc/$TEST_PID/oom_score_adj)"

# Make it expendable
echo 1000 | sudo tee /proc/$TEST_PID/oom_score_adj
echo ""
echo "=== Expendable OOM Score ==="
echo "OOM Score: $(cat /proc/$TEST_PID/oom_score)"
echo "OOM Score Adj: $(cat /proc/$TEST_PID/oom_score_adj)"

# Cleanup
kill $TEST_PID
```

✅ **Expected**: oom_score changes from default → protected (-1000) → expendable (1000)

### Practice 9: Monitor Slab Memory

```bash
# View top slab consumers
echo "=== Top Slab Allocations ==="
sudo slabtop -o -s c | head -25

# Track slab growth
echo "=== Slab Growth Over 30 Seconds ==="
for i in $(seq 1 6); do
    echo "Sample $i: $(date)"
    grep -E "SReclaimable|SUnreclaim" /proc/meminfo
    echo ""
    sleep 5
done

# Find specific slab caches
echo "=== Filesystem-related Slab ==="
cat /proc/slabinfo | grep -E "ext4|dentry|inode" | head -10
```

✅ **Expected**: Clear view of kernel memory allocations and their growth patterns

### Practice 10: Overcommit Testing

```bash
# Check current overcommit settings
echo "=== Current Overcommit Settings ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "overcommit_ratio: $(cat /proc/sys/vm/overcommit_ratio)"
echo ""
echo "CommitLimit: $(awk '/CommitLimit/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Committed_AS: $(awk '/Committed_AS/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo ""

# Set mode 2 (strict)
sudo sysctl vm.overcommit_memory=2
sudo sysctl vm.overcommit_ratio=80

echo "=== After Setting Mode 2 ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "CommitLimit: $(awk '/CommitLimit/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Committed_AS: $(awk '/Committed_AS/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"

# Restore default
sudo sysctl vm.overcommit_memory=0
```

✅ **Expected**: CommitLimit calculated as (RAM + swap) × overcommit_ratio, strict mode enforced

### Practice 11: Diagnose Memory Pressure

```bash
# Comprehensive memory pressure check
echo "=== Memory Pressure Diagnosis ==="
echo ""

echo "1. Available Memory:"
awk '/MemAvailable/{printf "   Available: %.1f GB / %.1f GB total (%.0f%%)\n", $2/1048576, $(/MemTotal/{print $2})/1048576, $2/$(/MemTotal/{print $2})*100}' /proc/meminfo

echo ""
echo "2. Swap Usage:"
awk '/SwapTotal/{total=$2} /SwapFree/{free=$2} END{printf "   Swap: %.1f GB / %.1f GB used\n", (total-free)/1048576, total/1048576}' /proc/meminfo

echo ""
echo "3. Swap Activity (10s):"
vmstat 1 10 | tail -5

echo ""
echo "4. Major Page Faults (disk reads):"
awk '/pgmajfault/{print "   " $0}' /proc/vmstat

echo ""
echo "5. Top Memory Consumers:"
ps aux --sort=-%mem | head -6
```

✅ **Expected**: Complete picture of memory health — available, swap, page faults, top consumers

### Practice 12: Database Memory Tuning

```bash
# Simulate PostgreSQL memory tuning on a 32GB system
echo "=== PostgreSQL Memory Tuning (32GB System) ==="
echo ""

TOTAL_RAM=32768  # MB
OS_RESERVED=4096  # 4GB for OS
PG_AVAILABLE=$((TOTAL_RAM - OS_RESERVED))  # 28GB

SHARED_BUFFERS=$((PG_AVAILABLE / 4))       # 7GB (25%)
EFFECTIVE_CACHE=$((PG_AVAILABLE * 75 / 100)) # 21GB (75%)
WORK_MEM=64                                 # 64MB per operation
MAINTENANCE_WORK_MEM=$((PG_AVAILABLE / 14)) # 2GB

echo "Total RAM: ${TOTAL_RAM}MB"
echo "OS Reserved: ${OS_RESERVED}MB"
echo "PostgreSQL Available: ${PG_AVAILABLE}MB"
echo ""
echo "Suggested PostgreSQL settings:"
echo "  shared_buffers = ${SHARED_BUFFERS}MB"
echo "  effective_cache_size = ${EFFECTIVE_CACHE}MB"
echo "  work_mem = ${WORK_MEM}MB"
echo "  maintenance_work_mem = ${MAINTENANCE_WORK_MEM}MB"
echo "  huge_pages = try"
echo ""
echo "NUMA: Run with: numactl --interleave=all postgres"
```

✅ **Expected**: Tuned PostgreSQL settings based on available system RAM

### Practice 13: JVM Memory Planning

```bash
# Plan JVM memory for a 32GB system running Elasticsearch
echo "=== JVM Memory Planning (32GB System) ==="
echo ""

TOTAL_RAM=32768  # MB
OS_RESERVED=4096  # 4GB for OS
JVM_TOTAL=$((TOTAL_RAM - OS_RESERVED))  # 28GB

HEAP=$((JVM_TOTAL * 85 / 100))          # 85% of JVM budget = 23GB
YOUNG_GEN=$((HEAP / 6))                 # ~4GB young gen
METASPACE=1024                          # 1GB
CODE_CACHE=256                          # 256MB
DIRECT_MEMORY=$((JVM_TOTAL - HEAP - METASPACE - CODE_CACHE))  # ~3GB

echo "Total RAM: ${TOTAL_RAM}MB"
echo "OS Reserved: ${OS_RESERVED}MB"
echo ""
echo "JVM Budget: ${JVM_TOTAL}MB"
echo "  Heap (-Xmx): ${HEAP}MB"
echo "  Young Gen (-Xmn): ${YOUNG_GEN}MB"
echo "  Metaspace: ${METASPACE}MB"
echo "  Code Cache: ${CODE_CACHE}MB"
echo "  Direct Memory: ${DIRECT_MEMORY}MB"
echo ""
echo "Java command:"
echo "  java -Xmx${HEAP}m -Xms${HEAP}m -Xmn${YOUNG_GEN}m \\"
echo "       -XX:MaxMetaspaceSize=${METASPACE}m \\"
echo "       -XX:ReservedCodeCacheSize=${CODE_CACHE}m \\"
echo "       -XX:MaxDirectMemorySize=${DIRECT_MEMORY}m \\"
echo "       -XX:+UseG1GC -XX:MaxGCPauseMillis=200 \\"
echo "       -jar elasticsearch.jar"
```

✅ **Expected**: JVM parameters calculated with proper OS reservation and memory breakdown

### Practice 14: Memory Monitoring Script

```bash
#!/bin/bash
# mem_monitor.sh — Comprehensive memory monitoring
echo "=== Memory Monitor $(date) ==="
echo ""

echo "┌─────────────────────────────────────────────────────┐"
echo "│ SYSTEM MEMORY                                        │"
echo "├─────────────────────────────────────────────────────┤"
printf "│ Total:     %8.1f GB                              │\n" $(awk '/MemTotal/{print $2/1048576}' /proc/meminfo)
printf "│ Available: %8.1f GB                              │\n" $(awk '/MemAvailable/{print $2/1048576}' /proc/meminfo)
printf "│ Free:      %8.1f GB                              │\n" $(awk '/MemFree/{print $2/1048576}' /proc/meminfo)
printf "│ Buffers:   %8.1f GB                              │\n" $(awk '/Buffers/{print $2/1048576}' /proc/meminfo)
printf "│ Cached:    %8.1f GB                              │\n" $(awk '/^Cached:/{print $2/1048576}' /proc/meminfo)
echo "├─────────────────────────────────────────────────────┤"
printf "│ Swap:      %5.1f / %.1f GB                        │\n" $(awk '/SwapTotal/{t=$2} /SwapFree/{printf "%.1f %.1f", (t-$2)/1048576, t/1048576}' /proc/meminfo)
echo "├─────────────────────────────────────────────────────┤"
echo "│ PRESSURE INDICATORS                                  │"
echo "├─────────────────────────────────────────────────────┤"
PCT_AVAIL=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.0f", a/t*100}' /proc/meminfo)
if [ "$PCT_AVAIL" -lt 20 ]; then
    echo "│ ⚠️  CRITICAL: Available memory < 20%               │"
elif [ "$PCT_AVAIL" -lt 40 ]; then
    echo "│ ⚠️  WARNING:  Available memory < 40%               │"
else
    echo "│ ✅ OK:       Available memory > 40%               │"
fi
echo "└─────────────────────────────────────────────────────┘"
```

✅ **Expected**: Color-coded memory health report with pressure indicators

### Practice 15: Complete Memory Audit

```bash
#!/bin/bash
# memory_audit.sh — Full system memory audit
echo "============================================"
echo "  COMPLETE MEMORY AUDIT — $(date)"
echo "============================================"
echo ""

echo "=== 1. Physical Memory ==="
free -h
echo ""

echo "=== 2. Memory per Process (Top 10) ==="
ps aux --sort=-%mem | head -11
echo ""

echo "=== 3. Slab Memory (Top 10) ==="
sudo slabtop -o -s c 2>/dev/null | head -15
echo ""

echo "=== 4. NUMA Topology ==="
numactl --hardware 2>/dev/null || echo "NUMA not available"
echo ""

echo "=== 5. Overcommit Settings ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "overcommit_ratio: $(cat /proc/sys/vm/overcommit_ratio)"
echo "CommitLimit: $(awk '/CommitLimit/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo "Committed_AS: $(awk '/Committed_AS/{printf "%.1f GB", $2/1048576}' /proc/meminfo)"
echo ""

echo "=== 6. Swap Devices ==="
sudo swapon --show 2>/dev/null || echo "No swap"
echo ""

echo "=== 7. OOM Configuration ==="
echo "vm.panic_on_oom: $(cat /proc/sys/vm/panic_on_oom)"
echo ""
echo "Protected processes (oom_score_adj < 0):"
for pid in /proc/[0-9]*/oom_score_adj; do
    val=$(cat "$pid" 2>/dev/null)
    if [ "$val" -lt 0 ] 2>/dev/null; then
        comm=$(cat "$(dirname $pid)/comm" 2>/dev/null)
        echo "  PID $(basename $(dirname $pid)): $comm (adj=$val)"
    fi
done
echo ""

echo "=== 8. Recent OOM Events ==="
dmesg | grep -i "oom\|out of memory\|killed process" | tail -5 || echo "No OOM events"
echo ""

echo "=== 9. Page Fault Rate ==="
echo "Before: $(grep pgmajfault /proc/vmstat)"
sleep 5
echo "After:  $(grep pgmajfault /proc/vmstat)"
echo ""
echo "============================================"
echo "  AUDIT COMPLETE"
echo "============================================"
```

✅ **Expected**: Complete memory audit covering physical, virtual, slab, NUMA, swap, OOM, and overcommit

---



---

[← Previous](10-9-tuning-for-applications.md) | [↑ Index](index.md) | [Next →](12-deep-understanding.md)
