## 8. cut, sort, uniq, wc, tr

### 8.1 cut — Column Extraction

```bash
cut -d: -f1,3 /etc/passwd          # fields 1 and 3 (delimiter :)
cut -d: -f1-3 /etc/passwd          # fields 1 through 3
cut -c1-10 file.txt                # characters 1-10
cut -d, -f1 --complement data.csv  # all except field 1
cut -d' ' -f2-                     # from field 2 to end
```

### 8.2 sort — Line Sorting

```bash
sort file.txt                      # alphabetically
sort -n file.txt                   # numerically
sort -rn file.txt                  # reverse numerically
sort -k2 -t: /etc/passwd           # sort by field 2, delimiter :
sort -u file.txt                   # unique sort
sort -h file.txt                   # human numeric (2K, 3M, 1G)
sort -R file.txt                   # random sort
sort -m file1 file2                # merge already-sorted files
sort -t$'\t' -k3 -n data.tsv       # tab-delimited, numeric field 3
```

### 8.3 uniq — Unique Lines

```bash
uniq file.txt                      # remove adjacent duplicates
uniq -c file.txt                   # prefix with count
uniq -d file.txt                   # only duplicates
uniq -u file.txt                   # only unique (non-duplicate) lines
sort file.txt | uniq               # global unique (sort first)
sort file.txt | uniq -c | sort -rn # frequency table
```

### 8.4 wc — Word Count

```bash
wc file.txt                        # lines, words, bytes
wc -l file.txt                     # lines only
wc -w file.txt                     # words only
wc -c file.txt                     # bytes
wc -m file.txt                     # characters (multi-byte aware)
wc -L file.txt                     # longest line length
```

### 8.5 tr — Translate/Delete

```bash
tr 'a-z' 'A-Z' < file.txt          # uppercase
tr -d '\t' < file.txt              # delete tabs
tr -s ' ' ' ' < file.txt           # squeeze spaces
tr -d '\r' < dos.txt > unix.txt    # remove CR (DOS→Unix)
tr ' ' '\n' < file.txt             # split words to lines
tr -dc '[:print:]' < file.txt      # delete non-printable chars
tr '[:upper:]' '[:lower:]' < file.txt  # lowercase (locale-aware)
```

### 8.6 Practical Pipelines

```bash
# Top 10 most frequent words
tr -s '[:space:]' '\n' < file.txt | tr -d '[:punct:]' | sort | uniq -c | sort -rn | head -10

# Largest files in directory
ls -la | awk 'NR>1 {print $5, $NF}' | sort -rn | head -10

# IP connections count
ss -tuna | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# HTTP status code summary
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# Users with UID > 1000 (non-system)
awk -F: '$3 >= 1000 {print $1, $3}' /etc/passwd | sort -k2 -n

# File type breakdown
find . -type f | awk -F. '{print $NF}' | sort | uniq -c | sort -rn
```





[← Previous](11-7-combining-tools.md) | [↑ Index](index.md) | [Next →](13-9-paste-join-comm.md)
