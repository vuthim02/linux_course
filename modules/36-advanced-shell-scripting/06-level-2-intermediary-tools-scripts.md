## ⭐ Level 2: Intermediary — Tools & Scripts

![sed and awk](https://upload.wikimedia.org/wikipedia/commons/3/34/GNU_awk_3.1.6_expression.svg)

> *"sed transforms; awk analyzes. Together they are the sysadmin's scalpel and microscope."*

### What You'll Cover
- `sed`: substitutions (`s///`), deletions, address ranges, in-place editing
- `awk`: field processing, pattern-action pairs, built-in variables (NR, NF, FS)
- `cut`, `sort`, `uniq`, `wc` — the core text processing pipeline
- `paste`, `join`, `comm` — combining and comparing sorted files
- `xargs` — building command lines from stdin
- `diff` and `patch` — comparing files and applying changes
- Real-world admin scripts combining these tools

At this level you master the core text processing toolkit. Together, these tools can handle 90% of data manipulation tasks without Python or Perl.

At this level you will practice:

- **`sed`**: `sed 's/old/new/g' file` replaces all occurrences. `sed -i 's/old/new/g' file` edits in-place. `sed -n '10,20p' file` prints lines 10-20. `sed '/^#/d' file` removes comments. Address ranges (`/start/,/end/`) apply commands to specific sections.
- **`awk`**: `awk '{print $1, $3}' file` prints columns 1 and 3. `awk -F: '{print $1}' /etc/passwd` uses `:` as delimiter. `awk 'NR==5' file` prints line 5. `awk '{sum+=$1} END{print sum}' file` sums a column. Pattern-action pairs: `awk '/error/ {print}' file`.
- **Core pipeline**: `cut -d: -f1 /etc/passwd | sort | uniq` extracts usernames and sorts them. `wc -l file` counts lines. `sort -u file` is equivalent to `sort | uniq`. These tools chain together with pipes for powerful transformations.
- **`xargs`**: `find . -name "*.log" | xargs rm` removes all `.log` files. `xargs -I{} cp {} /backup/` processes one at a time. `xargs -P4` runs 4 processes in parallel. Essential for converting piped input into command arguments.
- **`diff`/`patch`**: `diff -u old.conf new.conf` shows unified differences. `diff -rq dir1 dir2` recursively compares directories. `diff -u file > changes.patch` creates a patch. `patch < changes.patch` applies it. Essential for tracking configuration changes.


[← Previous](05-2-grep-in-depth.md) | [↑ Index](index.md) | [Next →](07-3-sed-stream-editor.md)
