## 🔍 Section 7: Thin Provisioning

Thin provisioning lets you create LVs with virtual sizes larger than available physical space. Space is allocated on-demand from a thin pool.

### Thin Pool Architecture

```
┌──────────────────────────────────────────────┐
│ Thin Pool                                     │
│  ┌──────────────────┐  ┌──────────────────┐   │
│  │ data LV (actual)  │  │ metadata LV      │   │
│  └────────┬─────────┘  └────────┬─────────┘   │
│           └──────────┬──────────┘              │
│                      │                          │
│  ┌───────────────────┼───────────────────┐     │
│  │                   │                   │      │
│ thin_lv_1 (2T virt)  thin_lv_2 (500G)    snap  │
│  50G actual          30G actual           1G    │
└────────────────────────────────────────────────┘
```

### Creating Thin Pool and Thin LVs

```bash
# Create thin pool
sudo lvcreate --type thin-pool -L 100G -n thin_pool vg_data

# Create thin LVs
sudo lvcreate --type thin -V 2T -n thin_lv_1 vg_data/thin_pool
sudo lvcreate --type thin -V 500G -n thin_lv_2 vg_data/thin_pool

# Monitor pool usage
lvs -a -o lv_name,lv_size,data_percent,metadata_percent,pool_lv
```

### Extending Thin Pool

```bash
sudo lvextend -L +50G vg_data/thin_pool                 # Data
sudo lvextend --poolmetadatasize +1G vg_data/thin_pool  # Metadata
```

### dmeventd Auto-Extend

Edit `/etc/lvm/lvm.conf`:
```
thin_pool_autoextend_threshold = 80
thin_pool_autoextend_percent = 20
```

```bash
sudo lvchange --monitor y vg_data/thin_pool
```

### Overcommit Warning

If data_percent reaches 100%, ALL thin LVs go read-only. Monitor daily and never run > 80% without auto-extend configured.





[← Previous](11-section-6-lvm-snapshots.md) | [↑ Index](index.md) | [Next →](13-section-8-lvm-cache.md)
