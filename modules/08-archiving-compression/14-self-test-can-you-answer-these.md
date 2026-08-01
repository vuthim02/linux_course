## 📝 Self-Test — Can You Answer These?
1. What is the difference between archiving and compression?
2. What does `tar -czf archive.tar.gz dir/` do?
3. How do you list the contents of a `.tar.gz` file without extracting?
4. How do you extract a tar.gz to a specific directory?
5. What is the difference between gzip, bzip2, and xz?
6. How do you create a tar archive that excludes `.log` files?
7. What does `tar -xf archive.tar.gz file.txt` do?
8. How do you view a compressed text file without decompressing it?
9. What utility would you use to search for "error" inside a .gz file?
10. How do you create a password-protected zip file?
11. What is the `-C` option in tar used for?
12. What does `zcat` do?
13. How would you split a large tar.gz into 50MB pieces?
14. What is the `--exclude` option in tar used for?
15. Why does re-compressing a compressed file not help?
**Score:** 12/15 correct = ready for Part 9.
## Answer Key
### Q1: What is the difference between archiving and compression?
**Answer:** Archiving bundles multiple files into one file (tar). Compression reduces file size (gzip, bzip2, xz). Often combined: `tar -czf` archives and compresses.
### Q2: What does `tar -czf archive.tar.gz dir/` do?
**Answer:** Creates (`-c`) a gzipped (`-z`) tar archive named `archive.tar.gz` from the `dir/` directory.
### Q3: How do you list the contents of a `.tar.gz` file without extracting?
**Answer:** `tar -tzf archive.tar.gz` — lists (`-t`) all files in the gzipped archive.
### Q4: How do you extract a tar.gz to a specific directory?
**Answer:** `tar -xzf archive.tar.gz -C /target/directory` — the `-C` flag changes to the target directory before extracting.
### Q5: What is the difference between gzip, bzip2, and xz?
**Answer:** gzip: fast, moderate compression (most common). bzip2: slower, better compression. xz: slowest, best compression ratio. All are single-file compressors.
### Q6: How do you create a tar archive that excludes `.log` files?
**Answer:** `tar -czf archive.tar.gz --exclude="*.log" dir/`
### Q7: What does `tar -xf archive.tar.gz file.txt` do?
**Answer:** Extracts only `file.txt` from the archive (not the entire archive).
### Q8: How do you view a compressed text file without decompressing it?
**Answer:** `zcat file.gz` (or `zless`, `zgrep`, `zmore`) — reads gzipped files directly.
### Q9: What utility would you use to search for "error" inside a .gz file?
**Answer:** `zgrep "error" file.gz` — searches inside gzipped files without manual decompression.
### Q10: How do you create a password-protected zip file?
**Answer:** `zip -e archive.zip file.txt` (prompts for password) or `7z a -p archive.zip file.txt`.
### Q11: What is the `-C` option in tar used for?
**Answer:** Changes directory before performing the operation. `tar -xf file.tar -C /dir` extracts into `/dir`.
### Q12: What does `zcat` do?
**Answer:** Decompresses a gzip file to stdout. Equivalent to `gunzip -c`.
### Q13: How would you split a large tar.gz into 50MB pieces?
**Answer:** `tar -czf - dir/ | split -b 50M - archive.tar.gz.part` — splits the output into 50MB chunks.
### Q14: What is the `--exclude` option in tar used for?
**Answer:** Excludes files matching a pattern from the archive. E.g., `--exclude="*.log"`.
### Q15: Why does re-compressing a compressed file not help?
**Answer:** Compressed data has very low entropy — there's little redundancy left to exploit. Re-compression may even increase size due to format overhead.
*Linux SysAdmin Course | Part 8 of ∞ | Reverse Engineering Approach*
*Previous → Part 7: Finding Things — grep, find, locate, and Beyond*
*Next → Part 9: Process Management — ps, top, kill, and Signals*
[← Previous](13-whats-coming-in-part-9.md) | [↑ Index](index.md)
