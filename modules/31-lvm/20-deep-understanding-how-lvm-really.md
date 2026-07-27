## 🧠 Deep Understanding — How LVM Really Works

### The Device Mapper Layer

LVM2 is built entirely on the Linux **Device Mapper** (dm) framework — a kernel subsystem for creating virtual block devices.

```
Kernel DM stack:
  Userspace (lvm2 tools → libdevmapper → ioctl)
    ↓
  Device Mapper Core (drivers/md/dm.c)
    ├── dm-linear    — linear mapping
    ├── dm-stripe    — striping
    ├── dm-mirror    — mirror/RAID1
    ├── dm-snapshot  — COW snapshots
    ├── dm-thin      — thin provisioning
    ├── dm-cache     — caching (SSD/HDD)
    ├── dm-raid      — RAID 4/5/6/10
    └── dm-crypt     — LUKS encryption
    ↓
  Block devices (sdX, nvmeXnY)
```

### How dmsetup Creates a Mapping

A linear LV's kernel table:

```
sudo dmsetup table vg_data-lv_home
0 20971520 linear 8:16 2048
│         │        │     └── Start sector on /dev/sdb (after PV header)
│         │        └── Device major:minor (8:16 = /dev/sdb)
│         └── Size in sectors (20971520 = 10 GiB)
└── Start sector of virtual device
```

LVM translates its metadata ("LV uses PE 0-2559 on PV /dev/sdb") into this table. Each PE = 8192 sectors (4 MiB). PEs start at sector 2048 (1 MiB alignment).

### dm-stripe Table

```
sudo dmsetup table vg_data-lv_stripe
0 41943040 striped 2 128 8:16 2048 8:32 2048
                    │   │   └─stripe1 └─stripe2
                    │   └── Stripe size in sectors (128×512=64K)
                    └── Number of stripes (=2)
```

### dm-snapshot — COW in Detail

```
Table: 0 20971520 snapshot 253:0 253:1 P 16
                           │      │     │ └── Chunk size (16 sectors = 8K)
                           │      │     └── P=persistent
                           │      └── COW device (dm-1)
                           └── Origin device (dm-0)

On first write to origin sector X:
1. Read origin data at sector X
2. Write old data to COW store
3. Update exception table: "sector X → COW chunk Y"
4. Write new data to origin
Read from snapshot: if sector in exception table → read from COW; else → read origin
```

### dm-thin — Thin Provisioning

Thin pool table:
```
0 209715200 thin-pool 253:3 253:4 128 1024
                       │      │    │    └── Low water mark
                       │      │    └── Block size (sectors)
                       │      └── Metadata device
                       └── Data device
```

**Thin write flow:**
1. Write to sector X of thin LV (ID 42)
2. dm-thin checks: "is sector X mapped for device 42?"
3. If no: allocate block from data device, update metadata
4. Write data to allocated block

### dm-cache Table

```
0 419430400 cache 253:0 253:1 253:2 512 1 writethrough smq
                   │      │      │    │           │        └── Policy
                   │      │      │    │           └── Cache mode
                   │      │      │    └── Block size (256K)
                   │      │      └── Cache metadata (SSD)
                   │      └── Cache data (SSD)
                   └── Origin (HDD)
```

### udev Integration

When LVM creates a DM device:
1. dmsetup ioctl creates the device -> kernel sends uevent
2. udev matches rules: `10-dm.rules`, `13-dm-disk.rules`, `56-lvm.rules`
3. udev creates `/dev/dm-N`, `/dev/vg_data/lv_home`, `/dev/mapper/vg_data-lv_home`

### VG Metadata Format

```lvm
# /etc/lvm/archive/vg_data_00001.vg (human-readable text)
vg_data {
    id = "abcdefg-hijklmn-opqrstu-..."
    seqno = 5
    format = "lvm2"
    extent_size = 8192           # 8192 sectors = 4 MiB PE
    physical_volumes {
        pv0 { id = "..."; device = "/dev/sdb"; pe_start = 2048; pe_count = 25599; }
    }
    logical_volumes {
        lv_home {
            segment1 {
                start_extent = 0
                extent_count = 2560    # 10 GiB
                type = "striped"
                stripe_count = 1
                stripes = [ "pv0", 0 ] # PV pv0, PE start 0
            }
        }
    }
}
```

### LVM Activation (Boot Sequence)

```
1. initramfs: load dm-mod → pvscan → vgscan → vgchange -ay
2. udev creates /dev/mapper/ and /dev/vg_name/ symlinks
3. Root filesystem mounted from LV
4. pivot_root → full system boot
5. lvm2-monitor.service starts dmeventd for auto-extend
```

### Key lvm.conf Sections

```
devices {
    filter = [ "a|sd.*|", "r|loop.*|", "r|.*|" ]
    global_filter = [ "r|/dev/dm-.*|", "a|.*|" ]
}
activation {
    snapshot_autoextend_threshold = 80
    snapshot_autoextend_percent = 20
    thin_pool_autoextend_threshold = 80
    thin_pool_autoextend_percent = 20
}

# Check current config:
sudo lvmconfig --type diff
sudo lvmconfig --type current
```

---



---

[← Previous](19-section-12-troubleshooting-advanced.md) | [↑ Index](index.md) | [Next →](21-practice-section-15-hands-on-exercises.md)
