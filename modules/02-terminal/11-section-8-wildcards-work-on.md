## 🔍 Section 8: Wildcards — Work on Many Files at Once

Wildcards let you match multiple files with a pattern. The **shell expands** wildcards before the command runs.

| Wildcard | Meaning | Example |
|----------|---------|---------|
| `*` | Match anything (zero or more characters) | `*.txt` = all .txt files |
| `?` | Match exactly one character | `file?.txt` = file1.txt, fileA.txt |
| `[abc]` | Match one character from the set | `file[123].txt` = file1.txt, file2.txt, file3.txt |
| `[a-z]` | Match one character in range | `file[a-z].txt` = filea.txt, fileb.txt |
| `[!abc]` | Match any character NOT in set | `file[!0-9].txt` = files not ending in numbers |
| `{a,b,c}` | Match any of these exact strings | `{*.txt,*.log}` = all txt and log files |

### Wildcard Examples

```bash
ls *.txt                    # All files ending in .txt
ls file*                    # All files starting with "file"
ls file?.txt                # file1.txt, fileA.txt, but NOT file10.txt
ls /var/log/*.log           # All log files in /var/log
cp *.conf /backup/          # Copy all config files to backup
rm temp_*                   # Delete all files starting with temp_
ls [Ff]ile.txt              # Match File.txt or file.txt
ls /dev/sd[a-z]             # Match sda, sdb, sdc... (all physical disks)
```

> 🔍 **How wildcards work — the shell expands them FIRST:**
> When you type `ls *.txt`, bash doesn't pass `*.txt` to `ls`. It first expands `*.txt` into the actual list of matching files, THEN runs `ls file1.txt file2.txt file3.txt`.
> This is why wildcards work with ANY command.





[← Previous](10-level-2-intermediary-advanced-file.md) | [↑ Index](index.md) | [Next →](12-section-9-finding-files-find.md)
