## 🔬 15 Hands-On Practices

### Level 1 Practices: Building Your First Arrays

**Goal:** Create, format, and destroy the basic RAID levels (0, 1, 5, 10) using `mdadm`.


### Practice 1: Create and Destroy RAID 0

```bash
# Setup loopback devices
dd if=/dev/zero of=/tmp/disk1.img bs=1M count=50
dd if=/dev/zero of=/tmp/disk2.img bs=1M count=50
losetup /dev/loop1 /tmp/disk1.img
losetup /dev/loop2 /tmp/disk2.img

# Create RAID 0
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/loop1 /dev/loop2

# Create filesystem, mount, write test data
mkfs.ext4 /dev/md0
mkdir -p /mnt/raid0
mount /dev/md0 /mnt/raid0
echo "RAID 0 test data" > /mnt/raid0/test.txt

# Verify
mdadm --detail /dev/md0
cat /proc/mdstat

# Stop and clean up
umount /mnt/raid0
mdadm --stop /dev/md0
losetup -d /dev/loop1 /dev/loop2
rm -f /tmp/disk1.img /tmp/disk2.img
```

### Practice 2: RAID 1 — Mirroring

```bash
dd if=/dev/zero of=/tmp/disk{1,2}.img bs=1M count=100
losetup /dev/loop1 /tmp/disk1.img
losetup /dev/loop2 /tmp/disk2.img

mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/loop1 /dev/loop2

# Both drives have identical data
# Let's verify by creating a filesystem and writing
mkfs.ext4 /dev/md1
mount /dev/md1 /mnt/raid1
dd if=/dev/urandom of=/mnt/raid1/data.bin bs=1K count=1000

# Check mdstat — note the [UU] (both up)
cat /proc/mdstat

# Clean up
umount /mnt/raid1
mdadm --stop /dev/md1
losetup -d /dev/loop1 /dev/loop2
rm -f /tmp/disk1.img /tmp/disk2.img
```

### Practice 3: RAID 5 with 3 Drives

```bash
for i in {1..3}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

mdadm --create /dev/md5 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3

# Wait for initial resync to finish
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Create filesystem
mkfs.ext4 /dev/md5
mkdir -p /mnt/raid5
mount /dev/md5 /mnt/raid5

# Check capacity: 3 × 100 MiB drives, but only 200 MiB usable (N-1)
df -h /mnt/raid5

# Write a 50 MiB file — should work
dd if=/dev/urandom of=/mnt/raid5/largefile bs=1M count=50

umount /mnt/raid5
mdadm --stop /dev/md5
for i in {1..3}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 4: RAID 10 with 4 Drives

```bash
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=200
    losetup /dev/loop$i /tmp/disk$i.img
done

mdadm --create /dev/md10 --level=10 --raid-devices=4 /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4

while grep -q "resync" /proc/mdstat; do sleep 2; done

# Capacity should be ~400 MiB (4 × 200 / 2 = 400 MiB)
mkfs.ext4 /dev/md10
mount /dev/md10 /mnt/raid10
df -h /mnt/raid10

umount /mnt/raid10
mdadm --stop /dev/md10
for i in {1..4}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Level 2 Practices: Management, Recovery & Monitoring

**Goal:** Handle real-world RAID operations — disk failures, hot spares, array growth, level migration, and monitoring.


### Practice 5: Simulate Disk Failure and Rebuild (RAID 5)

```bash
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=200
    losetup /dev/loop$i /tmp/disk$i.img
done

# Create RAID 5 with a spare
mdadm --create /dev/md0 --level=5 --raid-devices=3 --spare-devices=1 \
    /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4

while grep -q "resync" /proc/mdstat; do sleep 2; done

# Create filesystem and write test data
mkfs.ext4 /dev/md0
mount /dev/md0 /mnt/raid5
dd if=/dev/urandom of=/mnt/raid5/test.bin bs=1K count=10000
md5sum /mnt/raid5/test.bin > /tmp/test.md5

# FAILURE — simulate a dead drive by failing loop2
mdadm --fail /dev/md0 /dev/loop2
mdadm --detail /dev/md0 | grep State

# The spare (loop4) should start rebuilding automatically
watch -n 1 cat /proc/mdstat

# Wait for rebuild
while grep -q "recovery" /proc/mdstat; do sleep 5; done

# Check data integrity
md5sum -c /tmp/test.md5

# Remove the failed drive
mdadm --remove /dev/md0 /dev/loop2

# Clean up
umount /mnt/raid5
mdadm --stop /dev/md0
for i in {1..4}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 6: Simulate Failure Without a Spare

```bash
for i in {1..3}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3
while grep -q "resync" /proc/mdstat; do sleep 2; done

mkfs.ext4 /dev/md0
mount /dev/md0 /mnt/raid5
echo "IMPORTANT DATA" > /mnt/raid5/survival.txt
cat /mnt/raid5/survival.txt

# FAIL loop2
mdadm --fail /dev/md0 /dev/loop2
mdadm --remove /dev/md0 /dev/loop2

# Array is now degraded — still readable
cat /mnt/raid5/survival.txt

# Add a new drive to rebuild
dd if=/dev/zero of=/tmp/disk4.img bs=1M count=100
losetup /dev/loop4 /tmp/disk4.img
mdadm --add /dev/md0 /dev/loop4

while grep -q "recovery" /proc/mdstat; do sleep 5; done

# Verify data
cat /mnt/raid5/survival.txt

umount /mnt/raid5
mdadm --stop /dev/md0
for i in {1..4}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 7: Add a Hot Spare to an Existing Array

```bash
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

# Create RAID 5 with 3 drives (no spare)
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Add loop4 as a hot spare
mdadm --add /dev/md0 /dev/loop4

# Verify spare status
mdadm --detail /dev/md0 | grep -E "Spare|Total Devices"

# Now fail a drive and watch spare activate automatically
mdadm --fail /dev/md0 /dev/loop2
sleep 2
cat /proc/mdstat   # Should show recovery starting on loop4

while grep -q "recovery" /proc/mdstat; do sleep 5; done
mdadm --detail /dev/md0

mdadm --stop /dev/md0
for i in {1..4}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 8: Grow a RAID Array (Add a Drive)

```bash
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

# Start with RAID 5 on 3 drives
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Note the original size
mdadm --detail /dev/md0 | grep "Array Size"

# Grow to 4 drives
mdadm --add /dev/md0 /dev/loop4
mdadm --grow /dev/md0 --raid-devices=4

# Watch the reshape — this can take a while even on loop devices
watch -n 1 cat /proc/mdstat

while grep -q "reshape" /proc/mdstat; do sleep 5; done

# Confirm new size
mdadm --detail /dev/md0 | grep "Array Size"

mdadm --stop /dev/md0
for i in {1..4}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 9: Migrate RAID Level (RAID 1 → RAID 5)

```bash
for i in {1..3}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

# Start as RAID 1 with 2 drives
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/loop1 /dev/loop2
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Add third drive and grow to RAID 5
mdadm --add /dev/md0 /dev/loop3
mdadm --grow /dev/md0 --level=5 --raid-devices=3

while grep -q "reshape" /proc/mdstat; do sleep 5; done

mdadm --detail /dev/md0 | grep "Raid Level"

mdadm --stop /dev/md0
for i in {1..3}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

Note: Growing a RAID is not the same as migrating a level. The actual migration is done entirely by the kernel md driver, which reads the old layout and writes the new layout. The `--grow --level=` flag triggers this.

### Practice 10: Configure mdadm Monitoring

```bash
# Create a simple test array
dd if=/dev/zero of=/tmp/disk1.img bs=1M count=50
dd if=/dev/zero of=/tmp/disk2.img bs=1M count=50
losetup /dev/loop1 /tmp/disk1.img
losetup /dev/loop2 /tmp/disk2.img
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/loop1 /dev/loop2
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Configure monitoring in mdadm.conf
cat >> /etc/mdadm/mdadm.conf << 'EOF'
MAILADDR root@localhost
EOF

# Run mdadm monitor in test mode
mdadm --monitor --scan --test --mail=root@localhost /dev/md0

# You should see a test alert email sent to root
# Check if mail was sent (may require a local MTA):
mail

mdadm --stop /dev/md0
losetup -d /dev/loop1 /dev/loop2
rm -f /tmp/disk1.img /tmp/disk2.img
```

### Level 3 Practices: Advanced Operations & Tuning

**Goal:** Master advanced RAID operations — LVM integration, benchmarking, bitmap tuning, resync control, and production-grade deployment.


### Practice 11: RAID with LVM Integration

```bash
for i in {1..3}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=200
    losetup /dev/loop$i /tmp/disk$i.img
done

# Create RAID 5 array
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Setup LVM on top of RAID
pvcreate /dev/md0
vgcreate vg_raid /dev/md0
lvcreate -n lv_data -L 150M vg_raid
lvcreate -n lv_logs -l 100%FREE vg_raid

# Create filesystems
mkfs.ext4 /dev/vg_raid/lv_data
mkfs.xfs /dev/vg_raid/lv_logs

# Mount and test
mkdir -p /mnt/data /mnt/logs
mount /dev/vg_raid/lv_data /mnt/data
mount /dev/vg_raid/lv_logs /mnt/logs
df -h | grep -E "data|logs"

umount /mnt/data /mnt/logs
lvremove -f vg_raid
vgremove vg_raid
pvremove /dev/md0
mdadm --stop /dev/md0
for i in {1..3}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 12: Benchmark Different RAID Levels

```bash
# Build a test function
bench_raid() {
    local level=$1
    local name=$2
    local dev=$3
    
    echo "=== Benchmarking $name ==="
    
    # Sequential write
    echo "Sequential write (1M blocks):"
    dd if=/dev/zero of=$dev bs=1M count=50 oflag=direct 2>&1 | tail -1
    
    # Sequential read
    echo "Sequential read (1M blocks):"
    dd if=$dev of=/dev/null bs=1M count=50 iflag=direct 2>&1 | tail -1
    
    # Random write (using dd with seek)
    echo "Random write (4K blocks):"
    dd if=/dev/zero of=$dev bs=4K count=5000 oflag=direct seek=0 2>&1 | tail -1
    
    echo ""
}

# Create arrays and benchmark each one
# (Loop devices for each level)

# RAID 0
for i in {1..2}; do
    dd if=/dev/zero of=/tmp/r0_$i.img bs=1M count=100 2>/dev/null
    losetup /dev/loop$i /tmp/r0_$i.img
done
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/loop1 /dev/loop2
bench_raid 0 "RAID 0" /dev/md0

# RAID 5
for i in {3..5}; do
    dd if=/dev/zero of=/tmp/r5_$i.img bs=1M count=100 2>/dev/null
    losetup /dev/loop$i /tmp/r5_$i.img
done
mdadm --create /dev/md5 --level=5 --raid-devices=3 /dev/loop3 /dev/loop4 /dev/loop5
while grep -q "resync" /proc/mdstat 2>/dev/null; do sleep 2; done
bench_raid 5 "RAID 5" /dev/md5

# RAID 10
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/r10_$i.img bs=1M count=100 2>/dev/null
    idx=$((i + 5))
    losetup /dev/loop$idx /tmp/r10_$i.img
done
mdadm --create /dev/md10 --level=10 --raid-devices=4 /dev/loop6 /dev/loop7 /dev/loop8 /dev/loop9
while grep -q "resync" /proc/mdstat 2>/dev/null; do sleep 2; done
bench_raid 10 "RAID 10" /dev/md10

# Cleanup
for md in md0 md5 md10; do
    mdadm --stop /dev/$md 2>/dev/null
done
for i in $(seq 1 9); do
    losetup -d /dev/loop$i 2>/dev/null
done
rm -f /tmp/r0_*.img /tmp/r5_*.img /tmp/r10_*.img
```

### Practice 13: Write-Intent Bitmap Operations

```bash
for i in {1..3}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Add internal bitmap
mdadm --grow /dev/md0 --bitmap=internal

# Verify bitmap
mdadm --detail /dev/md0 | grep -i bitmap

# Create array with bitmap from start
mdadm --stop /dev/md0
mdadm --create /dev/md0 --level=5 --raid-devices=3 \
    --bitmap=internal /dev/loop1 /dev/loop2 /dev/loop3

# Remove bitmap
mdadm --grow /dev/md0 --bitmap=none

mdadm --stop /dev/md0
for i in {1..3}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 14: Resync Speed Tuning

```bash
for i in {1..3}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=200
    losetup /dev/loop$i /tmp/disk$i.img
done

# Create array with a spare for rebuild testing
dd if=/dev/zero of=/tmp/disk4.img bs=1M count=200
losetup /dev/loop4 /tmp/disk4.img

mdadm --create /dev/md0 --level=5 --raid-devices=3 --spare-devices=1 \
    /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4
while grep -q "resync" /proc/mdstat; do sleep 2; done

# Slow down resync
echo 5000 > /proc/sys/dev/raid/speed_limit_max

# Fail a drive to trigger rebuild
mdadm --fail /dev/md0 /dev/loop2
sleep 2
cat /proc/mdstat
# Note the slower recovery speed

# Speed it up
echo 500000 > /proc/sys/dev/raid/speed_limit_max
sleep 2
cat /proc/mdstat
# Speed should have increased

while grep -q "recovery" /proc/mdstat; do sleep 5; done

# Restore defaults
echo 200000 > /proc/sys/dev/raid/speed_limit_max

mdadm --stop /dev/md0
for i in {1..4}; do losetup -d /dev/loop$i; rm -f /tmp/disk$i.img; done
```

### Practice 15: Real-World Integration

This is the capstone practice. You will build a production-like RAID 10 array, configure it with LVM, create filesystems, set up monitoring, simulate a double failure, and document the recovery.

```bash
# ──────────────────────────────────────────────
# PHASE 1: SETUP — 6 virtual drives (simulating 6 physical disks)
# ──────────────────────────────────────────────
for i in {1..6}; do
    dd if=/dev/zero of=/tmp/prod_disk$i.img bs=1M count=500
    losetup /dev/loop$i /tmp/prod_disk$i.img
done

echo "=== PHASE 1: 6 virtual drives (1 GiB each) created ==="

# ──────────────────────────────────────────────
# PHASE 2: CREATE RAID 10 WITH SPARES
# 4 active + 2 hot spares
# ──────────────────────────────────────────────
# RAID 10 layout near=2 on loop1-4, 2 hot spares on loop5-6
mdadm --create /dev/md0 --level=10 --raid-devices=4 \
    --spare-devices=2 \
    --layout=n2 --chunk=64K \
    /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4 \
    /dev/loop5 /dev/loop6

# Wait for initial resync
while grep -q "resync" /proc/mdstat; do
    echo "Resync in progress... $(grep -oP '\d+\.\d+%' /proc/mdstat 2>/dev/null || echo 'starting')"
    sleep 3
done

echo "=== PHASE 2: RAID 10 created with 2 hot spares ==="
mdadm --detail /dev/md0 | grep -E "Raid|Total|Active|Working|Spare|Chunk"

# ──────────────────────────────────────────────
# PHASE 3: LVM ON TOP OF RAID
# ──────────────────────────────────────────────
# Total capacity = 4 × 500 MiB / 2 (RAID 10) = ~1000 MiB

pvcreate /dev/md0
vgcreate vg_prod /dev/md0

lvcreate -n lv_database -L 400M vg_prod
lvcreate -n lv_web -L 200M vg_prod
lvcreate -n lv_logs -L 100M vg_prod
lvcreate -n lv_backup -l 100%FREE vg_prod

mkfs.ext4 /dev/vg_prod/lv_database
mkfs.ext4 /dev/vg_prod/lv_web
mkfs.xfs  /dev/vg_prod/lv_logs
mkfs.ext4 /dev/vg_prod/lv_backup

mkdir -p /mnt/prod/{database,web,logs,backup}
mount /dev/vg_prod/lv_database /mnt/prod/database
mount /dev/vg_prod/lv_web /mnt/prod/web
mount /dev/vg_prod/lv_logs /mnt/prod/logs
mount /dev/vg_prod/lv_backup /mnt/prod/backup

echo "=== PHASE 3: LVM volumes created and mounted ==="
df -h | grep prod

# ──────────────────────────────────────────────
# PHASE 4: POPULATE WITH DATA
# ──────────────────────────────────────────────
# Simulate database tables
for i in $(seq 1 10); do
    dd if=/dev/urandom of=/mnt/prod/database/table_$i.dat bs=1K count=100 2>/dev/null
done

# Web content
echo "<html><body><h1>Production Server</h1></body></html>" > /mnt/prod/web/index.html
for i in $(seq 1 5); do
    echo "Log entry $i: system OK at $(date)" >> /mnt/prod/logs/app.log
done

# Calculate checksums for later verification
find /mnt/prod -type f -exec md5sum {} \; > /tmp/prod_checksums.txt
echo "=== PHASE 4: Test data written, checksums recorded ==="

# ──────────────────────────────────────────────
# PHASE 5: CONFIGURE MONITORING
# ──────────────────────────────────────────────
# Add to mdadm.conf
cat >> /etc/mdadm/mdadm.conf << 'CONF'
MAILADDR root@localhost
CONF

mdadm --detail --scan >> /etc/mdadm/mdadm.conf

# Start monitoring in background
mdadm --monitor --scan --daemonise --syslog
echo "=== PHASE 5: Monitoring configured ==="

# ──────────────────────────────────────────────
# PHASE 6: SIMULATE SINGLE DISK FAILURE
# ──────────────────────────────────────────────
echo "=== PHASE 6: FAILING DISK loop1 (member of first mirror pair) ==="
mdadm --fail /dev/md0 /dev/loop1
mdadm --remove /dev/md0 /dev/loop1

# Watch rebuild from hot spare
echo "Rebuild should start automatically on spare..."
sleep 4
cat /proc/mdstat

while grep -q "recovery" /proc/mdstat; do
    echo "Rebuilding... $(grep -oP '\d+\.\d+%' /proc/mdstat | head -1)"
    sleep 3
done

echo "Rebuild complete. Checking data integrity..."
md5sum -c /tmp/prod_checksums.txt 2>/dev/null | grep -v "OK$" && echo "DATA CORRUPTION DETECTED" || echo "All checksums match — data intact"

# ──────────────────────────────────────────────
# PHASE 7: SIMULATE SECOND DISK FAILURE
# ──────────────────────────────────────────────
echo "=== PHASE 7: FAILING SECOND DISK loop3 (different mirror pair) ==="
# loop3 is in the second mirror pair (loop3-loop4)
mdadm --fail /dev/md0 /dev/loop3
mdadm --remove /dev/md0 /dev/loop3

# Second hot spare (loop6) should activate
sleep 4
cat /proc/mdstat

while grep -q "recovery" /proc/mdstat; do
    echo "Rebuilding... $(grep -oP '\d+\.\d+%' /proc/mdstat | head -1)"
    sleep 3
done

echo "Second rebuild complete. Checking data integrity..."
md5sum -c /tmp/prod_checksums.txt 2>/dev/null | grep -v "OK$" && echo "DATA CORRUPTION DETECTED" || echo "All checksums match — RAID 10 survived double disk failure!"

# ──────────────────────────────────────────────
# PHASE 8: DOCUMENTATION AND CLEANUP
# ──────────────────────────────────────────────
echo "=== PHASE 8: Recovery Documentation ==="
{
    echo "RAID 10 Recovery Report — $(date)"
    echo "====================================="
    echo "Original configuration:"
    echo "  4 active drives (loop1-4) in RAID 10 near=2"
    echo "  2 hot spares (loop5-6)"
    echo ""
    echo "Failure 1: loop1 (member of mirror pair 1)"
    echo "  Action: Automatic failover to hot spare loop5"
    echo "  Rebuild time: $(mdadm --detail /dev/md0 | grep 'Events' | awk '{print $2}')"
    echo "  Spare consumed: Yes (loop5 now active)"
    echo ""
    echo "Failure 2: loop3 (member of mirror pair 2)"
    echo "  Action: Automatic failover to hot spare loop6"
    echo "  Spare consumed: Yes (loop6 now active)"
    echo ""
    echo "Current array status:"
    mdadm --detail /dev/md0 | grep -E "Raid|Total|Active|Failed|Spare|State"
    echo ""
    echo "Data integrity: VERIFIED (all checksums match)"
    echo "====================================="
} > /root/raid_recovery_report.txt

echo "Recovery report saved to /root/raid_recovery_report.txt"
cat /root/raid_recovery_report.txt

# ──────────────────────────────────────────────
# CLEANUP — Remove all practice artifacts
# ──────────────────────────────────────────────
# In a real scenario, skip this — but for practice:
echo "=== CLEANUP ==="
umount /mnt/prod/database /mnt/prod/web /mnt/prod/logs /mnt/prod/backup
lvremove -f vg_prod
vgremove vg_prod
pvremove /dev/md0
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4 /dev/loop5 /dev/loop6

for i in {1..6}; do
    losetup -d /dev/loop$i
    rm -f /tmp/prod_disk$i.img
done
rm -f /tmp/prod_checksums.txt /root/raid_recovery_report.txt
echo "=== All practice artifacts cleaned up ==="
```





[← Previous](16-section-12-comparing-raid-levels.md) | [↑ Index](index.md) | [Next →](18-level-3-deep-understanding-how.md)
