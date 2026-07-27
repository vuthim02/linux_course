## 💻 PRACTICE SECTION — 15 Hands-On Exercises

---

### Level 1 Practices: LVM Fundamentals

---

### ✅ Practice 1: Create PVs, VG, and LV

```bash
mkdir -p ~/linux-course/part31 && cd ~/linux-course/part31

# Create 3 virtual disks
for i in 1 2 3; do dd if=/dev/zero of=disk$i.img bs=1M count=500; done
LOOP1=$(sudo losetup --show -fP disk1.img)
LOOP2=$(sudo losetup --show -fP disk2.img)
LOOP3=$(sudo losetup --show -fP disk3.img)

# PVs
sudo pvcreate $LOOP1 $LOOP2 $LOOP3
sudo pvs

# VG
sudo vgcreate vg_lab $LOOP1 $LOOP2
sudo vgs

# LV
sudo lvcreate -L 400M -n lv_first vg_lab
sudo lvs
ls -la /dev/vg_lab/lv_first
```

---

### ✅ Practice 2: Extend an LV

```bash
cd ~/linux-course/part31
sudo mkfs.ext4 /dev/vg_lab/lv_first
sudo mkdir -p /mnt/lv_first
sudo mount /dev/vg_lab/lv_first /mnt/lv_first
df -h /mnt/lv_first

sudo lvextend -L +200M /dev/vg_lab/lv_first
sudo resize2fs /dev/vg_lab/lv_first
df -h /mnt/lv_first

sudo umount /mnt/lv_first
```

---

### ✅ Practice 3: Reduce an LV

```bash
cd ~/linux-course/part31
sudo lvcreate -L 300M -n lv_shrink vg_lab
sudo mkfs.ext4 /dev/vg_lab/lv_shrink
sudo mount /dev/vg_lab/lv_shrink /mnt/lv_shrink
dd if=/dev/urandom of=/mnt/lv_shrink/fill.dat bs=1M count=50 2>/dev/null

# Shrink
sudo umount /mnt/lv_shrink
sudo e2fsck -f /dev/vg_lab/lv_shrink
sudo resize2fs /dev/vg_lab/lv_shrink 200M
sudo lvreduce -L 200M /dev/vg_lab/lv_shrink
sudo mount /dev/vg_lab/lv_shrink /mnt/lv_shrink
df -h /mnt/lv_shrink

sudo umount /mnt/lv_shrink
sudo lvremove -f vg_lab/lv_shrink
```

---

### Level 2 Practices: Snapshots, Thin Provisioning, Cache

---

### ✅ Practice 4: Snapshot and Rollback

```bash
cd ~/linux-course/part31
sudo lvcreate -L 200M -n lv_origin vg_lab
sudo mkfs.ext4 /dev/vg_lab/lv_origin
sudo mount /dev/vg_lab/lv_origin /mnt/lv_origin
echo "ORIGINAL DATA - version 1" > /mnt/lv_origin/important.txt

# Snapshot
sudo lvcreate -s -L 50M -n lv_snap /dev/vg_lab/lv_origin

# Modify origin
echo "MODIFIED DATA - version 2" > /mnt/lv_origin/important.txt

# Mount snapshot
sudo mkdir -p /mnt/lv_snap
sudo mount -o ro /dev/vg_lab/lv_snap /mnt/lv_snap
cat /mnt/lv_snap/important.txt  # Shows version 1

# Rollback
sudo umount /mnt/lv_origin /mnt/lv_snap
sudo lvconvert --merge /dev/vg_lab/lv_snap
sudo mount /dev/vg_lab/lv_origin /mnt/lv_origin
cat /mnt/lv_origin/important.txt  # Back to version 1

sudo umount /mnt/lv_origin
sudo lvremove -f vg_lab/lv_origin
```

---

### ✅ Practice 5: Thin Pool and Thin LV

```bash
cd ~/linux-course/part31
sudo lvcreate --type thin-pool -L 300M -n thin_pool vg_lab
lvs -a vg_lab -o lv_name,seg_type,lv_size

sudo lvcreate --type thin -V 1G -n thin_lv_1 vg_lab/thin_pool
sudo lvcreate --type thin -V 2G -n thin_lv_2 vg_lab/thin_pool
lvs vg_lab -o lv_name,lv_size,data_percent,pool_lv

sudo mkfs.ext4 /dev/vg_lab/thin_lv_1
sudo mkfs.ext4 /dev/vg_lab/thin_lv_2
sudo mount /dev/vg_lab/thin_lv_1 /mnt/thin1
sudo mount /dev/vg_lab/thin_lv_2 /mnt/thin2

lvs vg_lab/thin_pool -o +data_percent,metadata_percent

sudo umount /mnt/thin1 /mnt/thin2
sudo lvremove -f vg_lab/thin_lv_1 vg_lab/thin_lv_2 vg_lab/thin_pool
```

---

### ✅ Practice 6: Thin Snapshots

```bash
cd ~/linux-course/part31
sudo lvcreate --type thin-pool -L 500M -n pool vg_lab
sudo lvcreate --type thin -V 500M -n thin_orig vg_lab/pool
sudo mkfs.ext4 /dev/vg_lab/thin_orig
sudo mount /dev/vg_lab/thin_orig /mnt/thin_orig
echo "Original content" > /mnt/thin_orig/data.txt

# Thin snapshots are instant — no separate COW store sizing needed
sudo lvcreate -s -n thin_snap vg_lab/thin_orig
sudo mount -o ro /dev/vg_lab/thin_snap /mnt/thin_snap
cat /mnt/thin_snap/data.txt

echo "Modified!" > /mnt/thin_orig/data.txt
cat /mnt/thin_snap/data.txt  # Still "Original content"

sudo umount /mnt/thin_orig /mnt/thin_snap
sudo lvremove -f vg_lab/thin_orig vg_lab/thin_snap vg_lab/pool
```

---

### ✅ Practice 7: LVM Cache

```bash
cd ~/linux-course/part31
dd if=/dev/zero of=slow.img bs=1M count=400
dd if=/dev/zero of=fast.img bs=1M count=100
SLOW=$(sudo losetup --show -fP slow.img)
FAST=$(sudo losetup --show -fP fast.img)
sudo pvcreate $SLOW $FAST
sudo vgcreate vg_cache $SLOW $FAST

# Create origin + cache
sudo lvcreate -L 300M -n lv_slow vg_cache $SLOW
sudo lvcreate -L 50M -n lv_fast vg_cache $FAST
sudo lvconvert --type cache --cachepool vg_cache/lv_fast vg_cache/lv_slow

lvs -a vg_cache -o lv_name,size,pool_lv,cache_mode,cache_read_hits,cache_read_misses

# Test performance
sudo mkfs.ext4 /dev/vg_cache/lv_slow
sudo mount /dev/vg_cache/lv_slow /mnt/cache_test
time dd if=/dev/zero of=/mnt/cache_test/test bs=4K count=2000

# Switch to writeback
sudo lvchange --cachemode writeback vg_cache/lv_slow

sudo umount /mnt/cache_test
sudo lvconvert --splitcache vg_cache/lv_slow
sudo lvremove -f vg_cache/lv_slow vg_cache/lv_fast
sudo vgremove -f vg_cache && sudo pvremove $SLOW $FAST
sudo losetup -d $SLOW $FAST && rm -f slow.img fast.img
```

---

### ✅ Practice 8: Striped LV

```bash
cd ~/linux-course/part31
dd if=/dev/zero of=disk4.img bs=1M count=500
LOOP4=$(sudo losetup --show -fP disk4.img)
sudo pvcreate $LOOP4
sudo vgextend vg_lab $LOOP4

# 4-way stripe
sudo lvcreate --type striped -i 4 -I 64 -L 800M -n lv_stripe vg_lab
lvs -a -o lv_name,seg_type,stripes,stripe_size,devices

sudo mkfs.ext4 -E stride=16,stripe_width=64 /dev/vg_lab/lv_stripe
sudo mount /dev/vg_lab/lv_stripe /mnt/stripe
time dd if=/dev/zero of=/mnt/stripe/test bs=1M count=200 2>&1

sudo umount /mnt/stripe
sudo lvremove -f vg_lab/lv_stripe
```

---

### Level 3 Practices: RAID, Recovery, and Integration

---

### ✅ Practice 9: LVM RAID 1

```bash
cd ~/linux-course/part31
sudo lvcreate --type raid1 -m 1 -L 200M -n lv_mirror vg_lab
lvs -a vg_lab -o lv_name,seg_type,devices,raid_sync_action,sync_percent
lvs -a vg_lab  # Shows rimage_0, rmage_1, rmeta_0, rmeta_1

sudo mkfs.ext4 /dev/vg_lab/lv_mirror
sudo mount /dev/vg_lab/lv_mirror /mnt/mirror
echo "Mirror test" > /mnt/mirror/data.txt

sudo umount /mnt/mirror
sudo lvremove -f vg_lab/lv_mirror
```

---

### ✅ Practice 10: LVM RAID 5

```bash
cd ~/linux-course/part31
sudo lvcreate --type raid5 -i 3 -L 600M -n lv_raid5 vg_lab
lvs -a -o lv_name,seg_type,stripes,devices,sync_percent

sudo mkfs.ext4 /dev/vg_lab/lv_raid5
sudo mount /dev/vg_lab/lv_raid5 /mnt/raid5
df -h /mnt/raid5

sudo umount /mnt/raid5
sudo lvremove -f vg_lab/lv_raid5
```

---

### ✅ Practice 11: Missing PV Recovery

```bash
cd ~/linux-course/part31
sudo lvcreate -L 100M -n lv_recover vg_lab

# Simulate PV failure
DETACH="$LOOP3"
sudo vgchange -an vg_lab
sudo losetup -d $DETACH

# Attempt activation (fails without --partial)
sudo vgchange -ay vg_lab 2>&1 || echo "Expected failure — PV missing"
sudo vgchange -ay --partial vg_lab 2>&1 || true

# Re-attach
sudo losetup $DETACH disk3.img
sudo pvscan && sudo vgchange -ay vg_lab

sudo mount /dev/vg_lab/lv_recover /mnt/recover
echo "Recovered!" | sudo tee /mnt/recover/recovered.txt
sudo umount /mnt/recover
sudo lvremove -f vg_lab/lv_recover
```

---

### ✅ Practice 12: Metadata Backup and Restore

```bash
cd ~/linux-course/part31
ls -la /etc/lvm/backup/vg_lab
ls -la /etc/lvm/archive/
sudo head -50 /etc/lvm/backup/vg_lab

sudo lvcreate -L 50M -n lv_meta vg_lab
sudo lvcreate -L 50M -n lv_meta2 vg_lab
sudo vgcfgrestore -l vg_lab  # List versions

# Simulate checking a restore (dry-run)
sudo vgcfgrestore -t -f /etc/lvm/archive/vg_lab_00001.vg vg_lab 2>&1 || true

sudo lvremove -f vg_lab/lv_meta vg_lab/lv_meta2
```

---

### ✅ Practice 13: lvm.conf Filters

```bash
cd ~/linux-course/part31
sudo grep -A5 '^devices {' /etc/lvm/lvm.conf | grep -E 'filter|global_filter'

# Test filter that excludes loop devices (without modifying config)
sudo pvs --config 'devices { filter = [ "r|loop.*|", "a|.*|" ] }'
echo "Loop devices should be hidden above"
sudo pvs  # All devices visible
```

---

### ✅ Practice 14: pvck and dmsetup

```bash
cd ~/linux-course/part31
sudo pvck $LOOP1 $LOOP2 $LOOP3
sudo pvck --dump $LOOP1 | head -30

sudo dmsetup ls --tree
sudo dmsetup table
sudo dmsetup table vg_lab-lv_first
sudo dmsetup deps vg_lab-lv_first
sudo dmsetup info -c | head -5
```

---

### ✅ Practice 15: Real-World Integration — Multi-Disk Thin Pool + Snapshot + RAID

```bash
cd ~/linux-course/part31

# 6 virtual disks
for i in $(seq 1 6); do dd if=/dev/zero of=int_disk$i.img bs=1M count=500; done
LOOPS=""
for i in $(seq 1 6); do LOOPS="$LOOPS $(sudo losetup --show -fP int_disk$i.img)"; done

# PVs + VG
sudo pvcreate $LOOPS && sudo vgcreate vg_prod $LOOPS

# RAID 5 on 4 disks as storage pool
sudo lvcreate --type raid5 -i 4 -L 1600M -n lv_pool vg_prod

# Convert to thin pool
sudo lvconvert --type thin-pool vg_prod/lv_pool

# Thin LVs
sudo lvcreate --type thin -V 500M -n thin_app vg_prod/lv_pool
sudo lvcreate --type thin -V 500M -n thin_data vg_prod/lv_pool
sudo lvcreate --type thin -V 500M -n thin_logs vg_prod/lv_pool

# Format and mount
sudo mkfs.ext4 /dev/vg_prod/thin_app
sudo mkfs.ext4 /dev/vg_prod/thin_data
sudo mkfs.ext4 /dev/vg_prod/thin_logs
sudo mkdir -p /mnt/integration/{app,data,logs}
sudo mount /dev/vg_prod/thin_app /mnt/integration/app
sudo mount /dev/vg_prod/thin_data /mnt/integration/data
sudo mount /dev/vg_prod/thin_logs /mnt/integration/logs

echo "Config v1" > /mnt/integration/app/config.txt
dd if=/dev/urandom of=/mnt/integration/data/userdata.dat bs=1K count=1024

# Snapshots
sudo lvcreate -s -n snap_app vg_prod/thin_app
sudo lvcreate -s -n snap_data vg_prod/thin_data

# Modify originals
echo "Config v2" > /mnt/integration/app/config.txt
echo "more data" >> /mnt/integration/data/userdata.dat

# Mount snapshots to verify
sudo mkdir -p /mnt/int_snap/{app,data}
sudo mount -o ro /dev/vg_prod/snap_app /mnt/int_snap/app
sudo mount -o ro /dev/vg_prod/snap_data /mnt/int_snap/data

echo "=== CURRENT vs SNAPSHOT ==="
cat /mnt/integration/app/config.txt
cat /mnt/int_snap/app/config.txt

# Status overview
echo "" && echo "=== PVs ===" && pvs
echo "=== VGs ===" && vgs vg_prod
echo "=== LVs ===" && lvs -a vg_prod -o lv_name,lv_size,data_percent,origin,pool_lv
echo "=== RAID ===" && lvs -a vg_prod -o +raid_sync_action,sync_percent
echo "=== DM TREE ===" && sudo dmsetup ls | grep vg_prod

# Cleanup
sudo umount /mnt/int_snap/app /mnt/int_snap/data
sudo umount /mnt/integration/app /mnt/integration/data /mnt/integration/logs
sudo lvremove -f vg_prod/snap_app vg_prod/snap_data vg_prod/thin_app vg_prod/thin_data vg_prod/thin_logs
sudo lvremove -f vg_prod/lv_pool
sudo vgremove -f vg_prod && sudo pvremove $LOOPS
sudo losetup -d $LOOPS
rm -f int_disk*.img

echo "Integration practice complete!"
```

---



---

[← Previous](20-deep-understanding-how-lvm-really.md) | [↑ Index](index.md) | [Next →](22-summary-complete-command-reference-for.md)
