## 🔍 Section 11: LVM and Encryption

### LUKS on LVM

Encrypt specific LVs (e.g., /home) while leaving others unencrypted:

```
┌──────────────────┐
│ Filesystem       │
├──────────────────┤
│ LUKS (dm-crypt) │
├──────────────────┤
│ LV               │
├──────────────────┤
│ VG / PV          │
└──────────────────┘
```

```bash
sudo lvcreate -L 20G -n lv_secure vg_data
sudo cryptsetup luksFormat /dev/vg_data/lv_secure
sudo cryptsetup open /dev/vg_data/lv_secure secure
sudo mkfs.ext4 /dev/mapper/secure
sudo mount /dev/mapper/secure /mnt/secure
```

### LVM on LUKS

Full-disk encryption — LVM on top of encrypted devices:

```
┌──────────────────┐
│ Filesystem       │
├──────────────────┤
│ LV               │
├──────────────────┤
│ VG               │
├──────────────────┤
│ PV               │
├──────────────────┤
│ LUKS (dm-crypt) │
├──────────────────┤
│ Block device     │
└──────────────────┘
```

```bash
sudo cryptsetup luksFormat /dev/sdb
sudo cryptsetup open /dev/sdb crypt_disk
sudo pvcreate /dev/mapper/crypt_disk
sudo vgcreate vg_encrypted /dev/mapper/crypt_disk
sudo lvcreate -L 50G -n lv_data vg_encrypted
sudo mkfs.ext4 /dev/vg_encrypted/lv_data
```





[← Previous](13-section-8-lvm-cache.md) | [↑ Index](index.md) | [Next →](15-section-12-troubleshooting-basic.md)
