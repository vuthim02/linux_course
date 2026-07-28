## ⭐ Level 1: Basic — Backup Philosophy and Classic Tools

![3-2-1 backup rule diagram — three copies, two media, one offsite](https://upload.wikimedia.org/wikipedia/commons/8/84/Backup_3-2-1_Rule_Diagram.svg)

> **Level 1 Goal:** Understand the 3-2-1 backup philosophy, master `tar` for archiving, use `rsync` for local/remote sync, and clone disks with `dd`.

### What You'll Cover
- The 3-2-1 rule: three copies, two media types, one offsite
- RPO and RTO — defining acceptable data loss and downtime
- `tar`: creating, extracting, compressing archives (gzip, xz, bzip2)
- `rsync`: local and remote sync with delta transfers
- `dd`: block-level disk cloning and imaging
- When to use each tool and their trade-offs

Backup strategy matters more than backup tools. Before choosing `tar` vs `rsync`, you need to define how much data you can afford to lose (RPO) and how quickly you must recover (RTO).

At this level you will learn:

- **3-2-1 rule**: Keep 3 copies of data, on 2 different media types, with 1 copy offsite. This protects against hardware failure, fire/theft, and corruption. Modern extensions include 3-2-1-1-0 (add 1 copy offline/immutable, 0 errors in backup verification).
- **RPO/RTO**: Recovery Point Objective is the maximum acceptable data loss (e.g., 24 hours means daily backups). Recovery Time Objective is the maximum acceptable downtime (e.g., 4 hours). These drive your backup frequency and recovery infrastructure.
- **`tar`**: `tar czf backup.tar.gz /data` creates a gzip archive. `tar xzf backup.tar.gz` extracts it. `tar cjf` uses bzip2 (slower, smaller). `tar cJf` uses xz (slowest, smallest). `tar` preserves permissions, ownership, and symlinks.
- **`rsync`**: `rsync -avz /data/ remote:/backup/` syncs with delta transfers — only changed blocks are transferred. The `-a` flag preserves permissions, ownership, timestamps. `-v` is verbose, `-z` compresses during transfer.
- **`dd`**: `dd if=/dev/sda of=/backup/disk.img bs=4M` clones a disk at the block level. Useful for forensics and exact replicas. Warning: `dd` does not compress, and a wrong `of=` target will destroy data.


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-backup-philosophy.md)
