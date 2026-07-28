## 17. Self-Test

**Score: 12/15 correct = ready for Part 36.**

### Questions

**Q1.** What does the shebang `#!/bin/bash` do?

**Q2.** What is the difference between `./script.sh` and `source script.sh`?

**Q3.** What does `set -euo pipefail` do? Explain each flag.

**Q4.** Write a one-liner that extracts lines 10-20 from a file.

**Q5.** What is the difference between `[ ]` and `[[ ]]` in bash?

**Q6.** How do you iterate over all `.conf` files in `/etc/`?

**Q7.** What does `${var:-default}` do?

**Q8.** How do you capture the output of a command into a variable?

**Q9.** What is the purpose of `mktemp` and why is it important?

**Q10.** How do you run a command in the background and get its PID?

**Q11.** Write a function that checks if a directory exists and is writable.

**Q12.** What is the difference between `$@` and `$*`?

**Q13.** How does `trap cleanup EXIT` work?

**Q14.** What does `IFS=` do in `while IFS= read -r line`?

**Q15.** How do you create an associative array in bash?

### Answers

**A1.** The shebang tells the kernel which interpreter to use. The kernel reads the first line, finds `/bin/bash`, and executes: `/bin/bash ./script.sh`.

**A2.** `./script.sh` runs in a new child process (fork+exec). `source script.sh` reads and executes the script in the current shell — all variable/function changes persist.

**A3.**
- `-e`: Exit immediately if any command exits with non-zero status
- `-u`: Treat reference to unset variables as an error
- `-o pipefail`: Pipeline fails if ANY command in the pipeline fails (not just the last)

**A4.** `sed -n '10,20p' file` or `awk 'NR>=10 && NR<=20' file`

**A5.** `[ ]` is POSIX `test`, performs word splitting and pathname expansion. `[[ ]]` is a bash keyword, doesn't split words, supports `=~` regex matching, `&&`/`||` operators, and pattern matching.

**A6.** `for file in /etc/*.conf; do echo "$file"; done`

**A7.** `${var:-default}` returns `default` if `$var` is unset or null; otherwise returns the value of `$var`.

**A8.** `output=$(command)`

**A9.** `mktemp` creates a temporary file or directory with a unique, unpredictable name. Prevents race conditions and symlink attacks.

**A10.** `command & pid=$!`

**A11.** `check_dir() { local dir="$1"; [ -d "$dir" -a -w "$dir" ]; }`

**A12.** `$@` expands each positional parameter as a separate word (preserves quoting). `$*` expands to a single word (all parameters concatenated).

**A13.** `trap cleanup EXIT` registers the `cleanup` function to be called automatically when the script exits for any reason.

**A14.** Setting `IFS=` (empty) prevents `read` from stripping leading/trailing whitespace. With `-r`, it safely reads lines without modification.

**A15.** `declare -A myarray; myarray[key1]="value1"; myarray[key2]="value2"`

### Scoring

| Score | Assessment |
|---|---|
| 15/15 | Expert level — you could teach this |
| 12-14/15 | Ready for Part 36 |
| 8-11/15 | Review sections 3-8 and retry |
| 0-7/15 | Re-read this part before moving on |





[← Previous](21-14-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](23-18-whats-coming-in-part.md)
