## 🔍 Section 12: Troubleshooting — Advanced

### dmsetup

```bash
sudo dmsetup ls                           # All DM devices
sudo dmsetup table                        # Mapping tables
sudo dmsetup table vg_data-lv_home        # Specific LV mapping
sudo dmsetup deps vg_data-lv_home         # Dependencies
sudo dmsetup info vg_data-lv_home         # Info
```

### pvck — Check PV Metadata

```bash
sudo pvck /dev/sdb                       # Check integrity
sudo pvck --dump /dev/sdb                # Dump metadata
sudo pvck --repair /dev/sdb              # Repair label
```

### vgcfgrestore — Restore VG Metadata

```bash
ls -la /etc/lvm/archive/vg_data_*       # List archive versions
sudo vgcfgrestore -l vg_data            # Show versions
sudo vgcfgrestore -f /etc/lvm/archive/vg_data_00005.vg vg_data  # Restore
```

### lvm.conf Filters

```bash
# /etc/lvm/lvm.conf — devices { filter = [...] }
# "a|pattern|" = accept, "r|pattern|" = reject, first match wins
# Example: accept sd* and nvme*, reject everything else
# filter = [ "a|/dev/sd.*|", "a|/dev/nvme.*|", "r|.*|" ]

# Test filter without modifying config:
sudo pvs --config 'devices { filter = [ "r|loop.*|", "a|.*|" ] }'
```





[← Previous](18-section-10-lvm-raid.md) | [↑ Index](index.md) | [Next →](20-deep-understanding-how-lvm-really.md)
