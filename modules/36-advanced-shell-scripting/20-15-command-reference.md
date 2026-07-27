## 15. Command Reference

### Level 1 — Basic

#### 15.1 grep Flags

| Flag | Purpose |
|------|---------|
| `-E` | Extended regex (ERE) |
| `-F` | Fixed string (literal) |
| `-P` | PCRE (Perl-compatible) |
| `-o` | Only matched text |
| `-n` | Line numbers |
| `-c` | Count matches |
| `-l` | List matching files |
| `-L` | List non-matching files |
| `-q` | Quiet (exit code only) |
| `-r` | Recursive |
| `-v` | Invert match |
| `-w` | Whole word match |
| `-i` | Case-insensitive |
| `-x` | Whole line match |
| `-A N` | After context N lines |
| `-B N` | Before context N lines |
| `-C N` | Context N lines each side |
| `-m N` | Max N matches per file |
| `-z` | Null/nul separated records |

#### 15.5 Text Processing Reference

| Tool | Primary Use | Key Feature |
|------|-------------|-------------|
| `grep` | Filter lines by pattern | Fast, recursive, PCRE |
| `sed` | Transform text | In-place, multi-line, hold space |
| `awk` | Process structured text | Fields, arrays, arithmetic |
| `cut` | Extract columns | Fields (by delimiter) or characters |
| `sort` | Sort lines | Numeric, human, key-based |
| `uniq` | Unique/count lines | Adjacent dedup |
| `wc` | Count lines/words/bytes | Fast stats |
| `tr` | Translate/delete chars | Single-char operations |
| `paste` | Merge files horizontally | Side-by-side columns |
| `join` | Relational join | Sorted input, key field |
| `comm` | Compare sorted files | Three-column diff |
| `xargs` | Build command lines | Parallel execution |
| `diff` | Compare files | Unified/context format |
| `patch` | Apply diffs | Reverse, strip path |

### Level 2 — Intermediary

#### 15.2 sed Commands and Flags

| Command | Purpose |
|---------|---------|
| `s/pat/rep/` | Substitute |
| `d` | Delete line |
| `p` | Print line |
| `a text` | Append text after line |
| `i text` | Insert text before line |
| `c text` | Change (replace) line |
| `y/set1/set2/` | Transliterate |
| `q` | Quit after line |
| `r file` | Read file into output |
| `w file` | Write line to file |
| `=` | Print line number |
| `N` | Append next line to pattern space |
| `D` | Delete to first newline |
| `P` | Print to first newline |
| `h/H` | Copy/append to hold space |
| `g/G` | Copy/append from hold space |
| `x` | Exchange hold and pattern spaces |
| `: label` | Label for branch |
| `b label` | Branch (goto) |
| `t label` | Branch if substitution succeeded |

| s/.../.../ Flags | Meaning |
|------------------|---------|
| `g` | Global (all occurrences) |
| `i` | Case-insensitive |
| `p` | Print line if substitution occurred |
| `w file` | Write to file if substitution occurred |
| `e` | Execute result as command (GNU) |
| `N` | Replace Nth occurrence |

#### 15.3 awk Built-in Variables

| Variable | Meaning |
|----------|---------|
| `NR` | Record number (global) |
| `FNR` | Record number (per file) |
| `NF` | Number of fields |
| `$0` | Entire record |
| `$1`..`$N` | Field 1..N |
| `$NF` | Last field |
| `FS` | Field separator (input) |
| `OFS` | Output field separator |
| `RS` | Record separator (input) |
| `ORS` | Output record separator |
| `FILENAME` | Current input file |
| `ARGV` | Command-line arguments array |
| `ARGC` | Argument count |
| `ENVIRON` | Environment variables array |
| `SUBSEP` | Array subscript separator (default: \034) |

#### 15.4 awk Built-in Functions

| Function | Purpose |
|----------|---------|
| `length(s)` | String length |
| `substr(s, i, n)` | Substring |
| `index(s, t)` | Position of t in s |
| `match(s, r)` | Position of regex match |
| `split(s, a, f)` | Split s into array a |
| `gsub(r, t, s)` | Global substitute |
| `sub(r, t, s)` | First substitute |
| `toupper(s)` | Uppercase |
| `tolower(s)` | Lowercase |
| `sprintf(fmt, ...)` | Formatted string |
| `int(x)` | Integer truncation |
| `sqrt(x)` | Square root |
| `rand()` | Random (0-1) |
| `srand(x)` | Seed random |
| `asort(a)` / `asorti(a)` | Sort array (GNU) |
| `system(cmd)` | Execute shell command |
| `strftime(fmt)` | Format timestamp |
| `mktime(ts)` | Make timestamp |
| `systime()` | Current epoch time |

---





---

[← Previous](19-14-deep-understanding.md) | [↑ Index](index.md) | [Next →](21-16-self-test.md)
