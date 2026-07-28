## ⭐ Level 1: Basic — RAID Fundamentals

![RAID levels comparison — striping, mirroring, parity explained](https://i.pinimg.com/736x/0e/95/cb/0e95cba62afcd7b1c917b45ae24ff761.jpg)

*RAID types overview — from basic striping to hybrid RAID 10 (Sony Camera Central / Pinterest)*

> **Level 1 Goal:** Understand what RAID is, the differences between RAID levels 0/1/5/6/10, and how to create your first RAID array with `mdadm`.

### What You'll Cover
- What RAID is and why redundancy matters for data protection
- RAID 0: striping for performance (no redundancy)
- RAID 1: mirroring for redundancy (half usable capacity)
- RAID 5: single-parity striping (distributed XOR)
- RAID 6: dual-parity striping (two-drive fault tolerance)
- RAID 10: stripe of mirrors (performance + redundancy)
- Creating your first array with `mdadm --create`
- Viewing array status with `/proc/mdstat` and `mdadm --detail`


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-raid.md)
