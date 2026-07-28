## 📝 Self-Test — Can You Answer These?

1. What are the three layers of LVM abstraction, and what problem does each solve?
2. What is the difference between a PE (Physical Extent) and an LE (Logical Extent)?
3. How does PE size affect maximum VG size and metadata overhead?
4. What command initializes a block device as a Physical Volume, and how do you verify it?
5. How do you extend a Volume Group to include a new disk?
6. What is the correct order of operations when shrinking an ext4 filesystem on a Logical Volume?
7. How does a COW (Copy-on-Write) snapshot work at the block level? What happens when the snapshot store fills up?
8. What is the difference between thin provisioning and thick (default) LVs? What are the risks of thin overcommit?
9. How does LVM cache work? What is writethrough vs writeback mode, and what are the tradeoffs?
10. When creating a striped LV, what does the `-i` and `-I` flag control, and what is the minimum number of PVs required?
11. How does LVM RAID 1 differ from a regular linear LV? What internal device names (rimage, rmeta) appear in `lvs -a`?
12. What is the difference between LUKS on LVM and LVM on LUKS? When would you choose each approach?
13. A PV in your VG has failed. What steps would you take to recover the VG and its LVs?
14. What does `dmsetup table` show, and how does a linear mapping table translate LV blocks to physical disk sectors?
15. What is the purpose of `dmeventd`, and what auto-extend capabilities does it provide?

**Score:** 12/15 correct = ready for Part 32.


## Answer Key

### Q1: What are the three layers of LVM abstraction?
**Answer:** PV (Physical Volume) = raw disk/partition. VG (Volume Group) = pool of PVs. LV (Logical Volume) = carveable storage from a VG, presented as a block device.

### Q2: What is the difference between PE and LE?
**Answer:** PE (Physical Extent) = smallest allocatable unit in a PV/VG. LE (Logical Extent) = smallest unit in an LV. In a basic LV, PE = LE.

### Q3: How does PE size affect maximum VG size?
**Answer:** Larger PE = larger max VG size but more wasted space for small LVs. Default PE = 4MB → max VG = 256TB. `vgcreate -s 64M` sets larger PE.

### Q4: What command initializes a PV and how do you verify?
**Answer:** `pvcreate /dev/sdX`. Verify: `pvs` or `pvdisplay` — shows PV with size, free space, and VG membership.

### Q5: How do you extend a VG with a new disk?
**Answer:** `vgextend vgname /dev/sdX` — adds the PV to the VG pool.

### Q6: Correct order for shrinking ext4 on an LV?
**Answer:** 1) `e2fsck -f /dev/vg/lv`, 2) `resize2fs /dev/vg/lv 10G`, 3) `lvreduce -L 10G /dev/vg/lv` (always shrink filesystem first, then LV).

### Q7: How does a COW snapshot work?
**Answer:** Original blocks are copied to the snapshot volume before overwriting. When snapshot store fills, the snapshot becomes invalid (must be extended or removed).

### Q8: What is thin provisioning vs thick LVs?
**Answer:** Thick = full allocation upfront. Thin = over-committed, allocated on demand. Risk: thin overcommit can cause data loss if pool runs out.

### Q9: How does LVM cache work?
**Answer:** Uses dm-cache to put a fast device (SSD) in front of a slow device (HDD). Writethrough: data written to both. Writeback: data written to cache first (faster, risk of loss).

### Q10: What do `-i` and `-I` flags control in striped LVs?
**Answer:** `-i` = number of stripes (minimum PVs required). `-I` = stripe size (e.g., 64K). More stripes = better parallel I/O.

### Q11: How does LVM RAID 1 differ from linear LV?
**Answer:** LVM RAID 1 mirrors data across PVs. Internal devices: `rimage_0` (data) and `rmeta_0` (metadata) for each leg, visible in `lvs -a`.

### Q12: LUKS on LVM vs LVM on LUKS?
**Answer:** LUKS on LVM: encrypt individual LVs (flexible, can snapshot unencrypted). LVM on LUKS: encrypt entire PV (simpler, single passphrase for all LVs).

### Q13: Steps to recover a VG after PV failure?
**Answer:** 1) `vgreduce --removemissing vgname`, 2) Replace the failed disk, 3) `pvcreate /dev/newdisk`, 4) `vgextend vgname /dev/newdisk`, 5) Resync with `pvmove`.

### Q14: What does `dmsetup table` show?
**Answer:** Device-mapper target table — shows the linear mapping from LV blocks to physical disk sectors (e.g., 0 2097152 linear 8:17 2048).

### Q15: What is the purpose of `dmeventd`?
**Answer:** Monitors device-mapper events. Auto-extends thin pools and mirrors when they reach thresholds (e.g., extends thin pool at 80% full).


*Linux SysAdmin Course | Part 31 of ∞ | Reverse Engineering Approach*
*Previous → Part 30: RAID*
*Next → Part 32: Backup Strategies*

[← Previous](part30.md) | [Next →](part32.md)



[← Previous](23-whats-coming-in-part-32.md) | [↑ Index](index.md)
