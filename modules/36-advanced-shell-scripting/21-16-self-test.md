## 16. Self-Test

Answer 15 questions. **Score:** 12/15 correct = ready for Part 37.

### Question 1
Which regex flavor does `grep` use by default?
- A) ERE
- B) BRE
- C) PCRE
- D) DFA

### Question 2
What does `sed -n '5,10p'` do?
- A) Deletes lines 5-10
- B) Prints only lines 5-10 to stdout
- C) Prints all lines except 5-10
- D) Substitutes on lines 5-10

### Question 3
In `awk`, what does `$NF` represent?
- A) Number of fields
- B) Last field of current record
- C) First field of next record
- D) Null field

### Question 4
Which `grep` flag enables Perl-compatible regular expressions?
- A) `-E`
- B) `-P`
- C) `-F`
- D) `-G`

### Question 5
What is the hold space in `sed` used for?
- A) Storing the current input line
- B) Storing data across cycles
- C) Buffering output
- D) Holding error messages

### Question 6
Which `xargs` option runs commands in parallel?
- A) `-I`
- B) `-n`
- C) `-P`
- D) `-0`

### Question 7
What does the `BEGIN` block in `awk` do?
- A) Runs after each record
- B) Runs when a pattern matches
- C) Runs before any input is read
- D) Runs at end of file

### Question 8
What is the difference between `[0-9]` and `[[:digit:]]`?
- A) No difference
- B) `[0-9]` is locale-aware; `[[:digit:]]` is ASCII-only
- C) `[[:digit:]]` is locale-aware; `[0-9]` is ASCII-only
- D) `[0-9]` matches letters; `[[:digit:]]` matches digits

### Question 9
Which command creates a patch in unified format?
- A) `patch -u`
- B) `diff -u`
- C) `diff -c`
- D) `patch -c`

### Question 10
In `sed`, what does the `g` flag in `s/old/new/g` mean?
- A) Global (replace all occurrences on line)
- B) Group (capture group)
- C) Greedy match
- D) Generate output

### Question 11
Which tool would you use to efficiently extract the 3rd column from a tab-delimited file?
- A) `sed`
- B) `cut -f3`
- C) `comm`
- D) `paste`

### Question 12
What does `awk '!seen[$0]++'` do?
- A) Counts all lines
- B) Removes duplicate lines (like uniq without requiring sort)
- C) Prints all lines twice
- D) Reverses line order

### Question 13
What is the NFA regex engine behavior when matching `(a|aa)*b` against `aaaaaaaaac`?
- A) Fast linear match
- B) Catastrophic backtracking (exponential)
- C) Immediate failure
- D) Lazy evaluation

### Question 14
Which command shows the difference between two files, ignoring whitespace?
- A) `diff -u`
- B) `diff -w`
- C) `diff -r`
- D) `diff -q`

### Question 15
What does the `-I {}` option in `xargs` do?
- A) Limits arguments per command
- B) Sets the replacement string for substitution
- C) Enables interactive mode
- D) Uses null separators

---

### Answer Key

1. **B** — BRE (Basic Regular Expressions). `grep -E` for ERE, `grep -P` for PCRE.
2. **B** — `-n` suppresses default output; `5,10p` prints lines 5-10. Only those lines appear.
3. **B** — `NF` is the number of fields; `$NF` is the value of the last field.
4. **B** — `-P` enables PCRE. `-E` for ERE, `-F` for fixed strings.
5. **B** — Hold space stores data that persists across the read-process cycle.
6. **C** — `-P N` runs N processes in parallel. `-I` sets replacement string, `-n` sets max args.
7. **C** — `BEGIN` runs once before any input is read. `END` runs after all input.
8. **C** — `[[:digit:]]` is locale-aware and matches digits from various scripts; `[0-9]` is ASCII only.
9. **B** — `diff -u` produces unified format. `patch` applies patches, doesn't create them.
10. **A** — The `g` flag makes the substitution apply to every occurrence on the line, not just the first.
11. **B** — `cut -f3` extracts the 3rd field (tab-delimited by default). Use `-d' '` for other delimiters.
12. **B** — `!seen[$0]++` prints a line only the first time it appears, removing duplicates without sorting.
13. **B** — Nested quantifiers with overlapping alternatives cause catastrophic backtracking.
14. **B** — `diff -w` ignores whitespace differences. `-u` is unified format, `-q` is quiet.
15. **B** — `-I {}` defines `{}` as the replacement string, substituted with each input item.

### Scoring

| Correct | Assessment |
|---------|------------|
| 15/15 | Expert level — you could teach this course |
| 13-14/15 | Strong — ready for Part 37 |
| 12/15 | Pass — ready for Part 37 |
| 10-11/15 | Review weak areas |
| <10/15 | Re-read Part 36 before continuing |

---

*Previous → Part 35: Shell Scripting for System Administrators*
*Next → Part 37: Automation with Ansible*

[← Previous](part35.md) | [Next →](part37.md)


---

[← Previous](20-15-command-reference.md) | [↑ Index](index.md)
