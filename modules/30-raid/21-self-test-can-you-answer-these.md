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

---

*Linux SysAdmin Course | Part 30 of ∞ | Reverse Engineering Approach*
*Previous → Part 29: Samba and Windows Interoperability*
*Next → Part 31: LVM — Logical Volume Manager*

[← Previous](part29.md) | [Next →](part31.md)


---

[← Previous](20-whats-coming-in-part-31.md) | [↑ Index](index.md)
