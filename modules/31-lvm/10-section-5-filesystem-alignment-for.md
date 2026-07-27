## 🔍 Section 5: Filesystem Alignment for Striped LVs

```bash
# If LV is striped across 4 PVs with 64K stripe:
sudo mkfs.ext4 -E stride=16,stripe_width=64 /dev/vg_data/lv_stripe
# stride = 64K / 4K block = 16; stripe_width = 16 × 4 = 64

sudo mkfs.xfs -d su=64k,sw=4 /dev/vg_data/lv_stripe
```

---



---

[← Previous](09-section-4-logical-volumes-shrinking.md) | [↑ Index](index.md) | [Next →](11-section-6-lvm-snapshots.md)
