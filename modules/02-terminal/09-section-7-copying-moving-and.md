## 🔍 Section 7: Copying, Moving, and Renaming

### `cp` — Copy Files and Directories

```bash
cp file.txt backup.txt              # Copy file to new name (same directory)
cp file.txt /tmp/file.txt           # Copy file to different directory
cp file.txt /tmp/                   # Same — directory destination keeps original name
cp -r projects/ backup_projects/    # Copy a directory and ALL its contents
cp -p file.txt backup.txt           # Preserve permissions and timestamps
cp -i file.txt dest.txt             # Ask before overwriting (interactive)
cp -u file.txt dest.txt             # Only copy if source is newer
cp *.txt /backup/                   # Copy all .txt files to /backup/
```

> ⚠️ Without `-r`, you cannot copy a directory. You will get an error:
> ```
> cp: -r not specified; omitting directory 'projects/'
> ```

### `mv` — Move AND Rename (Same Command!)

```bash
mv old.txt new.txt                  # Rename a file
mv file.txt /tmp/                   # Move file to /tmp/
mv file.txt /tmp/newname.txt        # Move AND rename at once
mv projects/ /var/www/              # Move entire directory
mv *.log /var/log/archive/          # Move all .log files
```

> 🔍 **Reverse Engineering Insight:** There is no separate "rename" command in Linux. `mv` handles both moving and renaming because they are the same operation at the file system level — you're just changing the path where the file is recorded.

### `rm` — Delete Files and Directories

```bash
rm file.txt                         # Delete a file
rm file1.txt file2.txt              # Delete multiple files
rm -i file.txt                      # Ask before deleting (safe mode)
rm -r projects/                     # Delete directory and everything inside
rm -rf projects/                    # Force delete — NO prompts, NO mercy
rm *.tmp                            # Delete all .tmp files
```

> 🚨 **CRITICAL WARNING:** `rm -rf` is the most dangerous command in Linux.
>
> - There is **no Recycle Bin**
> - There is **no undo**
> - `rm -rf /` would delete your entire operating system (modern Linux blocks this, but variants can still destroy your system)
>
> **Professional habit:** Always double-check your path before running `rm -r`. Many sysadmins have accidentally deleted the wrong directory. Some companies have lost production databases this way.
>
> Safe practice: Run `ls` on the path first, THEN `rm -r`.
> ```bash
> ls /tmp/old_project/    # Verify it's what you think
> rm -r /tmp/old_project/ # Now delete it
> ```

---



---

[← Previous](08-section-6-reading-file-contents.md) | [↑ Index](index.md) | [Next →](10-level-2-intermediary-advanced-file.md)
