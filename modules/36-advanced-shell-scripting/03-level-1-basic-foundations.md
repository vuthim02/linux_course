## ⭐ Level 1: Basic — Foundations

![Regular expression visualization](https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3FpaTgyZTRkb2dwaTV5czM3eGxtanF2eDF1bnB0ZmU5aGQwMG10OCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/MdA16VIoXKKxNE8Stk/giphy.webp)


### What You'll Cover
- Regular expression flavors: BRE, ERE, PCRE — when to use each
- Anchors: `^`, `$`, `\b`, `\B`
- Quantifiers: `*`, `+`, `?`, `{n}`, `{n,m}`
- Character classes: `[[:digit:]]`, `[[:alpha:]]`, `[[:alnum:]]`, `.`
- Groups and alternation: `()`, `|`
- `grep` in depth: `-E`, `-P`, `-o`, `-c`, `-v`, `-A`, `-B`, `-C`

Regular expressions are the pattern-matching language that powers `grep`, `sed`, `awk`, and `vim`. Mastering regex is the single most valuable skill for text processing.

At this level you will learn:

- **BRE vs ERE vs PCRE**: BRE (Basic Regular Expressions) requires escaping `+`, `?`, `()` with backslashes. ERE (`grep -E`) treats them as special by default. PCRE (`grep -P`) adds lookahead (`(?=...)`), lookbehind (`(?<=...)`), and non-greedy quantifiers. Use ERE for most tasks; PCRE when you need lookahead.
- **Anchors**: `^` matches start of line. `$` matches end of line. `\b` matches word boundary. `^$` matches empty lines. `^#` matches comment lines. Anchors are essential for precise matching — without them, patterns match anywhere in the line.
- **Quantifiers**: `*` matches zero or more. `+` matches one or more. `?` matches zero or one. `{3}` matches exactly three. `{2,5}` matches two to five. `.*` matches everything (greedy). Non-greedy: `.*?` (PCRE only).
- **Character classes**: `[[:digit:]]` matches digits (same as `[0-9]`). `[[:alpha:]]` matches letters. `[[:alnum:]]` matches alphanumeric. `[[:space:]]` matches whitespace. These are POSIX classes — portable across systems.
- **`grep` in depth**: `grep -E 'pattern' file` uses ERE. `grep -o 'pattern' file` outputs only matching parts. `grep -c 'pattern' file` counts matches. `grep -v 'pattern' file` inverts the match. `grep -A3 -B1 'pattern' file` shows context (3 lines after, 1 before).


[← Previous](02-table-of-contents.md) | [↑ Index](index.md) | [Next →](04-1-regular-expressions-bre-vs.md)
