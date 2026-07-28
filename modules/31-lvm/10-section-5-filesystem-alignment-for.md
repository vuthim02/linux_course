## 🔍 Section 5: Filesystem Alignment for Striped LVs

Filesystem alignment is critical when using striped logical volumes. Misalignment causes extra I/O operations — a single logical write can span two physical stripes, doubling the I/O cost.

```bash
# If LV is striped across 4 PVs with 64K stripe:
sudo mkfs.ext4 -E stride=16,stripe_width=64 /dev/vg_data/lv_stripe
# stride = 64K / 4K block = 16; stripe_width = 16 × 4 = 64

sudo mkfs.xfs -d su=64k,sw=4 /dev/vg_data/lv_stripe
```

**Key parameters**:
- **stride**: Number of filesystem blocks per stripe unit. Controls how the filesystem distributes data across stripes.
- **stripe_width**: Number of filesystem blocks across all data stripes. This is `stride × (number of data disks)`.
- **su** (XFS): Stripe unit size — the amount of data written to one disk before moving to the next.
- **sw** (XFS): Stripe width — the number of data-bearing disks in the array.

**How to calculate**:
1. Determine your stripe unit size from `lvdisplay` or `lvs -o +stripesize`.
2. Divide by the filesystem block size (usually 4096 bytes) to get `stride`.
3. Multiply `stride` by the number of stripes (PVs in the LV) to get `stripe_width`.

**Why it matters**: Without alignment, a 4KB write to an aligned offset might span two 64KB stripes, requiring two disk reads and two disk writes instead of one of each. For database workloads, misalignment can reduce performance by 40% or more.


[← Previous](09-section-4-logical-volumes-shrinking.md) | [↑ Index](index.md) | [Next →](11-section-6-lvm-snapshots.md)
