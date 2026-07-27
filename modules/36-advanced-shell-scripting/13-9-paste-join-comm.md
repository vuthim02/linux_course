## 9. paste, join, comm

### 9.1 paste — Merge Lines Column-Wise

```bash
# Side by side
paste file1 file2                   # tab-delimited columns
paste -d, file1 file2              # comma delimiter
paste -d'|' file1 file2            # pipe delimiter

# Serial paste
paste -s file1                     # all lines on one line (tab)
paste -sd, file1                   # all lines, comma-separated

# Interleave lines
paste - - < file.txt               # pairs of lines
paste - - - < file.txt             # groups of 3 lines
```

```bash
# Combine header and data
echo "User:UID:Shell" | cat - /etc/passwd | head -1

# Create CSV from columns
paste -d, users.txt uids.txt shells.txt
```

### 9.2 join — Relational Join on Common Field

```bash
# Requires sorted input
join -t: -1 1 -2 1 users.txt groups.txt     # join on field 1
join -t, -j1 -o 1.1,2.2 file1.csv file2.csv

# Outer joins
join -a1 file1 file2              # left outer join
join -a2 file1 file2              # right outer join
join -a1 -a2 file1 file2          # full outer join

# Custom output format
join -o 1.1,2.2,1.3 -t: /etc/passwd /etc/group
# 1.1 = file1 field1, 2.2 = file2 field2, 1.3 = file1 field3
```

```bash
# Example: join passwd with group info
sort -t: -k4 /etc/passwd > passwd_by_gid
sort -t: -k3 /etc/group > group_by_gid
join -t: -1 4 -2 3 -o 1.1,2.1 passwd_by_gid group_by_gid | head
```

### 9.3 comm — Compare Two Sorted Files

```bash
comm file1 file2                   # 3-column output
comm -1 file1 file2                # suppress column 1
comm -2 file1 file2                # suppress column 2
comm -3 file1 file2                # suppress column 3
comm -12 file1 file2               # only lines in both (intersection)
comm -23 file1 file2               # lines only in file1
comm -13 file1 file2               # lines only in file2
```

```bash
# Compare package lists between two servers
ssh server1 'dpkg -l | awk "NR>5 {print \$2}"' | sort > pkgs_1.txt
ssh server2 'dpkg -l | awk "NR>5 {print \$2}"' | sort > pkgs_2.txt
comm -3 pkgs_1.txt pkgs_2.txt      # differences
comm -12 pkgs_1.txt pkgs_2.txt     # common packages
```

---



---

[← Previous](12-8-cut-sort-uniq-wc.md) | [↑ Index](index.md) | [Next →](14-10-xargs-building-command-lines.md)
