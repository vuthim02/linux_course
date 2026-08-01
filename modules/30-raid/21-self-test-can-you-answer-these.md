## 📝 Self-Test — Can You Answer These?
1. What is the difference between RAID 0 and RAID 1? When would you use each?
2. How does RAID 5 parity work? What mathematical operation is used for the first parity block?
3. What is the RAID 5 write hole? How does a write-intent bitmap mitigate it?
4. How many drives minimum are needed for RAID 6? For RAID 10? What are the effective capacities with 4 × 1 TiB drives?
5. What does the output `[UU_U]` mean in `/proc/mdstat`? What action would you take?
6. What is a hot spare and what determines when it activates? What happens to the spare after the failed drive is replaced?
7. What does `mdadm --fail` do to a drive? Does it destroy the data on that drive?
8. How do you add an internal write-intent bitmap to an existing RAID 5 array? What command and parameters?
9. What is the difference between superblock formats 0.90, 1.0, 1.1, and 1.2? Which is the modern default?
10. In the LVM-on-RAID stack, which component goes first? Why is the reverse order (RAID on LVM) a bad idea?
11. What is the RAID 5 write penalty? Why does a random 4 KiB write to RAID 5 require 4 physical I/Os?
12. Why is RAID 10 preferred over RAID 5 for database workloads? Compare the write IOPS of each with 8 drives.
13. What is a foreign configuration on a hardware RAID controller? How do you import or clear it?
14. What is the role of the BBU on a hardware RAID controller? What happens during a learn cycle?
15. In RAID 6, what is the difference between the P and Q parity blocks? Why can't you derive Q from P?
**Score:** 12/15 correct = ready for Part 31.
## Answer Key
### Q1: What is the difference between RAID 0 and RAID 1?
**Answer:** RAID 0 = striping (performance, no redundancy, one drive fails = all data lost). RAID 1 = mirroring (full redundancy, 50% capacity).
### Q2: How does RAID 5 parity work?
**Answer:** XOR parity blocks are distributed across all drives. First parity block = A XOR B. Allows one drive failure. Capacity = (N-1) × drive size.
### Q3: What is the RAID 5 write hole?
**Answer:** During parity update, a crash mid-write leaves inconsistent parity. Write-intent bitmaps track dirty regions to detect and repair this.
### Q4: Minimum drives and capacity for RAID 6 and RAID 10?
**Answer:** RAID 6: 4 drives min, capacity = (N-2) × size (2 drive fault tolerance). RAID 10: 4 drives min, capacity = N/2 × size (mirrored stripes).
### Q5: What does `[UU_U]` mean in `/proc/mdstat`?
**Answer:** One drive is marked faulty (U=healthy, _=faulty/fail). Replace the failed drive immediately: `mdadm --manage /dev/md0 --add /dev/sdX`.
### Q6: What is a hot spare?
**Answer:** A standby drive that automatically activates when a drive fails. After rebuilding, the spare remains active (the replaced drive becomes the new spare).
### Q7: What does `mdadm --fail` do?
**Answer:** Marks a drive as faulty in the array. Does NOT destroy data — the array continues degraded until the drive is replaced.
### Q8: How do you add a write-intent bitmap to an existing RAID 5?
**Answer:** `mdadm --grow /dev/md0 --bitmap=internal` — adds an internal bitmap to track dirty regions.
### Q9: What is the difference between superblock formats?
**Answer:** 0.90 = legacy (128MB max, at start). 1.0 = modern default (at end of device). 1.1 = at start (allows boot). 1.2 = at 4K offset.
### Q10: LVM-on-RAID vs RAID-on-LVM?
**Answer:** LVM on RAID is correct (RAID provides redundancy, LVM provides flexibility). RAID on LVM is bad because LVM stripes span multiple PVs, defeating RAID protection.
### Q11: What is the RAID 5 write penalty?
**Answer:** A 4KB random write requires: read old data + read old parity + write new data + write new parity = 4 I/Os per write.
### Q12: Why is RAID 10 preferred over RAID 5 for databases?
**Answer:** RAID 10 has no parity calculation overhead. With 8 drives: RAID 10 = 8× write IOPS. RAID 5 = 2× write IOPS (4 I/O penalty).
### Q13: What is a foreign configuration on hardware RAID?
**Answer:** A configuration from another controller or a replaced controller. Import it with the controller BIOS utility, or clear it and create new arrays.
### Q14: What is the role of the BBU?
**Answer:** Battery Backup Unit keeps the RAID cache powered during outages. During a learn cycle, the BBU calibrates to measure actual battery capacity.
### Q15: What is the difference between P and Q parity in RAID 6?
**Answer:** P parity = XOR (same as RAID 5). Q parity = Reed-Solomon (GF math). Q cannot be derived from P because they use different algorithms for dual-fault tolerance.
*Linux SysAdmin Course | Part 30 of ∞ | Reverse Engineering Approach*
*Previous → Part 29: Samba and Windows Interoperability*
*Next → Part 31: LVM — Logical Volume Manager*
[← Previous](20-whats-coming-in-part-31.md) | [↑ Index](index.md)
