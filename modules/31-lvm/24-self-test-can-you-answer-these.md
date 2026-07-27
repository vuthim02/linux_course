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

---

*Linux SysAdmin Course | Part 31 of ∞ | Reverse Engineering Approach*
*Previous → Part 30: RAID*
*Next → Part 32: Backup Strategies*

[← Previous](part30.md) | [Next →](part32.md)


---

[← Previous](23-whats-coming-in-part-32.md) | [↑ Index](index.md)
