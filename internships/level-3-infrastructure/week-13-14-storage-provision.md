# Internship — Level 3, Week 13-14
## Storage Provisioning Toolkit

### Real-World Scenario

A new database server arrives with 4x 2TB NVMe drives. The senior admin is on leave. You need to provision the storage: configure RAID for redundancy, set up LVM for flexibility, create the filesystem, and mount it. Build a tool that automates this so anyone on the team can provision a new server in minutes.

### Requirements

Write `/usr/local/bin/storage-provision.sh` that automates disk provisioning.

#### Phase 1: Disk Discovery

```bash
./storage-provision.sh --detect
```

Output:
```
Available disks:
  NAME    SIZE  TYPE  MODEL                SYSTEM
  sda     250G  disk  SYSTEM_SSD           [system - skip]
  sdb     2.0T  disk  NVMe_Data_01         [available]
  sdc     2.0T  disk  NVMe_Data_02         [available]
  sdd     2.0T  disk  NVMe_Data_03         [available]
  sde     2.0T  disk  NVMe_Data_04         [available]
```

- Detect system disk (contains `/`) and exclude it
- Detect existing RAID/LVM members and warn before re-use

#### Phase 2: Interactive RAID Setup

```bash
./storage-provision.sh --setup
```

Interactive menu:
```
Select RAID level:
  1) RAID 0 — striping (performance, no redundancy)
  2) RAID 1 — mirroring (redundancy, 50% capacity)
  3) RAID 5 — striping with parity (N-1 capacity)
  4) RAID 6 — striping with double parity (N-2 capacity)
  5) RAID 10 — stripe of mirrors (performance + redundancy)
  6) None — use disks individually (JBOD)

Select disks (space separated): sdb sdc sdd sde
Hot spare (optional): sdf
Chunk size (KB) [default 512]:
```

#### Phase 3: LVM on RAID

After RAID creation, configure LVM automatically:

```bash
./storage-provision.sh --setup --raid /dev/md0
```

```
RAID device: /dev/md0 (6.0 TB, RAID 10)
Create LVM on this device?
  Volume Group name [vg_data]:
  Logical Volume name [lv_data]:
  Size (e.g. 500G, 100%, free): 100%
  Filesystem type [ext4]: xfs
  Mount point [/mnt/data]:
```

Creates: PV → VG → LV → mkfs → mount → /etc/fstab entry

#### Phase 4: Non-Interactive Mode (for automation)

```bash
./storage-provision.sh --auto \
  --raid-level 10 \
  --disks sdb,sdc,sdd,sde \
  --hot-spare sdf \
  --vg-name vg_data \
  --lv-name lv_data \
  --lv-size 100% \
  --fstype xfs \
  --mount /mnt/data
```

#### Phase 5: Status and Health

```bash
./storage-provision.sh --status
```

Output:
```
Storage Status — 2026-06-24
RAID Arrays:
  /dev/md0: RAID 10, 4 active, 1 spare, 6.0 TB, [UUUU_]  ← degraded!
  /dev/md1: RAID 1, 2 active, 0 spare, 250 GB, [UU]

LVM:
  vg_data (6.0 TB): /dev/md0
    lv_data (5.8 TB): /mnt/data, xfs, 23% used
  vg_system (250 GB): /dev/md1
    lv_root (100 GB): /, ext4, 45% used

Mounts:
  /mnt/data -> /dev/vg_data/lv_data (xfs, rw, noatime)
```

#### Error Handling

- Verify disk count matches RAID level requirements (RAID 5 needs ≥3, RAID 10 needs ≥4 and even)
- Check for existing partitions/RAID on selected disks (ask before overwrite)
- Verify /etc/fstab entry works: `mount -a` after adding entry
- Log everything to `/var/log/storage-provision.log`

### Validation

```bash
# Use loop devices for testing (no real disks needed)
sudo modprobe loop
for i in {1..4}; do
  dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
  sudo losetup /dev/loop$i /tmp/disk$i.img
done

# Run setup on loop devices
sudo ./storage-provision.sh --auto --raid-level 1 --disks /dev/loop1,/dev/loop2 \
  --vg-name vg_test --lv-name lv_test --lv-size 100% --fstype ext4 --mount /mnt/test

# Verify
mount | grep /mnt/test
df -h /mnt/test
cat /proc/mdstat
sudo pvs && sudo vgs && sudo lvs

# Cleanup
sudo umount /mnt/test
sudo lvremove -f vg_test/lv_test
sudo vgremove vg_test
for i in {1..4}; do sudo losetup -d /dev/loop$i; done
```

### Deliverables

- `~/internship/storage-provision.sh`
- `~/internship/storage-status.sh` (the --status functionality)
- `~/internship/storage-provision.conf` — default configuration
- `~/internship/test-output.txt` — test run on loop devices

### Hints

- Use `lsblk -dno NAME,SIZE,TYPE,MODEL` for disk discovery
- `mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde --spare-devices=1 /dev/sdf`
- `grep -v "$(df / | tail -1 | awk '{print $1}')"` to exclude system disk — but clean this up to use `lsblk -o MOUNTPOINT`
- For loop device testing: `losetup -fP /tmp/disk1.img`
- `mountpoint -q /mnt/data && echo "mounted" || echo "not mounted"`
