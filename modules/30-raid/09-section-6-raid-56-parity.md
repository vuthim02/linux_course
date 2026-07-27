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



---

[← Previous](08-section-5-spare-disks-hot.md) | [↑ Index](index.md) | [Next →](10-section-7-raid-10-stripe.md)
