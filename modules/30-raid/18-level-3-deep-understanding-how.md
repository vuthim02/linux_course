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





[← Previous](17-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](19-command-reference-by-level.md)
