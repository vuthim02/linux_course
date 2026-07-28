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





[← Previous](02-level-1-basic-raid-fundamentals.md) | [↑ Index](index.md) | [Next →](04-section-2-mdadm-the-linux.md)
