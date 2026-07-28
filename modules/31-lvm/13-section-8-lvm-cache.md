## 🔍 Section 8: LVM Cache

LVM cache accelerates a slow device (HDD) with a fast device (SSD).

### Creating a Cache LV

```bash
# Method 1: Two-step
sudo lvcreate -L 500G -n lv_origin vg_data /dev/sdb       # Slow
sudo lvcreate -L 50G -n lv_cache vg_data /dev/sdc         # Fast
sudo lvconvert --type cache --cachepool vg_data/lv_cache vg_data/lv_origin

# Check status
lvs -a -o lv_name,lv_attr,size,pool_lv,cache_mode,cache_policy,cache_read_hits,cache_read_misses
```

### Cache Modes

```bash
# writethrough (default) — writes to both cache+origin. Safe, slower writes.
sudo lvchange --cachemode writethrough vg_data/lv_origin

# writeback — writes to cache only, flushed later. Fast writes, risk on cache failure.
sudo lvchange --cachemode writeback vg_data/lv_origin

# passthrough — reads from origin, writes bypass cache. Maintenance mode.
```

### Removing Cache

```bash
sudo lvconvert --splitcache vg_data/lv_origin              # Detach
sudo lvremove vg_data/lv_cache                            # Remove pool
```





[← Previous](12-section-7-thin-provisioning.md) | [↑ Index](index.md) | [Next →](14-section-11-lvm-and-encryption.md)
