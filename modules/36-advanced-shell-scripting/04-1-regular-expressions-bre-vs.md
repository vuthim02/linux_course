## 1. Regular Expressions — BRE vs ERE vs PCRE

A regular expression (regex) is a pattern that describes a set of strings. Every sysadmin must understand three flavors.

### 1.1 BRE (Basic Regular Expressions)

The original Unix regex. Meta-characters `?`, `+`, `{`, `|`, `(`, `)` lose their special meaning unless escaped with `\`.

| Pattern | Meaning in BRE |
|---------|---------------|
| `abc`   | literal string |
| `a\.b`  | a, dot, b (dot escaped) |
| `^`     | start of line |
| `$`     | end of line |
| `.*`    | zero or more of any char |
| `[abc]` | one of a, b, c |
| `[^abc]`| NOT a, b, c |
| `\(abc\)` | grouping (escaped parens) |
| `abc\|def` | alternation (escaped pipe) |
| `a\{3\}` | exactly 3 a's (escaped braces) |

```bash
# BRE default in grep (no -E)
grep '^root:' /etc/passwd
grep '\(foo\|bar\)' file.txt
```

### 1.2 ERE (Extended Regular Expressions)

Meta-characters are special **without** escaping. Used by `grep -E`, `awk`, `sed -E`.

| Pattern | Meaning in ERE |
|---------|---------------|
| `a?`    | zero or one a |
| `a+`    | one or more a |
| `a{3}`  | exactly 3 a's |
| `(abc)` | grouping |
| `abc\|def` | alternation |

```bash
grep -E '^[A-Za-z_][A-Za-z0-9_]*$' identifiers.txt
```

### 1.3 PCRE (Perl-Compatible Regular Expressions)

Richest flavor: lookahead, lookbehind, non-capturing groups, backreferences. Used by `grep -P`, `pcregrep`, `perl`, `python`.

```bash
grep -P '(?<=\$)[A-Z_]+(?=\s* =)' script.sh  # variable names after $
```

### 1.4 Anchors

```bash
^         # start of line
$         # end of line
\b        # word boundary (PCRE/ERE in some tools)
\B        # non-word boundary
\A        # start of string (PCRE)
\Z        # end of string (PCRE)
```

```bash
grep '^#\|^$' config.conf      # comments + blank lines
grep -P '^.{0,80}$' file.txt   # lines ≤ 80 chars
```

### 1.5 Quantifiers

```bash
*       # 0 or more  (greedy)
\+ / +  # 1 or more  (escaped in BRE)
\? / ?  # 0 or 1
{n,m}   # n to m times
{n}     # exactly n
{n,}    # n or more
*?      # lazy 0 or more (PCRE)
+?      # lazy 1 or more (PCRE)
```

```bash
# IP address pattern (ERE)
grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log

# Hex color
grep -P '#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?' style.css
```

### 1.6 Character Classes

```bash
[abc]         # a, b, or c
[^abc]        # NOT a, b, or c
[a-z]         # range a to z
[[:alpha:]]   # POSIX: alphabetic
[[:digit:]]   # POSIX: digit
[[:space:]]   # POSIX: whitespace
[[:upper:]]   # POSIX: uppercase
[[:lower:]]   # POSIX: lowercase
[[:alnum:]]   # POSIX: alphanumeric
[[:punct:]]   # POSIX: punctuation
[[:blank:]]   # POSIX: space or tab
```

```bash
# POSIX classes are locale-aware
grep '[[:digit:]]' file.txt     # digits in any locale
grep '[0-9]' file.txt           # ASCII digits only
grep '[[:upper:]]' names.txt    # works with accented chars
```

### 1.7 Grouping and Backreferences

```bash
# ERE
grep -E '(foo) \1' file.txt    # "foo foo"
sed -E 's/([a-z]+) \1/\1/g'    # remove duplicated words

# BRE requires escaped parens
sed 's/\([a-z]\)\([0-9]\)/\2\1/g'

# PCRE: non-capturing group
grep -P '(?:foo|bar)baz'

# PCRE: named groups (Python/Perl)
(?P<name>pattern) \k<name>
```

### 1.8 Lookahead and Lookbehind (PCRE)

```bash
(?=pattern)   # positive lookahead
(?!pattern)   # negative lookahead
(?<=pattern)  # positive lookbehind
(?<!pattern)  # negative lookbehind
```

```bash
# Extract values after "key="
grep -P '(?<=key=)\w+' config.txt

# Lines NOT followed by "END"
grep -P '^START(?!.*END)' file.txt

# Lines NOT preceded by "#"
grep -P '(?<!#)include' config.cfg

# Password-like strings (8+ chars, letter + digit)
grep -P '^(?=.*[a-zA-Z])(?=.*[0-9]).{8,}' passwords.txt
```

### 1.9 Regex Pitfalls

```bash
# Greediness
echo '<tag>text</tag>' | grep -Po '<.*>'    # matches whole line
echo '<tag>text</tag>' | grep -Po '<.*?>'   # matches <tag> only

# Catastrophic backtracking
# BAD:  (a|aa|aaa|aaaa)*b   — exponential with long strings
# GOOD: a+b                  — linear

# [0-9] vs [[:digit:]]
[0-9]     # ASCII 0-9 only
[[:digit:]] # locale-aware: digits in Arabic, Devanagari, etc.
```





[← Previous](03-level-1-basic-foundations.md) | [↑ Index](index.md) | [Next →](05-2-grep-in-depth.md)
