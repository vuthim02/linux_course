## 📝 Self-Test — Can You Answer These?
1. How do you search for "error" case-insensitively in a file?
2. What does `grep -c "error" file.log` do?
3. What is the difference between `*` and `+` in regular expressions?
4. How do you search for lines that start with "ERROR"?
5. How do you show 5 lines of context before and after a match?
6. How do you find all files larger than 100MB?
7. How do you find files modified in the last 7 days?
8. What does `find . -name "*.tmp" -delete` do?
9. What is the difference between `find` and `locate`?
10. How do you update the locate database?
11. When would you use `rg` instead of `grep`?
12. What does `find . -type f -perm -4000` find?
13. How do you find all empty files in a directory?
14. Write a command to find all `.conf` files containing the word "Port".
15. How do you count unique IP addresses in a log file?
**Score:** 12/15 correct = ready for Part 8.
## Answer Key
### Q1: How do you search for "error" case-insensitively in a file?
**Answer:** `grep -i "error" filename` — the `-i` flag ignores case.
### Q2: What does `grep -c "error" file.log` do?
**Answer:** Counts the number of lines containing "error" instead of printing them.
### Q3: What is the difference between `*` and `+` in regular expressions?
**Answer:** `*` means zero or more of the preceding character. `+` (ERE) means one or more of the preceding character.
### Q4: How do you search for lines that start with "ERROR"?
**Answer:** `grep "^ERROR" filename` — the `^` anchors to the beginning of the line.
### Q5: How do you show 5 lines of context before and after a match?
**Answer:** `grep -B5 -A5 "pattern" filename` or `grep -C5 "pattern" filename`.
### Q6: How do you find all files larger than 100MB?
**Answer:** `find / -type f -size +100M`
### Q7: How do you find files modified in the last 7 days?
**Answer:** `find / -type f -mtime -7`
### Q8: What does `find . -name "*.tmp" -delete` do?
**Answer:** Finds all `.tmp` files in the current directory tree and deletes them.
### Q9: What is the difference between `find` and `locate`?
**Answer:** `find` searches the filesystem in real-time (slower but always current). `locate` uses a pre-built database (faster but may be outdated).
### Q10: How do you update the locate database?
**Answer:** `sudo updatedb` — rebuilds the `mlocate.db` database.
### Q11: When would you use `rg` instead of `grep`?
**Answer:** `rg` (ripgrep) is faster, recursively searches by default, respects `.gitignore`, and auto-detects file types. Best for codebase searching.
### Q12: What does `find . -type f -perm -4000` find?
**Answer:** All files with the SUID bit set (permission 4000 or higher).
### Q13: How do you find all empty files in a directory?
**Answer:** `find /path -type f -empty`
### Q14: Write a command to find all `.conf` files containing the word "Port".
**Answer:** `find / -name "*.conf" -exec grep -l "Port" {} +`
### Q15: How do you count unique IP addresses in a log file?
**Answer:** `awk '{print $1}' access.log | sort -u | wc -l` (adjust field number as needed).
*Linux SysAdmin Course | Part 7 of ∞ | Reverse Engineering Approach*
*Previous → Part 6: Shell Scripting — Automate Everything*
*Next → Part 8: Archiving and Compression — tar, gzip, zip*
[← Previous](12-whats-coming-in-part-8.md) | [↑ Index](index.md)
