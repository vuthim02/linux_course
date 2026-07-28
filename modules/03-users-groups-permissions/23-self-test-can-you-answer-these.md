## 📝 Self-Test — Can You Answer These?

1. What do `r`, `w`, and `x` mean on a **directory** (not a file)?
2. Convert `-rwxr-x---` to numeric permissions.
3. Convert `751` to symbolic permissions.
4. What does `chmod u+s` do? When would you use it?
5. What is the purpose of the Sticky Bit? Where do you see it by default?
6. What is the difference between `/etc/passwd` and `/etc/shadow`?
7. How do you add a user to the `sudo` group without removing them from other groups?
8. What happens when you set SGID on a directory?
9. Why can a regular user run `passwd` even though it writes to root-owned `/etc/shadow`?
10. What is `umask 0027` in terms of resulting file and directory permissions?
11. How do you view the ACL of a file?
12. How would you give user `bob` read/write access to a file without changing its owner or group?
13. What is the difference between `sudo -s` and `sudo -i`?
14. A user reports: "I was added to the `developers` group but I still can't access the shared directory." What is the most likely cause?
15. How do you find all files on the system with the SUID bit set?

**Score:** 12/15 correct = ready for Part 4.


## Answer Key

### Q1: What do `r`, `w`, and `x` mean on a directory?
**Answer:** `r` = list directory contents (ls), `w` = create/delete files inside, `x` = enter the directory (cd).

### Q2: Convert `-rwxr-x---` to numeric permissions.
**Answer:** 750 (rwx=7, r-x=5, ---=0).

### Q3: Convert `751` to symbolic permissions.
**Answer:** `-rwxr-x--x` (7=rwx, 5=r-x, 1=--x).

### Q4: What does `chmod u+s` do?
**Answer:** Sets the SUID (Set User ID) bit. When executed, the file runs with the permissions of the file owner (not the executing user). Used for programs like `passwd` that need root access.

### Q5: What is the purpose of the Sticky Bit? Where do you see it by default?
**Answer:** Prevents users from deleting files they don't own in a shared directory. Default on `/tmp` (shows as `drwxrwxrwt` with `t`).

### Q6: What is the difference between `/etc/passwd` and `/etc/shadow`?
**Answer:** `/etc/passwd` stores user account info (username, UID, GID, home, shell) in plaintext. `/etc/shadow` stores hashed passwords and password policies, readable only by root.

### Q7: How do you add a user to the `sudo` group without removing them from other groups?
**Answer:** `sudo usermod -aG sudo username` — the `-a` flag appends (doesn't replace existing groups).

### Q8: What happens when you set SGID on a directory?
**Answer:** New files created inside inherit the group of the directory (not the creator's group). Subdirectories also inherit the SGID bit.

### Q9: Why can a regular user run `passwd` even though it writes to root-owned `/etc/shadow`?
**Answer:** `passwd` has the SUID bit set, so it runs with root privileges when any user executes it.

### Q10: What is `umask 0027` in terms of resulting file and directory permissions?
**Answer:** Files get 640 (`rw-r-----`), directories get 750 (`rwxr-x---`). The umask removes permissions from the base (666 for files, 777 for dirs).

### Q11: How do you view the ACL of a file?
**Answer:** `getfacl filename` — shows the Access Control List entries.

### Q12: How would you give user `bob` read/write access to a file without changing its owner or group?
**Answer:** `setfacl -m u:bob:rw filename` — sets an ACL entry for bob.

### Q13: What is the difference between `sudo -s` and `sudo -i`?
**Answer:** `sudo -s` opens a shell as root but keeps the current user's environment. `sudo -i` simulates a full root login (loads root's profile, changes to root's home).

### Q14: A user reports they were added to `developers` but can't access the shared directory. What is the most likely cause?
**Answer:** The user needs to log out and back in for group changes to take effect, or the directory's permissions/group ownership don't include the `developers` group.

### Q15: How do you find all files on the system with the SUID bit set?
**Answer:** `find / -type f -perm -4000` — finds all files with the user SUID bit (4000 in octal).


*Linux SysAdmin Course | Part 3 of ∞ | Reverse Engineering Approach*
*Previous → Part 2: Mastering the Terminal — Navigation, Files & Directories*
*Next → Part 4: Text Editors — Vim, Nano, and Why They Matter*

[← Previous](part2.md) | [Next →](part4.md)



[← Previous](22-whats-coming-in-part-4.md) | [↑ Index](index.md)
