## 3. sed — Stream Editor

`sed` reads line by line, applies commands, outputs result. Non-interactive text transformation.

### 3.1 How sed Works (The Cycle)

```
Read a line → Execute commands → Print (unless -n) → Repeat
```

```bash
sed 's/old/new/' file.txt        # basic substitute
sed -n '5,10p' file.txt          # print lines 5-10
sed '3d' file.txt                # delete line 3
```

### 3.2 The s Command — Substitute

```
s/pattern/replacement/flags
```

| Flag | Meaning |
|------|---------|
| `g`  | global (all occurrences on line) |
| `N`  | replace Nth occurrence |
| `p`  | print line if substitution occurred |
| `w file` | write to file if substitution occurred |
| `i`  | case-insensitive |
| `e`  | execute replacement as command (GNU sed) |

```bash
sed 's/foo/bar/' file.txt          # first occurrence per line
sed 's/foo/bar/g' file.txt         # all occurrences
sed 's/foo/bar/2' file.txt         # only second occurrence
sed -n 's/ERROR/CRITICAL/p' log    # print changed lines only
sed 's/[0-9]/[&]/g' file.txt       # wrap each digit in brackets
sed 's/\(foo\)/\1bar/' file.txt    # backreference: foobar
```

### 3.3 Address Ranges

```bash
sed '3s/foo/bar/' file.txt         # line 3 only
sed '/pattern/s/foo/bar/' file.txt # lines matching pattern
sed '5,10s/foo/bar/' file.txt      # lines 5-10
sed '/start/,/end/s/foo/bar/'      # between markers
sed '5,$s/foo/bar/' file.txt       # line 5 to end
sed '1~3d' file.txt                # every 3rd line starting at 1
```

### 3.4 sed Commands

```bash
s       # substitute
d       # delete line
p       # print line (with -n)
a       # append text after line
i       # insert text before line
c       # change (replace) line
y       # transliterate (like tr)
q       # quit
r       # read file into output
w       # write line to file
=       # print line number
N       # read next line into pattern space
D       # delete up to first newline in pattern space
P       # print up to first newline in pattern space
h       # copy pattern space to hold space
H       # append pattern space to hold space
g       # copy hold space to pattern space
G       # append hold space to pattern space
x       # exchange pattern and hold spaces
```

```bash
# Delete blank lines
sed '/^$/d' file.txt

# Print line numbers
sed '=' file.txt | sed 'N;s/\n/\t/'

# Insert header before line 1
sed '1i\# Generated on '$(date)'' file.txt

# Append footer
sed '$a\# End of file' file.txt

# Change a line
sed '/^DEBUG/c\# DEBUG mode disabled' config.txt

# Transliterate (like tr)
sed 'y/abcdef/ABCDEF/' file.txt
```

### 3.5 The Hold Space

sed has two buffers:
- **Pattern space** — the working line
- **Hold space** — a storage buffer

```bash
# Reverse line order of file (tac equivalent)
sed '1!G;h;$!d' file.txt

# Print paragraph if it contains a pattern
sed -n '/pattern/{h;:a;n;/./{H;ba};g;p}' file.txt

# Duplicate each line
sed 'G' file.txt

# Join every other line
sed 'N;s/\n/ /' file.txt
```

### 3.6 Multi-line sed (N, D, P)

```bash
# Join lines ending with backslash
sed '/\\$/{N;s/\\\n//}' file.txt

# Print from START to END inclusive
sed -n '/START/,/END/p' file.txt

# Delete blank lines and surrounding
sed '/^$/{N;/^\n$/d}' file.txt

# Replace \n with comma between lines
sed ':a;N;$!ba;s/\n/,/g' file.txt
```

### 3.7 sed -i (In-Place Editing)

```bash
# GNU sed (Linux)
sed -i 's/old/new/g' file.txt
sed -i.bak 's/old/new/g' file.txt   # backup as file.txt.bak
sed -i '' 's/old/new/g' file.txt    # BSD sed (macOS)

# Multiple expressions with -e
sed -i -e 's/foo/bar/' -e 's/baz/qux/' file.txt

# Script file
sed -i -f commands.sed file.txt
```





[← Previous](06-level-2-intermediary-tools-scripts.md) | [↑ Index](index.md) | [Next →](08-4-sed-admin-patterns.md)
