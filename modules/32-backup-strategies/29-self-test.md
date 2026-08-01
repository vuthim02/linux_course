## 📝 Self-Test
1. What does the "2" in the 3-2-1 backup rule refer to?
2. What is the difference between RPO and RTO?
3. An incremental backup captures changes since __________. A differential backup captures changes since __________.
4. When using `rsync --link-dest`, what happens to files that haven't changed?
5. What does `conv=sync,noerror` do in `dd`?
6. What is the purpose of the mapfile in `ddrescue`?
7. In Borg, what is the difference between `repokey` and `keyfile` encryption?
8. What does `restic forget --keep-daily 7 --prune` do?
9. Why is a file-level backup of a running MySQL database potentially inconsistent?
10. What does `mysqldump --single-transaction` guarantee?
11. Why must you test restores, not just backups?
12. What is the difference between incremental backup and deduplication?
13. How does `fsync` affect backup reliability?
14. What is a sparse file, and why does its handling matter?
15. In `tar --listed-incremental`, what is stored in the `.snar` file?
**Score:** 12/15 correct = ready for Part 33.
## Answer Key
### Q1: What does the "2" in the 3-2-1 backup rule refer to?
**Answer:** 3 copies of data, on **2** different media types, with 1 copy offsite.
### Q2: What is the difference between RPO and RTO?
**Answer:** RPO (Recovery Point Objective) = maximum acceptable data loss (time). RTO (Recovery Time Objective) = maximum acceptable downtime.
### Q3: Incremental vs differential backup.
**Answer:** Incremental captures changes since the **last backup** (any type). Differential captures changes since the **last full backup**.
### Q4: What happens with `rsync --link-dest` for unchanged files?
**Answer:** Unchanged files are hard-linked to the previous backup, saving disk space (no duplication).
### Q5: What does `conv=sync,noerror` do in `dd`?
**Answer:** `sync` pads unreadable blocks with zeros. `noerror` continues past read errors instead of aborting.
### Q6: What is the purpose of the mapfile in ddrescue?
**Answer:** Maps good/bad/retry sectors on the source disk. Allows resuming interrupted recovery and prioritizes good sectors first.
### Q7: repokey vs keyfile encryption in Borg?
**Answer:** `repokey` stores the encryption key in the repo config. `keyfile` stores the key in a separate local file (better security: key never touches the repo).
### Q8: What does `restic forget --keep-daily 7 --prune` do?
**Answer:** Keeps the most recent backup from each of the last 7 days, deletes older ones. `--prune` removes unreferenced data from the repository.
### Q9: Why is file-level backup of a running MySQL potentially inconsistent?
**Answer:** Files may be mid-write (e.g., partially updated table). InnoDB needs crash-consistent snapshot or `FLUSH TABLES WITH READ LOCK`.
### Q10: What does `mysqldump --single-transaction` guarantee?
**Answer:** Creates a consistent snapshot using InnoDB's MVCC. The dump sees a consistent point-in-time view without locking tables.
### Q11: Why must you test restores?
**Answer:** An untested backup is not a backup. Corruption, incomplete data, or incorrect procedures may only be discovered during a restore attempt.
### Q12: Incremental backup vs deduplication?
**Answer:** Incremental = only backs up changes since last backup. Deduplication = stores only unique blocks across all data (even within a single backup).
### Q13: How does `fsync` affect backup reliability?
**Answer:** Forces pending writes to disk. Without fsync, data may exist only in OS cache. `conv=fsync` in dd ensures data reaches disk before completing.
### Q14: What is a sparse file and why does handling matter?
**Answer:** A file with "holes" (unallocated blocks shown as zeros). `tar --sparse` detects and stores sparsely (smaller archive). Ignoring holes wastes space.
### Q15: What is stored in the `.snar` file for `tar --listed-incremental`?
**Answer:** Snapshot of file states (mtime, ctime, inode) from the previous backup. tar uses it to identify which files changed for the incremental.
*Previous → Part 31: LVM*
*Next → Part 33: System Monitoring*
[← Previous](28-whats-coming-in-part-33.md) | [↑ Index](index.md)
