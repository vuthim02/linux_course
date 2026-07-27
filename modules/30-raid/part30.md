# 🐧 Linux System Administrator — Complete Course
## Part 30 of ∞: RAID — Redundant Array of Independent Disks

---

> **Reverse Engineering Approach:** In 1987, David Patterson, Garth Gibson, and Randy Katz at UC Berkeley published a paper titled "A Case for Redundant Arrays of Inexpensive Disks (RAID)" — which they later changed to "Independent" because vendors wanted to sell expensive drives. The original insight was that you could take cheap consumer hard drives, strap them together, and get better performance and/or reliability than a single expensive "enterprise" drive. Thirty-five years later, RAID is everywhere — from the md driver in the Linux kernel to enterprise megaraid controllers. We will learn RAID the only way that sticks: by breaking it, fixing it, and measuring it ourselves.

---

## 🎯 What You Will Achieve in Part 30

This part is organized into **three progressive levels:**

| Level | You Will Learn |
|-------|---------------|
| **⭐ Basic** (Level 1) | What RAID is, RAID levels 0/1/5/6/10, software vs hardware RAID, creating your first arrays with `mdadm` |
| **⭐ Intermediary** (Level 2) | Managing arrays, hot spares, failure recovery, parity math, RAID 10 layouts, monitoring, RAID + LVM |
| **⭐ Advanced** (Level 3) | Hardware RAID controllers, md driver internals, XOR parity deep-dive, superblock formats, chunk tuning, performance benchmarking |

By the end, you will complete **15 hands-on practices** spanning all three levels.

---

## ⭐ Level 1: Basic — RAID Fundamentals

![RAID levels comparison — striping, mirroring, parity explained](https://i.pinimg.com/736x/0e/95/cb/0e95cba62afcd7b1c917b45ae24ff761.jpg)

*RAID types overview — from basic striping to hybrid RAID 10 (Sony Camera Central / Pinterest)*

> **Level 1 Goal:** Understand what RAID is, the differences between RAID levels 0/1/5/6/10, and how to create your first RAID array with `mdadm`.

---

## 🔍 Section 1: What Is RAID — How It Really Works

### The Core Problem

Hard drives fail. It is not a question of *if* but *when*. The annual failure rate (AFR) of consumer hard drives is typically 2-5%, meaning in a server with 20 drives, you expect one failure per year or sooner. RAID solves two separate problems:

1. **Reliability** — survive a drive failure without losing data
2. **Performance** — combine multiple drives for faster reads/writes

### The Three Building Blocks

RAID is built from exactly three techniques, combined in different ways:

| Technique | What It Does | Cost |
|-----------|-------------|------|
| **Striping** | Splits data across drives (like interleaving) | No redundancy, all drives needed |
| **Mirroring** | Duplicates data across drives | 50% capacity loss |
| **Parity** | Stores mathematical checksums | 1/N capacity loss (N=drives) |

### RAID 0 — Striping (Performance, No Redundancy)

```
Data blocks: A B C D E F G H

           [Disk 1]   [Disk 2]
             A          B
             C          D
             E          F
             G          H
```

Read from Disk 1: A C E G
Read from Disk 2: B D F H

Two drives = double the read/write speed (theoretically). But if either drive dies, ALL data is lost. RAID 0 has no redundancy — the "0" means zero protection.

### RAID 1 — Mirroring (Redundancy, No Performance Gain for Writes)

```
           [Disk 1]   [Disk 2]
             A          A
             B          B
             C          C
             D          D
```

Every write goes to both drives. Reads can be served from either drive (load balancing). Effective capacity = 1 drive's worth. Survives 1 drive failure.

### RAID 5 — Striping with Distributed Parity

```
           [Disk 1]   [Disk 2]   [Disk 3]
             A          B       p(A,B)
             C        p(C,D)      D
           p(E,F)       E          F
```

Parity blocks are distributed across all drives. If one drive fails, the missing data can be reconstructed by XORing the remaining drives. Effective capacity = N-1 drives. Requires minimum 3 drives. Write penalty: every write needs 4 I/Os (read old data, read old parity, write new data, write new parity).

### RAID 6 — Striping with Double Parity

```
           [Disk 1]   [Disk 2]   [Disk 3]   [Disk 4]
             A          B        p(A,B)     q(A,B)
             C        p(C,D)      D          q(C,D)
           p(E,F)     q(E,F)      E           F
```

Two independent parity blocks per stripe. Can survive 2 simultaneous drive failures. Minimum 4 drives. Capacity = N-2 drives. Uses Reed-Solomon codes for the second parity (more on this in Deep Understanding).

### RAID 10 (1+0) — Stripe of Mirrors

```
           [Mirror 1]          [Mirror 2]
           [Disk 1] [Disk 2]   [Disk 3] [Disk 4]
             A        A          B         B
             C        C          D         D
             E        E          F         F
             G        G          H         H
```

RAID 10 is NOT RAID 0+1. RAID 10: first mirror, then stripe. RAID 0+1: first stripe, then mirror. RAID 10 is superior because it can survive multiple failures as long as no single mirror loses both disks. Minimum 4 drives. Capacity = N/2 drives. Best performance for databases and high-write workloads.

### Hardware RAID vs Software RAID

| Aspect | Hardware RAID | Software RAID (md) |
|--------|---------------|-------------------|
| CPU usage | Offloaded to RAID controller | Uses host CPU |
| Cost | $200-$2000+ | Free (kernel built-in) |
| Boot support | Native (BIOS sees the array) | Needs initramfs |
| OS dependency | Works before OS loads | Kernel module (md_mod) |
| Cache | Battery-backed cache (BBU) | System RAM |
| Portability | Tied to controller model | Portable across Linux systems |
| Features | Hot-swap bays, dedicated LEDs | Flexible, scriptable |

### The md Driver in Linux

Linux software RAID is implemented by the `md` (Multiple Device) driver in the kernel. It is a block layer driver that sits between the filesystem and the physical block devices:

```
Filesystem (ext4, xfs, btrfs)
        │
   md device (/dev/md0)
        │
   md driver (kernel)
        │
   ┌────┼────┐
  sda  sdb  sdc  (physical disks or partitions)
```

The md driver exposes `/dev/mdX` devices that work like any block device. The kernel handles all the striping, mirroring, and parity calculations transparently.

---

## 🔍 Section 2: mdadm — The Linux Software RAID Tool

### What is mdadm?

`mdadm` is the userspace tool that controls the kernel md driver. Think of it as the control panel for RAID. It can:
- Create arrays (`mdadm --create`)
- Assemble existing arrays (`mdadm --assemble`)
- Manage drives (`mdadm --add`, `--remove`, `--fail`)
- Monitor status (`mdadm --monitor`, `--detail`)
- Grow/resize arrays (`mdadm --grow`)

### Understanding mdadm Modes

mdadm operates in several modes. Every command uses exactly one mode:

| Mode | Flag | Purpose |
|------|------|---------|
| Create | `--create` | Build a new array |
| Assemble | `--assemble` | Bring existing array online |
| Manage | `--add`, `--remove`, `--fail` | Hot-modify an array |
| Monitor | `--monitor` | Watch for failures |
| Grow | `--grow` | Change array parameters |
| Incremental Assembly | `--incremental` | Auto-detect and add drives |
| Misc | `--detail`, `--query`, `--stop` | Informational and control |

### The md Superblock

Every drive in a Linux software RAID array has an md superblock — metadata written to the drive that tells the kernel:
- Which array this drive belongs to (UUID)
- What RAID level, chunk size, layout
- The role of this drive in the array
- The event count (essential for resync detection)

Superblock formats:

| Format | Location | Max Device Size | Max Array Size | Features |
|--------|----------|----------------|----------------|----------|
| 0.90 | Last 2 sectors of device | 2 TiB | 2 TiB | Legacy, no UUID |
| 1.0 | Last 4 KiB of device | Unlimited | Unlimited | At end, OS can boot |
| 1.1 | First 4 KiB of device | Unlimited | Unlimited | At beginning (default) |
| 1.2 | 4 KiB from start of device | Unlimited | Unlimited | Most common default |

Modern Linux uses superblock 1.2 by default. The superblock contains the entire array configuration, which is why you can stop an array, move the drives to another Linux system, and `mdadm --assemble --scan` will find and reconstruct the array automatically.

---

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

---

## ⭐ Level 2: Intermediary — Daily RAID Management

![mdadm RAID monitoring and disk failure recovery workflow](https://thelinuxclub.com/wp-content/uploads/2025/03/RAID-recovery-768x461.png)

*Monitoring disk health, identifying failed drives, and rebuilding arrays with mdadm (The Linux Club)*

> **Level 2 Goal:** Manage RAID arrays in production — add/remove drives, configure hot spares, handle failures, monitor health, and integrate with LVM.

---

## 🔍 Section 4: Managing RAID Arrays

### /proc/mdstat — Your First Health Check

The file `/proc/mdstat` is the single most important tool for RAID monitoring. It is a virtual file created by the kernel md driver in real time:

```bash
cat /proc/mdstat
```

```
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid5 sdd[3] sdc[2] sdb[1] sda[0]
      5860545024 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]
      
md1 : active raid1 sde[0] sdf[1]
      976762584 blocks super 1.2 [2/2] [UU]

unused devices: <none>
```

Reading this output:
- `[4/4]` = 4 devices out of 4 are active
- `[UUUU]` = all devices are Up (U = up, _ = failed/removed)
- `raid5` = level 5
- `512k chunk` = stripe size

### mdadm --detail

For comprehensive status of an array:

```bash
mdadm --detail /dev/md0
```

```
/dev/md0:
           Version : 1.2
     Creation Time : Tue Jun 16 14:23:45 2026
        Raid Level : raid5
        Array Size : 5860545024 (5589.34 GiB 6001.89 GB)
     Used Dev Size : 1953515008 (1863.11 GiB 2000.41 GB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Tue Jun 23 16:30:12 2026
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : server:0
              UUID : 3f0d6e7a:8b1c2d3e:4f5a6b7c:8d9e0f1a
            Events : 2478

    Number   Major   Minor   RaidDevice State
       0       8        0        0      active sync   /dev/sda
       1       8       16        1      active sync   /dev/sdb
       2       8       32        2      active sync   /dev/sdc
       3       8       48        3      active sync   /dev/sdd
```

### mdadm --query

Quick check on any block device:

```bash
mdadm --query /dev/sda
/dev/sda: is an md component device, part of /dev/md0

mdadm --query /dev/md0
/dev/md0: is an md array
```

### Adding and Removing Drives

```bash
# Add a drive to an existing array (expands capacity for RAID 1/5/6 if supported)
mdadm --add /dev/md0 /dev/sde

# Remove a drive from an array (must be failed or spare)
mdadm --remove /dev/md0 /dev/sde

# Mark a drive as failed
mdadm --fail /dev/md0 /dev/sdb
```

### Stopping and Starting Arrays

```bash
# Stop an array
mdadm --stop /dev/md0

# Start/assemble an array
mdadm --assemble /dev/md0 /dev/sda /dev/sdb /dev/sdc /dev/sdd
# Or scan for all arrays
mdadm --assemble --scan
```

### Resync Speed Control

The kernel resync can be throttled. These files control the speed:

```bash
# Check current limits
cat /proc/sys/dev/raid/speed_limit_min
cat /proc/sys/dev/raid/speed_limit_max

# Set minimum resync speed (KB/sec)
echo 10000 > /proc/sys/dev/raid/speed_limit_min

# Set maximum resync speed (KB/sec)
echo 200000 > /proc/sys/dev/raid/speed_limit_max
```

Typical values: min=1000 (1 MB/s), max=200000 (200 MB/s). Lower max during production hours to minimize performance impact; raise it during maintenance windows.

---

## 🔍 Section 5: Spare Disks — Hot Spares

### The Hot Spare Concept

A hot spare is a drive that sits in the array doing nothing — until a real drive fails. When the array detects a failure, it automatically replaces the failed drive with the spare and starts rebuilding. This minimizes the window of vulnerability.

### Adding a Hot Spare

```bash
# Create an array with an explicit spare count
mdadm --create /dev/md0 --level=5 --raid-devices=3 \
    --spare-devices=1 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Or add a spare to an existing array
mdadm --add /dev/md0 /dev/sdd
```

After adding a spare, `mdadm --detail` will show:
```
    Spare Devices : 1

    Number   Major   Minor   RaidDevice State
       0       8        0        0      active sync   /dev/sda
       1       8       16        1      active sync   /dev/sdb
       2       8       32        2      active sync   /dev/sdc
       3       8       48        -      spare   /dev/sdd
```

The key difference: a spare has `RaidDevice` set to `-` (dash) — it is not an active part of the array. It just waits.

### Automatic Rebuild with Hot Spare

When a drive fails:

```bash
mdadm --fail /dev/md0 /dev/sdb
```

The kernel immediately:
1. Marks `/dev/sdb` as failed
2. Removes it from the active set
3. Takes the hot spare (`/dev/sdd`) and starts rebuilding parity onto it
4. `/proc/mdstat` shows the rebuild in progress

### Spare Groups

For systems with multiple arrays, you can define spare groups so that a single spare drive can protect multiple arrays:

```bash
mdadm --create /dev/md0 --level=1 --raid-devices=2 \
    --spare-group=pool1 /dev/sda /dev/sdb

mdadm --create /dev/md1 --level=1 --raid-devices=2 \
    --spare-group=pool1 /dev/sdc /dev/sdd

# Add a shared spare
mdadm --add /dev/md0 /dev/sde
mdadm --spare-group /dev/md0 pool1
```

Note: spare groups cannot be set via `--spare-group` on array creation. The mechanism uses `mdadm --spare-group` to assign a spare to a group, and any array in that group can claim it:

```bash
# Mark a spare drive as belonging to a group
mdadm --spare-group pool1 /dev/md0 /dev/sde

# Actually spare groups are set in mdadm.conf:
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
# Then edit to add spare-group=pool1 to the ARRAY lines
```

When any array in `pool1` loses a drive, the kernel takes the spare from the group and starts rebuilding.

### Global Spares

A spare not assigned to any group becomes a global spare — it can be used by any array on the system:

```bash
# Just add a spare without specifying a group
mdadm --add /dev/md0 /dev/sde
# This spare is available to /dev/md0 automatically
# To make it available to all arrays, add it to each array:
mdadm --add /dev/md1 /dev/sde
```

---

## 🔍 Section 6: RAID 5/6 Parity — The Write Hole

### How RAID 5 Parity Works: XOR

RAID 5 uses the XOR (exclusive or) operation to compute parity. XOR has a critical property: it is reversible.

```
XOR truth table:
A ⊕ B = P
0 ⊕ 0 = 0
0 ⊕ 1 = 1
1 ⊕ 0 = 1
1 ⊕ 1 = 0
```

If you have A, B, and P (where P = A ⊕ B), you can recover any missing piece:
- A ⊕ P = B
- B ⊕ P = A

Example with real data:
```
Stripe 1:
  Disk 1: 01011010  (A)
  Disk 2: 11001100  (B)
  Parity: 10010110  (P = A ⊕ B)

If Disk 1 dies, recover A:
  A = B ⊕ P = 11001100 ⊕ 10010110 = 01011010 ✓
```

For N drives, the parity is computed across N-1 data blocks, and each block is typically 512 bytes to 1 MiB (the chunk size).

![RAID 5 layout with 4 disks — distributed parity across all drives](https://upload.wikimedia.org/wikipedia/commons/6/64/RAID_5_new.png)

*RAID 5 distributed parity across 4 disks (Cburnett / Wikimedia Commons / CC-BY-SA-3.0)*

### RAID 5 Distributed Parity

In RAID 5, parity is not stored on a dedicated drive (that would be RAID 4). Instead, it rotates across all drives:

```
Stripe 0: P D0 D1 D2  (parity on disk 0)
Stripe 1: D0 P D1 D2  (parity on disk 1)
Stripe 2: D0 D1 P D2  (parity on disk 2)
Stripe 3: D0 D1 D2 P  (parity on disk 3)
```

This avoids the "parity drive" bottleneck of RAID 4, where the single parity drive is a write bottleneck.

### The RAID 5 Write Penalty

Every random write to a RAID 5 array costs 4 disk I/Os:

1. Read old data from target disk
2. Read old parity from parity disk
3. XOR old data with new data, XOR result with old parity → new parity
4. Write new data + new parity

This is called the **RAID 5 write penalty** (4x). Sequential writes can be optimized by reading and writing full stripes, but random writes always pay this penalty.

### The RAID 6 Write Penalty

RAID 6 has a 6x write penalty:
1. Read old data (2 disks)
2. Read both old parity blocks (2 disks)
3. Compute new parities
4. Write new data + both parities (3 writes)

Actually the penalty is more precisely: for each I/O operation, 6 disk operations occur.

### The RAID 5 Write Hole

The *write hole* is a RAID 5/6 vulnerability: if power is lost during a write, the parity may be inconsistent with the data. The array will not know which stripe is affected, and using the incorrect parity during a rebuild will produce corrupted data.

```
Normal write sequence:
1. Write data block A to Disk 1
2. Write parity P to Disk 3
3. Confirm completion

Power loss scenario:
1. Write data block A to Disk 1 ✓
2. POWER LOSS ✗ — parity P never written
3. On restart: Disk 3 has stale P, Disk 1 has new A
4. If Disk 2 fails, rebuild uses stale P → CORRUPTED DATA
```

Solutions:
- **Write-intent bitmap** (bitmap logging): md tracks which stripes may be inconsistent. On restart, only those stripes are checked and repaired.
- **RAID 5 with journal** (md journal device): a dedicated NVDIMM or SSD logs all writes before they hit the array.
- **Hardware RAID with BBU**: battery-backed cache allows the controller to complete delayed writes after power is restored.

### Write-Intent Bitmap

```bash
# Add a write-intent bitmap to an existing array
mdadm --grow /dev/md0 --bitmap=internal

# Check bitmap status
mdadm --detail /dev/md0 | grep -i bitmap

# Remove the bitmap
mdadm --grow /dev/md0 --bitmap=none
```

With a bitmap, if the system crashes, only stripes marked as "dirty" in the bitmap need to be resynced — typically a few hundred MiB instead of scanning the entire array.

### RAID 6 Double Parity — Reed-Solomon

RAID 6 uses two independent parity blocks per stripe. The first is standard XOR (same as RAID 5). The second uses **Reed-Solomon codes** — a more complex mathematical construct:

```
P = A ⊕ B ⊕ C ⊕ D  (XOR — same as RAID 5)
Q = A ⊕ 2B ⊕ 4C ⊕ 8D  (Galois field multiplication)
```

Without going deep into finite field arithmetic, the key point is that Reed-Solomon allows recovery from any two simultaneous failures. The math works because the second parity equation is linearly independent from the first — you cannot derive Q from P.

In md, the RAID 6 layout is defined by `--layout`:
```
left-asymmetric (default): P and Q rotate
left-symmetric: P and Q rotate with different offsets
```

---

## 🔍 Section 7: RAID 10 — Stripe of Mirrors

### The Near-Right Layout

RAID 10 in Linux md has several layout options. The default (and most common) is `near=2`:

```
Layout: near=2 (2 copies, near layout)
Chunk: 64K

Disk 1    Disk 2    Disk 3    Disk 4
┌────────┬────────┬────────┬────────┐
│ A1     │ A1     │ B1     │ B1     │
├────────┼────────┼────────┼────────┤
│ C1     │ C1     │ D1     │ D1     │
├────────┼────────┼────────┼────────┤
│ E1     │ E1     │ F1     │ F1     │
└────────┴────────┴────────┴────────┘
```

Each chunk is mirrored on the adjacent drive (1-2, 3-4). The stripes run across the mirror pairs.

### How RAID 10 Handles Failure

RAID 10 is the most fault-tolerant RAID level because any drive can fail and the mirror carries the data. With a 4-drive RAID 10:

- Survives 1 drive failure (obviously — mirror kicks in)
- Survives up to 2 drive failures IF no mirror loses both drives
- Can survive 2 failures if the failed drives are in different mirror pairs
- Could theoretically survive N/2 failures (with N=4, up to 2 failures possible)

Compare to RAID 5: any second failure during rebuild = total array loss.
Compare to RAID 6: survives exactly 2 failures, regardless of which drives.

### RAID 10 Performance Characteristics

| Metric | RAID 10 | RAID 5 | RAID 6 |
|--------|---------|--------|--------|
| Read IOPS | N x single drive | N x single drive | N x single drive |
| Write IOPS | N/2 x single drive | N/4 x single drive (random) | N/6 x single drive |
| Sequential read | N x single drive | N x single drive | N x single drive |
| Sequential write | N/2 x single drive | (N-1) x single drive | (N-2) x single drive |
| Write penalty | 2x | 4x | 6x |

For write-heavy workloads (databases, transaction logs), RAID 10 is significantly faster than RAID 5/6 because the write penalty is only 2x (both sides of the mirror).

### Creating RAID 10 with Different Layouts

```bash
# Default: near=2 (two copies, adjacent drives)
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    /dev/sda /dev/sdb /dev/sdc /dev/sdd

# Explicit near=2
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    --layout=n2 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# far layout — copies are far apart on the drive
# Better read performance for sequential access
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    --layout=f2 /dev/sda /dev/sdb /dev/sdc /dev/sdd

# offset layout — copies on different drives at offset chunks
mdadm --create /dev/md10 --level=10 --raid-devices=4 \
    --layout=o2 /dev/sda /dev/sdb /dev/sdc /dev/sdd
```

The `far` layout spreads the mirrored copies to opposite ends of the drive platters, which improves sequential read performance but increases seek time for random reads.

---

## 🔍 Section 8: RAID Failure Simulation and Recovery

### Simulating a Disk Failure

```bash
# 1. Check current state
mdadm --detail /dev/md0

# 2. Mark a drive as failed
mdadm --fail /dev/md0 /dev/loop2

# 3. Confirm the failure
cat /proc/mdstat
mdadm --detail /dev/md0
```

Output after failure:
```
md0 : active raid5 loop3[3] loop2[1](F) loop1[0]
      313344 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [U_U]
      
Number Major Minor RaidDevice State
   0     7      0        0      active sync   /dev/loop1
   1     7      0        1      faulty   /dev/loop2
   3     7      0        2      active sync   /dev/loop3
```

The `(F)` marks the failed device. The `[U_U]` shows device 1 is down.

### Removing the Failed Drive

```bash
mdadm --remove /dev/md0 /dev/loop2
```

After removal, the array runs in degraded mode. If this is RAID 5, you have NO redundancy. If RAID 6, you have one remaining parity. If RAID 1, you are running on one drive. If RAID 10, the mirror pair is down to one drive.

### Replacing and Rebuilding

```bash
# Add a replacement drive
mdadm --add /dev/md0 /dev/loop4

# Watch the rebuild
watch -n 1 cat /proc/mdstat
```

The kernel automatically starts rebuilding. During rebuild, performance is degraded — the resync process reads all remaining drives to reconstruct the missing data.

### Full Recovery Scenario

```bash
# Initial setup
for i in {1..4}; do
    dd if=/dev/zero of=/tmp/disk$i.img bs=1M count=100
    losetup /dev/loop$i /tmp/disk$i.img
done

# Create RAID 5
mdadm --create /dev/md0 --level=5 --raid-devices=3 --spare-devices=1 \
    /dev/loop1 /dev/loop2 /dev/loop3 /dev/loop4

# Create filesystem and test data
mkfs.ext4 /dev/md0
mount /dev/md0 /mnt/raidtest
dd if=/dev/urandom of=/mnt/raidtest/testfile bs=1M count=5

# Record checksum
sha256sum /mnt/raidtest/testfile > /root/testfile.sha256

# FAILURE! Kill loop2
mdadm --fail /dev/md0 /dev/loop2
mdadm --remove /dev/md0 /dev/loop2

# Hot spare (loop4) should automatically rebuild
# Wait for rebuild to complete
while grep -q "resync" /proc/mdstat; do sleep 5; done

# Verify data integrity
sha256sum -c /root/testfile.sha256

# The array is healthy and data survived
```

### Don't Remove the Wrong Drive

One of the most dangerous RAID mistakes: removing the WRONG drive during a rebuild or after a failure. Always triple-check serial numbers:

```bash
# Before failing a drive, confirm its identity
smartctl -i /dev/sdb | grep -i "serial"
mdadm --detail /dev/md0 | grep -B5 /dev/sdb
```

In a real data center, drives are labeled with physical location (bay number). The kernel also reports physical location:

```bash
ls -la /dev/disk/by-path/
# Shows drives by physical connector (e.g., pci-0000:00:1f.2-ata-3)
```

---

## 🔍 Section 9: Monitoring RAID Health

### /proc/mdstat — Real-Time Health

The simplest and most useful monitoring tool. Parse it in scripts:

```bash
#!/bin/bash
# Quick RAID health check

if grep -q "\[.*_.*\]" /proc/mdstat; then
    echo "ALERT: RAID array has a failed device!"
    mdadm --detail /dev/md0
    exit 1
fi

if grep -q "resync\|recovery\|reshape" /proc/mdstat; then
    echo "INFO: RAID array is syncing"
    cat /proc/mdstat
else
    echo "OK: All arrays healthy"
fi
```

### mdadm --monitor Mode

mdadm can run as a daemon and watch for events:

```bash
# Run in foreground (for testing)
mdadm --monitor --scan --test

# Run as daemon
mdadm --monitor --scan --daemonise --syslog

# With email alerts
mdadm --monitor --scan --mail=root@localhost
```

Events monitored:
- `Fail`: A device has failed
- `FailSpare`: A spare has failed
- `SpareActive`: A spare was activated (started rebuild)
- `NewArray`: A new array was detected
- `RebuildStarted/RebuildFinished/RebuildNN`

### Email Alerts Configuration

In `/etc/mdadm/mdadm.conf`:

```
MAILADDR admin@example.com
MAILFROM mdadm@server.example.com
PROGRAM /usr/local/bin/raid_notify.sh
```

The `MAILADDR` directive tells mdadm where to send alerts. The `PROGRAM` directive specifies a script to run on events (useful for Slack/PagerDuty integration).

### Integrating with systemd

mdadm provides a systemd service for monitoring:

```bash
systemctl enable mdmonitor.service
systemctl start mdmonitor.service

# Check status
systemctl status mdmonitor.service
```

The service reads `/etc/mdadm/mdadm.conf` and starts mdadm in monitor mode.

### smartctl — Predictive Failure Detection

SMART (Self-Monitoring, Analysis and Reporting Technology) can predict drive failures before they happen:

```bash
# Check SMART health
smartctl -H /dev/sda

# Comprehensive status
smartctl -a /dev/sda | grep -E "Reallocated|Pending|Offline|UDMA|Current_Pending"

# Key SMART attributes to watch:
#   5   Reallocated_Sector_Ct    — sectors remapped (should be 0)
# 197   Current_Pending_Sector   — sectors waiting to be remapped (should be 0)
# 198   Offline_Uncorrectable    — uncorrectable errors (should be 0)
# 196   Reallocated_Event_Count  — reallocation events (should be 0)
```

### Monitoring Script Example

```bash
#!/bin/bash
# /usr/local/bin/raid_health.sh
# Run from cron every 5 minutes

ALERT_EMAIL="admin@example.com"
TMPFILE=$(mktemp)

cat /proc/mdstat > "$TMPFILE"

# Check for failed devices
if grep -q "\[.*_.*\]" /proc/mdstat; then
    mail -s "RAID FAILURE on $(hostname)" "$ALERT_EMAIL" < "$TMPFILE"
fi

# Check for degraded arrays (should show [UU] not [U_] etc.)
if grep -qE "\[.*_.*" /proc/mdstat; then
    mail -s "RAID DEGRADED on $(hostname)" "$ALERT_EMAIL" < "$TMPFILE"
fi

rm -f "$TMPFILE"
```

---

## 🔍 Section 10: RAID and LVM

### Why Put LVM on Top of RAID?

RAID provides: reliability, performance, and device-level redundancy.
LVM provides: flexible volume management, snapshots, resizing, striping across arrays.

The recommended stack:

```
Filesystem (ext4/xfs)
    ↑
LVM logical volume (lv)
    ↑
LVM volume group (vg)
    ↑
Physical volumes (md0, md1, md2 — RAID arrays)
    ↑
md driver (RAID)
    ↑
Physical drives (/dev/sda, /dev/sdb, ...)
```

### Why NOT Put RAID on Top of LVM?

The reverse (LVM then RAID) is a bad idea because:
- LVM stripes would break RAID redundancy
- LVM snapshots mixed with RAID create complications
- The kernel md driver does not understand LVM layout

### Building RAID + LVM

```bash
# Create a RAID 5 array
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd

# Initialize as LVM physical volume
pvcreate /dev/md0

# Create volume group
vgcreate vg_data /dev/md0

# Create logical volumes
lvcreate -n lv_database -L 100G vg_data
lvcreate -n lv_backups -L 200G vg_data

# Create filesystems
mkfs.ext4 /dev/vg_data/lv_database
mkfs.xfs /dev/vg_data/lv_backups

# Mount
mount /dev/vg_data/lv_database /var/lib/mysql
mount /dev/vg_data/lv_backups /var/backups
```

### Extending RAID + LVM

```bash
# 1. Add a new drive to the RAID array (grow it)
mdadm --add /dev/md0 /dev/sde
mdadm --grow /dev/md0 --raid-devices=4

# 2. After reshape, tell LVM the PV has grown
pvresize /dev/md0

# 3. Extend the logical volume
lvextend -L +50G /dev/vg_data/lv_database

# 4. Resize the filesystem
resize2fs /dev/vg_data/lv_database      # ext4
xfs_growfs /var/lib/mysql               # XFS
```

### RAID Metadata on LVM — Not Recommended

You CAN put an md superblock on an LVM logical volume, but this is extremely unusual and not recommended for production. The LVM layer adds complexity, and if the LV is ever removed or snapshotted, the md array becomes inconsistent.

### LVM RAID (md raid in LVM)

Modern LVM (since lvm2 2.02.132) has built-in RAID support. Instead of creating mdadm arrays and then adding them to LVM, you can create RAID directly in LVM:

```bash
# Create a RAID 1 logical volume (uses md internally)
lvcreate --type raid1 --mirrors 1 -L 10G -n lv_mirror vg_data /dev/sdb /dev/sdc

# Create a RAID 5 logical volume
lvcreate --type raid5 --stripes 2 -L 10G -n lv_raid5 vg_data /dev/sdb /dev/sdc /dev/sdd

# Create a RAID 10 logical volume
lvcreate --type raid10 --mirrors 1 --stripes 2 -L 10G -n lv_raid10 vg_data \
    /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

Behind the scenes, LVM RAID uses the same kernel md driver. But it manages the arrays automatically, creating the md devices and handling failures through LVM commands:

```bash
# Convert a linear LV to RAID 1
lvconvert --type raid1 --mirrors 1 vg_data/lv_linear

# Repair a failed RAID LV
lvconvert --repair vg_data/lv_mirror
```

The advantage is that LVM handles all the md configuration. The disadvantage is that you lose some fine-grained mdadm control.

---

---

## ⭐ Level 3: Advanced — RAID Internals & Hardware

![XOR parity calculation — the math behind RAID 5 and RAID 6 recovery](https://www.sqlpassion.at/wp-content/uploads/2017/05/RAID5_Parity.png)

*XOR parity logic — how RAID 5 reconstructs data after a disk failure (SQLpassion)*

> **Level 3 Goal:** Master RAID internals — hardware RAID controllers, the md driver architecture, XOR parity math, superblock formats, performance tuning, and enterprise-grade RAID practices.

---

## 🔍 Section 11: Hardware RAID

### Hardware RAID Architecture

```
                    ┌─────────────────────┐
                    │   RAID Controller    │
                    │  ┌─────────────────┐ │
Host → PCIe Bus →   │  │  CPU + Cache    │ │
                    │  │  BBU (battery)  │ │
                    │  └─────────────────┘ │
                    │     │    │    │       │
                    └─────┼────┼────┼───────┘
                          │    │    │
                     ┌────┘    │    └────┐
                     │         │         │
                   [Drive]  [Drive]  [Drive]
```

Hardware RAID controllers have their own CPU, memory (256 MiB to 8 GiB cache), and battery backup unit (BBU). The OS sees only the final array — the controller handles all striping, mirroring, and parity. This is called "complete transparency" from the OS perspective.

### Why Hardware RAID?

- **Bootable**: The system can boot directly from the RAID array because the BIOS sees it as a single drive.
- **Zero OS CPU overhead**: Parity calculations happen on the controller.
- **Caching**: The BBU allows write-back caching — data is acknowledged as written immediately but actually written later. This dramatically improves performance.
- **OS independence**: Works with any OS (or no OS).

### Three Major Hardware RAID Vendors

| Vendor | Controller Examples | Management Tool |
|--------|-------------------|-----------------|
| Broadcom/Avago/LSI | MegaRAID 9361-8i, 9460-16i | `storcli` / `megacli` |
| Dell (OEM LSI) | PERC H730, H740, H745 | `perccli` / `megacli` |
| Hewlett Packard | Smart Array P440, P840 | `hpssacli` / `ssacli` |
| Microsemi/Adaptec | SmartRAID 3154-8i | `arcconf` |

### storcli — Broadcom MegaRAID

`storcli` replaced `megacli` as the standard tool. Its syntax is:

```bash
# List all controllers
storcli64 show

# Show all arrays (virtual drives) on controller 0
storcli64 /c0 /vall show

# List physical drives
storcli64 /c0 /eall /sall show

# Create a RAID 5 array (Virtual Drive) from drives 0:0, 0:1, 0:2
storcli64 /c0 add vd type=raid5 drives=0:0,0:1,0:2 name=VD_RAID5

# Set write-back cache with BBU
storcli64 /c0 /v0 set wrcache=wb

# Check BBU status
storcli64 /c0 /bbu show

# Locate a physical drive (blinks the activity LED)
storcli64 /c0 /e0 /s3 start locate
storcli64 /c0 /e0 /s3 stop locate
```

### Foreign Configurations

When you physically move drives from one controller to another (e.g., failed controller replacement), the new controller sees them as having a "foreign configuration" — an array from a different controller.

```bash
# Scan for foreign configs
storcli64 /c0 /fall show

# Preview what the foreign config contains
storcli64 /c0 /fall import preview

# Import the foreign config (add to this controller)
storcli64 /c0 /fall import

# OR — clear the foreign config (DESTROYS array metadata)
storcli64 /c0 /fall delete
```

### BBU — Battery Backup Unit

The BBU is a small battery on the RAID controller that keeps the cache powered long enough to flush writes to disk after a power failure. Without a working BBU, write-back caching is unsafe (though some controllers force write-through if the BBU is failed).

```bash
# Check BBU health
storcli64 /c0 /bbu show

# Output:
# BBU_Status = Healthy
# Battery_Type = iBBU
# Voltage = 3908 mV
# Temperature = 37 C
# State = Optimal
# Remaining Capacity = 99%

# Learn cycle (calibrates the battery — run yearly)
storcli64 /c0 /bbu start learn
```

A learn cycle intentionally discharges and recharges the battery to calibrate its capacity gauge. The controller runs in write-through mode during the learn cycle, which reduces performance.

### hpssacli — HP Smart Array

```bash
# List controllers
hpssacli ctrl all show

# List logical drives
hpssacli ctrl slot=0 ld all show

# List physical drives
hpssacli ctrl slot=0 pd all show

# Create RAID 5
hpssacli ctrl slot=0 create type=ld drives=1I:1:1,1I:1:2,1I:1:3 raid=5

# Check BBU
hpssacli ctrl slot=0 show status
```

On newer HP ProLiant Gen10+ systems, `hpssacli` has been superseded by `ssacli` or the RESTful API.

### perccli — Dell PERC Controllers

```bash
# Show controller info
perccli64 show

# List virtual drives
perccli64 /c0 /vall show

# Create RAID 10
perccli64 /c0 add vd type=raid10 drives=0:0-3 size=all

# Show disk group info
perccli64 /c0 /d0 show
```

Remember: Dell PERC controllers are rebranded LSI/Broadcom chipsets. The CLI syntax is very similar to storcli.

---

## 🔍 Section 12: Comparing RAID Levels
> **Level**: Basic (reference) — this section belongs conceptually to Level 1; placed here for document flow.

### Full Comparison Table

| Feature | RAID 0 | RAID 1 | RAID 5 | RAID 6 | RAID 10 |
|---------|--------|--------|--------|--------|---------|
| Min drives | 2 | 2 | 3 | 4 | 4 |
| Max fault tolerance | None | 1 drive | 1 drive | 2 drives | 1 per mirror |
| Effective capacity | N × | 1 × | (N-1) × | (N-2) × | N/2 × |
| Capacity efficiency | 100% | 50% | 67-94% | 50-88% | 50% |
| Read IOPS | N × | N × (both mirrors) | N × | N × | N × |
| Write IOPS (random) | N × | 1 × (both mirrors) | N/4 × | N/6 × | N/2 × |
| Sequential write | N × | 1 × | (N-1) × | (N-2) × | N/2 × |
| Write penalty | 1× | 2× | 4× | 6× | 2× |
| Rebuild impact | N/A (total loss) | Low (copy from mirror) | High (reads all drives) | Very high (reads all drives) | Low (copy from mirror) |
| Risk during rebuild | N/A | None (1 remaining) | Second failure = loss | Second failure OK | Depends on failure location |
| Use case | Temp/cache, zero concern for data loss | OS drive, small databases | General storage, archives, media | Large capacity + high uptime | Databases, VMs, high-performance |

### IOPS Calculation Example

Given 4 drives, each capable of 100 random read IOPS and 100 random write IOPS:

| Level | Read IOPS | Write IOPS | Capacity |
|-------|-----------|------------|----------|
| RAID 0 | 400 | 400 | 4 × |
| RAID 1 | 400 (both mirrors) | 100 (both write) | 2 × |
| RAID 5 | 400 (read all) | 100 (1/4 penalty) | 3 × |
| RAID 6 | 400 (read all) | ~67 (1/6 penalty) | 2 × |
| RAID 10 | 400 | 200 (half penalty) | 2 × |

RAID 10 provides the best write IOPS of any redundant RAID level, which is why it is preferred for databases.

### Capacity Efficiency Graph

```
For 4 × 1 TiB drives:

 RAID 0:  4.0 TiB usable  (100% efficiency)
 RAID 1:  1.0 TiB usable  ( 25% efficiency) — for a 2-drive mirrored pair
 RAID 5:  3.0 TiB usable  ( 75% efficiency)
 RAID 6:  2.0 TiB usable  ( 50% efficiency)
 RAID 10: 2.0 TiB usable  ( 50% efficiency)

For 10 × 1 TiB drives:

 RAID 0:  10.0 TiB usable  (100%)
 RAID 5:   9.0 TiB usable  ( 90%)
 RAID 6:   8.0 TiB usable  ( 80%)
 RAID 10:  5.0 TiB usable  ( 50%)
```

As the number of drives increases, RAID 5 and 6 become more capacity-efficient. RAID 10 always loses exactly 50% of capacity.

### When to Use What

- **RAID 0**: Scratch space, video editing temp files, scientific compute nodes where checkpointing handles failures. NEVER for valuable data.
- **RAID 1**: Boot drives, OS partitions, small databases. Simple and reliable.
- **RAID 5**: Media storage, file servers, archives, backup repositories. Good capacity efficiency with 4-8 drives.
- **RAID 6**: Large-capacity storage, archive servers, video surveillance. Protection during URE (unrecoverable read error) events during rebuild.
- **RAID 10**: Databases (MySQL, PostgreSQL, Oracle), virtual machine stores, high-performance file servers. Best write performance of any redundant level.

---

## 🔬 15 Hands-On Practices

### Level 1 Practices: Building Your First Arrays

**Goal:** Create, format, and destroy the basic RAID levels (0, 1, 5, 10) using `mdadm`.

---

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

---

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

---

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

---

## 🧠 Level 3 Deep Understanding — How RAID Really Works
> Deep-dive into the md kernel driver, parity math, superblock formats, and performance internals.

### The md Driver Architecture

The Linux md driver (`drivers/md/md.c` in the kernel source) implements a generic block-level driver that sits between the filesystem and physical block devices. Its key components:

```
┌─────────────────────────────────────┐
│         Userspace (mdadm)           │
└──────────────┬──────────────────────┘
               │ ioctl() / sysfs
┌──────────────▼──────────────────────┐
│         md_mod.ko (core)            │
│  ┌──────────────────────────────┐   │
│  │  mddev — array descriptor   │   │
│  │  ├─ raid_disks              │   │
│  │  ├─ level                   │   │
│  │  ├─ chunk_size              │   │
│  │  ├─ layout                  │   │
│  │  ├─ bitmap (write-intent)   │   │
│  │  └─ private (personality)   │   │
│  └──────────────────────────────┘   │
└──────────────┬──────────────────────┘
               │ bio requests
┌──────────────▼──────────────────────┐
│  Personality Modules               │
│  ┌──────────┐ ┌──────────┐ ┌──────┐│
│  │raid0.ko  │ │raid1.ko  │ │raid5││
│  │          │ │          │ │.ko  ││
│  └──────────┘ └──────────┘ └──────┘│
└──────────────┬──────────────────────┘
               │ split bio to components
┌──────────────▼──────────────────────┐
│  Block Layer (submit_bio)          │
│  sda  sdb  sdc  sdd  (component)   │
└─────────────────────────────────────┘
```

The `mddev` structure holds the array metadata. The `personality` is a set of function pointers that implement the specific RAID algorithm. When you create a RAID 5 array, md assigns the `raid5` personality to the array, which handles all stripe computation.

### RAID 5 XOR Parity Calculation — Step by Step

Let's trace a 4 KiB write to a RAID 5 array with 512-byte chunk size:

```
Chunk size = 512 bytes
Stripe width = 3 data chunks × 512 bytes = 1536 bytes

Write: 4 KiB = 8 sectors of 512 bytes
       = 2 full stripes + 1 partial stripe

Stripe 0:
  [chunk 0]      [chunk 1]      [chunk P]
  0xAB12CD34     0x5678EF01     0xFD6A2235 (XOR of data chunks)

To compute parity:
  P = chunk0 XOR chunk1
  P = 0xAB12CD34 XOR 0x5678EF01
  P = 0xFD6A2235

To reconstruct chunk0 from failed drive:
  chunk0 = chunk1 XOR P
  chunk0 = 0x5678EF01 XOR 0xFD6A2235
  chunk0 = 0xAB12CD34 ✓
```

The XOR is computed per byte, per chunk. The kernel does this with SIMD instructions (SSE/AVX on x86, NEON on ARM) for massive parallelism — millions of bytes per second.

### RAID 6 Reed-Solomon Codes

RAID 6 computes TWO parity blocks per stripe. The first (P) is the same XOR as RAID 5. The second (Q) uses Reed-Solomon coding:

```
P = D0 ⊕ D1 ⊕ D2 ⊕ ... ⊕ Dn-1
Q = D0 ⊕ (2·D1) ⊕ (4·D2) ⊕ ... ⊕ (2^(n-1)·Dn-1)
```

Where multiplication is in GF(2^8) — Galois field of 256 elements. This is NOT regular integer multiplication. It uses a generator polynomial (typically 0x1D for RAID 6). The field arithmetic allows constructing two independent equations, guaranteeing recovery from any two failures.

The kernel implementation uses a Cauchy matrix or Vandermonde matrix to compute the coefficients. Modern CPUs with AES-NI instructions can accelerate GF(2^8) multiplication.

### The Resync and Recovery Process

When md decides to resync or rebuild:

1. **Event count check**: Every write increments an event counter in the superblock. During assembly, md compares event counts across all drives. If they match, no resync needed. If they differ, the array needs resync.

2. **Bitmap check**: If a write-intent bitmap exists, md checks which stripes are marked dirty and only resyncs those.

3. **Full resync**: Without a bitmap, md reads every stripe, computes parity, and writes it. For RAID 1, it copies entire drives.

4. **Recovery rebuild**: When a failed drive is replaced, md reads every stripe from the surviving drives, reconstructs the missing data (using XOR for RAID 5, Reed-Solomon for RAID 6, or simple copy for RAID 1/10), and writes it to the replacement.

### md Superblock Layout

The superblock is stored at a known offset on each component device. For version 1.2 (most common):

```
| 4 KiB padding | Superblock (4 KiB) | Data area starts here... |
| 0x000-0xFFF   | 0x1000-0x1FFF       | 0x2000 →                  |
```

The superblock structure (from kernel source `include/linux/raid/md_p.h`):

```c
struct mdp_superblock_1 {
    __le32  magic;          // 0xA92B4EFC
    __le32  major_version;  // 1
    __le32  feature_map;    // bitmap, journal, etc.
    __le32  pad0;
    __u8    set_uuid[16];   // UUID of the array
    char    set_name[32];   // Name (host:array)
    __u8    csum[20];       // SHA1 checksum of superblock
    __le64  mtime;          // Last modification time
    __le32  level;          // RAID level
    __le32  layout;         // left-symmetric, near, far, etc.
    __le64  size;           // Size of data area per device
    __le32  chunksize;      // In bytes
    __le32  raid_disks;     // Number of active disks
    __le32  bitmap_offset;  // Location of bitmap
    // ... more fields
    __le32  dev_number;     // Role index in the array
    __le64  events;         // Event count
    // ... device-specific fields
};
```

The magic number `0xA92B4EFC` identifies an md superblock. The `events` field ensures the kernel always uses the most recent copy during assembly — if one drive has a higher event count, it has the most up-to-date data.

### Superblock Format Comparison

| Aspect | 0.90 | 1.0 | 1.1 | 1.2 |
|--------|------|-----|-----|------|
| Location | Last 2 sectors | Last 4 KiB | First 4 KiB | 4 KiB from start |
| UUID support | No (uses major/minor) | Yes (128-bit) | Yes | Yes |
| Max device size | 2 TiB | Unlimited | Unlimited | Unlimited |
| Max array size | 2 TiB | Unlimited | Unlimited | Unlimited |
| Name support | No | Yes (32 chars) | Yes | Yes |
| Default in mdadm | Legacy | Rarely | Rarely | Yes (current) |
| Detection | scan by device | scan last sectors | scan first sectors | scan at offset 4K |

The key practical difference: with 1.0, the superblock is at the END of the device, so the beginning once had valid partition table or filesystem data (useful for booting). With 1.2 (default), the superblock is 4 KiB from the start, which means the first 4 KiB is available for boot code.

### Bitmap (Write-Intent Bitmap) Internals

The write-intent bitmap is stored either internally (within the array data area, at the end) or on an external device. It divides the array into fixed-size chunks (typically 64 MiB each). Each bit in the bitmap represents one chunk:

```
Bitmap chunk size = 64 MiB
Array size = 1 TiB
Number of bits = 1 TiB / 64 MiB = 16384 bits = 2048 bytes
```

When data in a chunk is modified, the corresponding bit is set to 1 (dirty). On clean shutdown, all bits are cleared. After a crash, dirty bits indicate which stripes might be inconsistent. md reads those stripes and repairs parity.

```bash
# Set explicit bitmap chunk size
mdadm --grow /dev/md0 --bitmap=internal --bitmap-chunk=32768
```

### RAID 5/6 Write Hole — Deeper Explanation

The write hole exists because RAID 5/6 writes are NOT atomic. A single write to a RAID 5 stripe involves:

```
1. Read old data block D (from disk)
2. Read old parity block P (from disk)
3. XOR D(old) with D(new) → diff
4. XOR diff with P(old) → P(new)
5. Write D(new) to disk
6. Write P(new) to disk
```

If the system crashes between steps 5 and 6, the parity is stale but no longer matches the data. This is called a "torn stripe." On recovery, if a second drive fails, md reads the bad parity and reconstructs the data incorrectly — producing silent corruption.

The bitmap mitigates this: on restart, stripes with dirty bitmap bits are resynced. But the bitmap itself is not crash-safe either (it is stored on the md device). This is why enterprise arrays use dedicated journal devices:

```bash
# Create a RAID 5 with a dedicated journal on an SSD
mdadm --create /dev/md0 --level=5 --raid-devices=3 \
    --write-journal /dev/nvme0n1p1 \
    /dev/sda /dev/sdb /dev/sdc
```

The journal provides true atomicity: all writes go to the journal first, then to the array. On crash recovery, the journal replays or discards incomplete writes.

### Chunk Size and Alignment

![Linux kernel I/O stack — from VFS through block layer to device drivers](https://upload.wikimedia.org/wikipedia/commons/3/30/IO_stack_of_the_Linux_kernel.svg)

*Linux kernel storage stack — block layer, I/O schedulers, and device-mapper (Fischer & Schönberger / Wikimedia Commons / CC-BY-SA-4.0)*

The chunk size determines the stripe width and has dramatic performance implications:

| Chunk Size | Small files (4K) | Large files (1M+) | Mixed workloads |
|------------|------------------|--------------------|-----------------|
| 16K | Best for random I/O | High overhead | Good for databases |
| 64K | Good | Good | Good all-around (default) |
| 512K | Poor (wasted parity reads) | Best for sequential | Good for media/archives |
| 1M | Very poor | Best for huge sequential | Poor for random |

Rule of thumb: match chunk size to the average I/O size of your workload. Database workloads (8K random I/O) benefit from small chunks. Media streaming (1M+ sequential) from large chunks.

Alignment is critical for performance. All RAID components should be aligned to the stripe boundary:

```bash
# For RAID 5 with 3 drives and 64K chunk:
# Stripe = (3-1) × 64K = 128K
# Partition start should be a multiple of 128K

parted /dev/sda unit s print
# Ensure partitions start at sector boundaries aligned to stripe
```

### mdadm --examine — Reading Raw Superblock Data

```bash
# Read the superblock from a component device
mdadm --examine /dev/loop1

# Output:
/dev/loop1:
          Magic : a92b4efc
        Version : 1.2
    Feature Map : 0x0
     Array UUID : 1b3345cd:6789abcd:0123ef45:67891234
           Name : hostname:0
  Creation Time : Tue Jun 16 14:23:45 2026
     Raid Level : raid5
   Raid Devices : 3

 Avail Dev Size : 204800 sectors (100.00 MiB 102.40 MB)
     Array Size : 409600 KiB (400.00 MiB 419.43 MB)
  Used Dev Size : 204800 sectors (100.00 MiB 102.40 MB)
    Data Offset : 2048 sectors
   Super Offset : 8 sectors
   Unused Space: before=1960 sectors, after=0 sectors
          State : clean
    Device UUID : 9abcdef0:12345678:90abcdef:12345678

    Update Time : Tue Jun 23 16:30:12 2026
       Checksum : a1b2c3d4 - correct
         Events : 2478

         Layout : left-symmetric
     Chunk Size : 512K

   Device Role : Active device 0
   Array State : UUU ('U' = active, '.' = missing, 'R' = replacing)
```

The `Events` count is critical. If one drive shows events=2478 and another shows events=2479, the second drive has more recent data. During assembly, md selects the drive with the highest event count as authoritative.

---

## 📋 Command Reference by Level

### Level 1 Commands — Create & Inspect
| Command | Purpose |
|---------|---------|
| `cat /proc/mdstat` | Show live status of all arrays |
| `mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sda /dev/sdb /dev/sdc` | Create a RAID 5 array |
| `mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sda /dev/sdb /dev/sdc /dev/sdd` | Create a RAID 10 array |
| `mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb` | Create a RAID 1 mirror |
| `mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sda /dev/sdb` | Create a RAID 0 stripe |
| `mdadm --detail /dev/md0` | Show detailed array info |
| `mdadm --detail --scan` | Generate config lines for mdadm.conf |
| `mdadm --query /dev/sda` | Check if device is part of an array |
| `mdadm --examine /dev/sda` | Read raw superblock data |

### Level 2 Commands — Manage & Recover
| Command | Purpose |
|---------|---------|
| `mdadm --assemble /dev/md0 /dev/sda /dev/sdb /dev/sdc` | Assemble an array |
| `mdadm --assemble --scan` | Auto-discover and assemble all arrays |
| `mdadm --stop /dev/md0` | Stop an array |
| `mdadm --fail /dev/md0 /dev/sdb` | Mark a drive as failed |
| `mdadm --remove /dev/md0 /dev/sdb` | Remove a drive from an array |
| `mdadm --add /dev/md0 /dev/sdd` | Add a drive (as spare or replacement) |

### Level 3 Commands — Grow, Tune & Monitor
| Command | Purpose |
|---------|---------|
| `mdadm --grow /dev/md0 --raid-devices=4` | Grow array to more drives |
| `mdadm --grow /dev/md0 --level=6` | Migrate to different RAID level |
| `mdadm --grow /dev/md0 --bitmap=internal` | Add write-intent bitmap |
| `mdadm --grow /dev/md0 --chunk=128` | Change chunk size |
| `mdadm --monitor --scan --mail=admin@example.com` | Start monitoring with email |
| `mdadm --zero-superblock /dev/sda` | Wipe md superblock (destructive!) |

### Key Files

| File | Purpose |
|------|---------|
| `/proc/mdstat` | Live RAID status from kernel |
| `/etc/mdadm/mdadm.conf` | mdadm configuration |
| `/dev/md/*` | Device-mapper RAID device nodes |
| `/dev/disk/by-id/` | Persistent disk identifiers |
| `/dev/disk/by-path/` | Physical location identifiers |
| `/sys/block/md0/md/` | sysfs interface for md driver |
| `/proc/sys/dev/raid/speed_limit_min` | Minimum resync speed (KB/sec) |
| `/proc/sys/dev/raid/speed_limit_max` | Maximum resync speed (KB/sec) |

### sysfs md Interface

The sysfs directory `/sys/block/md0/md/` exposes fine-grained control:

```bash
# List attributes
ls /sys/block/md0/md/

# Check array state
cat /sys/block/md0/md/array_state

# Check sync status
cat /sys/block/md0/md/sync_action

# Trigger a check
echo check > /sys/block/md0/md/sync_action

# Trigger a repair (fixes mismatches found by check)
echo repair > /sys/block/md0/md/sync_action

# Set sync speed (same as /proc/sys/proc interface)
echo 50000 > /sys/block/md0/md/sync_speed_max
```

### Hardware RAID Management Commands

| Command | Purpose |
|---------|---------|
| `storcli64 show` | List Broadcom/LSI RAID controllers |
| `storcli64 /c0 /vall show` | List virtual drives on controller 0 |
| `storcli64 /c0 /eall /sall show` | List physical drives |
| `storcli64 /c0 add vd type=raid5 drives=0:0,0:1,0:2` | Create RAID 5 virtual drive |
| `storcli64 /c0 /fall import` | Import foreign configuration |
| `storcli64 /c0 /bbu show` | Check BBU status |
| `perccli64 /c0 /vall show` | Dell PERC: list virtual drives |
| `hpssacli ctrl slot=0 ld all show` | HP Smart Array: list logical drives |
| `hpssacli ctrl slot=0 pd all show` | HP Smart Array: list physical drives |

---

## 🚀 What's Coming in Part 31

**Part 31: LVM — Logical Volume Manager**

You will learn:
- Physical volumes, volume groups, and logical volumes — the LVM stack
- Creating and managing LVM volumes
- Extending, shrinking, and removing volumes
- LVM snapshots — instant point-in-time backups
- LVM striping, mirroring, and thin provisioning
- LVM cache pools — using SSDs to accelerate HDD volumes
- LVM RAID integration (lvmraid)
- Moving data between drives without downtime
- Resizing filesystems on LVM
- Integration with RAID from Part 30
- 15 hands-on practices with LVM

---

## 📝 Self-Test — Can You Answer These?

1. What is the difference between RAID 0 and RAID 1? When would you use each?
2. How does RAID 5 parity work? What mathematical operation is used for the first parity block?
3. What is the RAID 5 write hole? How does a write-intent bitmap mitigate it?
4. How many drives minimum are needed for RAID 6? For RAID 10? What are the effective capacities with 4 × 1 TiB drives?
5. What does the output `[UU_U]` mean in `/proc/mdstat`? What action would you take?
6. What is a hot spare and what determines when it activates? What happens to the spare after the failed drive is replaced?
7. What does `mdadm --fail` do to a drive? Does it destroy the data on that drive?
8. How do you add an internal write-intent bitmap to an existing RAID 5 array? What command and parameters?
9. What is the difference between superblock formats 0.90, 1.0, 1.1, and 1.2? Which is the modern default?
10. In the LVM-on-RAID stack, which component goes first? Why is the reverse order (RAID on LVM) a bad idea?
11. What is the RAID 5 write penalty? Why does a random 4 KiB write to RAID 5 require 4 physical I/Os?
12. Why is RAID 10 preferred over RAID 5 for database workloads? Compare the write IOPS of each with 8 drives.
13. What is a foreign configuration on a hardware RAID controller? How do you import or clear it?
14. What is the role of the BBU on a hardware RAID controller? What happens during a learn cycle?
15. In RAID 6, what is the difference between the P and Q parity blocks? Why can't you derive Q from P?

**Score:** 12/15 correct = ready for Part 31.

---

*Linux SysAdmin Course | Part 30 of ∞ | Reverse Engineering Approach*
*Previous → Part 29: Samba and Windows Interoperability*
*Next → Part 31: LVM — Logical Volume Manager*

[← Previous](part29.md) | [Next →](part31.md)
