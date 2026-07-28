## 🔍 Section 3: Creating RAID Arrays with mdadm

### Prerequisites — Setting Up Loopback Devices

You do not need real spare hard drives to learn RAID. Linux loopback devices let you use files as block devices. This means you can create virtual disks for RAID practice on any system:

```bash
# Create 4 virtual disk files (100 MiB each)
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
done

# Attach them to loopback devices
for i in {1..4}; do
    losetup /dev/loop$i /tmp/disk$i.img
done

# Verify
lsblk | grep loop
```

Output:
```
loop0   7:0    0   100M  0 loop
loop1   7:1    0   100M  0 loop
loop2   7:2    0   100M  0 loop
loop3   7:3    0   100M  0 loop
```

### Creating a RAID 0 Array

```bash
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/loop1 /dev/loop2
```

Flags explained:
- `--create`: Build a new array (use `--build` only for RAID 0/1 without superblocks — never do this)
- `--level=0`: RAID level
- `--raid-devices=2`: Number of active disks in the array
- `/dev/loop1 /dev/loop2`: The component devices

After creation, check the result:

```bash
cat /proc/mdstat
```

Output:
```
Personalities : [raid0]
md0 : active raid0 loop2[1] loop1[0]
      208896 blocks super 1.2 512k chunks

unused devices: <none>
```

### Creating RAID 1, 5, 6, 10

```bash
# RAID 1 — minimum 2 devices
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/loop1 /dev/loop2

# RAID 5 — minimum 3 devices
mdadm --create /dev/md5 --level=5 --raid-devices=3 /dev/loop1 /dev/loop2 /dev/loop3

# RAID 6 — minimum 4 devices
mdadm --create /dev/md6 --level=6 --raid-devices=4 /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4

# RAID 10 — minimum 4 devices
mdadm --create /dev/md10 --level=10 --raid-devices=4 /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4
```

### The Initial Resync (Background Sync)

When you create a RAID 1, 5, 6, or 10 array, the kernel immediately starts a "resync" — it reads all the drives and rebuilds parity/mirror consistency. For RAID 5/6, this initializes all parity blocks. For RAID 1, it copies data between mirrors.

You can watch this happen:

```bash
watch -n 1 cat /proc/mdstat
```

You will see the resync percentage and speed:
```
md0 : active raid5 loop4[4] loop3[3] loop2[1] loop1[0]
      313344 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [UU_U]
      [=>...................]  resync =  7.2% (23456/313344) finish=0.3min speed=11728K/sec
```

### Configuring /etc/mdadm/mdadm.conf

For persistent arrays that survive reboots, you must create a configuration file:

```bash
# Discover arrays and generate config
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

# Or more carefully — redirect properly
mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf

# Update initramfs so the arrays assemble at boot
update-initramfs -u
```

On Red Hat-family systems:
```bash
grubby --update-kernel=ALL --args="raid=noautodetect"
# Or just let it auto-assemble
dracut --force
```

### ARRAY Lines in mdadm.conf

The configuration file contains lines like:

```
ARRAY /dev/md0 metadata=1.2 UUID=3f0d6e7a:8b1c2d3e:4f5a6b7c:8d9e0f1a name=host:0
ARRAY /dev/md1 metadata=1.2 UUID=a1b2c3d4:e5f6a7b8:c9d0e1f2:a3b4c5d6 name=host:1
```

This tells mdadm exactly which drives belong to which array by UUID. The alternative is auto-assembly, which the kernel does by scanning all drives for superblocks.





[← Previous](04-section-2-mdadm-the-linux.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-daily-raid.md)
