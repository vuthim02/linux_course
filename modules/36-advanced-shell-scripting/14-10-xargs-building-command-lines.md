## 10. xargs — Building Command Lines from stdin

### 10.1 Basic Usage

```bash
# Convert stdin to arguments
find . -name '*.tmp' | xargs rm -f

# With -I for substitution
find . -name '*.txt' | xargs -I {} cp {} /backup/

# Dry run
find . -name '*.tmp' | xargs -I {} echo rm {}

# Null-separated (safe with spaces)
find . -name '*.txt' -print0 | xargs -0 rm -f
```

### 10.2 Key Options

```bash
-n N       # max arguments per command
-I {}      # replacement string
-P N       # parallel N processes
-0 / --null # null-delimited input
-t         # trace (print commands before running)
-p         # prompt before running each command
-r         # don't run if stdin is empty (GNU)
-d CHAR    # custom delimiter
```

```bash
# Batch files (100 per rm call)
find . -name '*.log' | xargs -n 100 rm -f

# Parallel downloads
cat urls.txt | xargs -P 4 -n 1 wget -q

# With replacement string
seq 1 10 | xargs -I {} echo "Processing file_{}.txt"

# Prompt before dangerous operations
find . -name '*.zip' -type f | xargs -p rm
```

### 10.3 Parallel xargs (-P)

```bash
# Parallel compression
find /var/log -name '*.log' -mtime +30 | \
    xargs -P $(nproc) -I {} gzip {}

# Parallel DNS lookup
cat domains.txt | xargs -P 10 -n 1 dig +short

# Parallel file processing
find data/ -name '*.csv' | \
    xargs -P 4 -I {} sh -c 'wc -l "$1" | awk "{print \$1, \"$1\"}"' -- {}
```

### 10.4 xargs with find (Best Practices)

```bash
# BAD: special chars break
find . -name '*.txt' | xargs rm

# GOOD: null separator
find . -name '*.txt' -print0 | xargs -0 rm

# BEST: use -exec or -delete
find . -name '*.txt' -delete
find . -name '*.txt' -exec rm {} +
```

### 10.5 xargs for System Admin

```bash
# Restart services from file
grep -l 'status: fail' /etc/service/* | sed 's|.*/||' | xargs -I {} systemctl restart {}

# Check multiple hosts
echo "web{1,2,3}.example.com" | tr ',' '\n' | xargs -P 3 -I {} ssh {} 'uptime'

# Kill processes by name
pgrep -f 'node server.js' | xargs kill -9

# Chown files by owner
awk -F: '$1 == "www-data" {print $6}' /etc/passwd | xargs -I {} chown -R www-data:www-data {}
```





[← Previous](13-9-paste-join-comm.md) | [↑ Index](index.md) | [Next →](15-11-diff-and-patch.md)
