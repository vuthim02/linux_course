## 14. Deep Understanding

### 14.1 How sed Works (Read → Process → Cycle)

```
sed operates on a cyclic buffer called the PATTERN SPACE.

              +-----------+
  Input ----> | Read line | ----> Pattern Space
              +-----------+          |
                                     |
                              +------v-------+
                              | Execute cmds  |
                              | s/d/p/a/i/c/y |
                              +------+-------+
                                     |
                    +----------------+----------------+
                    |                                 |
              +-----v-----+                    +------v------+
              | -n flag?  |                    | Print space |
              +-----+-----+                    +------+------+
                    | no                              |
                    +---------> Output <--------------+

Then NEXT line is read. Cycle repeats. EOF terminates.

HOLD SPACE: a secondary buffer for storing data across cycles.
Commands: h (copy to hold), H (append), g (copy from hold), G (append from hold), x (swap).
```

### 14.2 How awk Works (Read → Pattern → Action)

```
awk's main loop is implicit:

  1. Initialize: BEGIN block runs once
  2. For each record (line by default):
     a. Split record into fields ($1, $2, ..., $NF)
     b. Evaluate each pattern in order
     c. If pattern matches, execute corresponding action
     d. If no pattern matches, nothing happens (unlike sed)
  3. Finalize: END block runs once

Field splitting uses FS (Field Separator), default whitespace.
$0 = entire record, $1 = first field, $NF = last field.
NR = number of records read, NF = number of fields in current record.
```

### 14.3 Regex Engine (NFA/DFA)

Two types of regex engines:

**DFA (Deterministic Finite Automaton)**
- Used by: `awk`, `egrep` (traditional), `lex`
- Each character processed once — O(n) always
- No backreferences, no lookahead/lookbehind
- Always finds the longest match (leftmost longest)
- Cannot backtrack — faster but less powerful

**NFA (Nondeterministic Finite Automaton)**
- Used by: `sed`, `grep` (GNU), `perl`, `python`, `java`
- Backtracks to try alternatives — potentially O(2^n)
- Supports backreferences, lookahead/lookbehind, lazy quantifiers
- Uses backtracking: tries one path, if fails, goes back and tries another
- Greedy by default (tries longest first), lazy with `?` suffix

**Backreference Performance Impact**
```bash
# Without backreference — NFA, fast
grep -E '([a-z])'  # still uses NFA but no backtrack issue

# With backreference — forces NFA, can cause catastrophic backtracking
grep -E '([a-z]+)-\1'  # \1 must match same text as group

# Catastrophic backtracking example
# Pattern: (a|aa|aaa)*b on string "aaaaaaaaac"
# Each a can match any of the alternatives, creating exponential paths
# Fix: rewrite without nested quantifiers a*b
```

### 14.4 Why `[0-9]` vs `[[:digit:]]`

```bash
[0-9]        # Matches ASCII characters with codes 0x30-0x39
             # Only "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"

[[:digit:]]   # POSIX character class, locale-aware
              # In C locale: same as [0-9]
              # In e.g. ar_SA.utf8: also matches Arabic-Indic digits
              # In e.g. bn_IN: also matches Bengali digits

# When to use which:
# [0-9] — faster, safe for ASCII-only configs, code, logs
# [[:digit:]] — required for internationalized apps, user input validation

# Similarly:
[[:alpha:]] vs [a-zA-Z]   # [[:alpha:]] includes accented chars
[[:space:]] vs [ \t]      # [[:space:]] includes \r, \n, \f, \v
[[:alnum:]] vs [a-zA-Z0-9] # [[:alnum:]] includes locale-specific chars
```

### 14.5 sed vs awk — When to Use Which

| Task | Tool | Reason |
|------|------|--------|
| Simple text substitution | `sed` | Readable one-liner |
| Find lines matching pattern | `grep` | Fastest, simplest |
| Field/column extraction | `awk` | Native field support |
| Arithmetic/computations | `awk` | Full numeric support |
| Complex conditionals | `awk` | C-like syntax |
| Multi-line operations | `sed` (N,D,P) or `awk` | Both work, awk often clearer |
| In-place editing | `sed -i` | Native support |
| Report generation | `awk` | printf, arrays, totals |
| Table joins | `awk` or `join` | Associative arrays |
| Stream transformation | `sed` | Designed for this |

### 14.6 GNU Extensions vs POSIX

Many examples in this course use GNU extensions:

- `sed -i` (in-place) — GNU, not POSIX
- `grep -P` (PCRE) — GNU, not POSIX
- `sort -h` (human sort) — GNU
- `xargs -P` (parallel) — GNU
- `awk` `asorti()` — GNU awk

For maximum portability (BSD/macOS), avoid GNU extensions or test on target.





[← Previous](18-13-hands-on-practices-15.md) | [↑ Index](index.md) | [Next →](20-15-command-reference.md)
