## 🔍 Section 9: LVM Striping

Striping spreads data across multiple PVs, improving sequential I/O throughput.

### Creating Striped LVs

```bash
# 2-way stripe
sudo lvcreate --type striped -i 2 -I 64 -L 100G -n lv_stripe vg_data

# 4-way stripe on specific PVs
sudo lvcreate --type striped -i 4 -I 128 -L 200G -n lv_stripe4 vg_data /dev/sd{b,c,d,e}

# Check stripe layout
lvs -a -o lv_name,seg_type,stripes,stripe_size,devices
```

| Workload | Stripe Size |
|----------|-------------|
| OLTP (random, small) | 16-64 KiB |
| File server (mixed) | 64-128 KiB |
| Data warehouse (sequential) | 256-512 KiB |
| Video streaming | 1 MiB |

Converting a linear LV to striped requires creating a new LV and copying data:

```bash
sudo lvcreate --type striped -i 4 -I 64 -L 200G -n lv_stripe_new vg_data
sudo dd if=/dev/vg_data/lv_linear of=/dev/vg_data/lv_stripe_new bs=4M status=progress
sudo lvremove vg_data/lv_linear
sudo lvrename vg_data/lv_stripe_new lv_linear
```

---



---

[← Previous](16-level-3-advanced-lvm-internals.md) | [↑ Index](index.md) | [Next →](18-section-10-lvm-raid.md)
