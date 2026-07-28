## 15. `ncdu` — NCurses Disk Usage Analyzer

`ncdu` is an interactive disk usage analyzer that runs in the terminal. Unlike `du`, it lets you navigate directories interactively and sort by size.

```
$ sudo apt install ncdu
$ ncdu /home
$ sudo ncdu /
```

Export to CSV: `ncdu -o report.csv /path`

**Key features**:
- Interactive navigation: use arrow keys to browse directories, `d` to delete files
- Sort by size or count: press `s` to toggle sort mode
- Exclude patterns: `ncdu --exclude /proc --exclude /sys /`
- Remote analysis: `ncdu -o report.json /data`, copy the file, then `ncdu -f report.json` on another machine
- The exported JSON format allows integration with other tools and historical comparison

**When to use ncdu**: When a disk is filling up and you need to find the culprit fast. `du -sh * | sort -h` gives you a static view; `ncdu` lets you drill down interactively. For automated monitoring, use `ncdu -o` to export and compare over time.


[← Previous](16-14-log-based-monitoring.md) | [↑ Index](index.md) | [Next →](18-16-cockpit-web-based-server-administration.md)
