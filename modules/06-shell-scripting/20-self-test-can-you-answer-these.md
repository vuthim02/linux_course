## 📝 Self-Test — Can You Answer These?

1. What does the shebang `#!/bin/bash` do?
2. What is the difference between `./script.sh` and `source script.sh`?
3. Why should you always quote variables like `"$var"`?
4. What does `set -euo pipefail` do?
5. How do you read a file line by line in bash?
6. What is the difference between `[ ]` and `[[ ]]`?
7. How do you define a function and declare a local variable inside it?
8. What exit code indicates success? What indicates failure?
9. How do you pass a default value if a variable is unset?
10. What does `declare -i` do? What about `declare -l` and `declare -u`?
11. Write a for loop that iterates over all `.txt` files in the current directory.
12. What does `trap cleanup EXIT` do?
13. How do you schedule a script to run every day at 3:30 AM?
14. What is the difference between running a script and sourcing it?
15. How would you write a function that logs a timestamped message?
16. How do you check if a file exists before operating on it?

**Score:** 13/16 correct = ready for Part 7.


## Answer Key

### Q1: What does the shebang `#!/bin/bash` do?
**Answer:** Tells the kernel to use `/bin/bash` as the interpreter when executing the script.

### Q2: What is the difference between `./script.sh` and `source script.sh`?
**Answer:** `./script.sh` runs in a child process (variables/functions don't persist). `source script.sh` runs in the current shell (changes persist).

### Q3: Why should you always quote variables like `"$var"`?
**Answer:** Prevents word splitting and globbing. An unquoted empty variable disappears; quoted it becomes `""` (empty string).

### Q4: What does `set -euo pipefail` do?
**Answer:** `-e`: exit on any error. `-u`: error on unset variables. `-o pipefail`: pipeline fails if any command fails (not just the last).

### Q5: How do you read a file line by line in bash?
**Answer:** `while IFS= read -r line; do echo "$line"; done < file` — preserves whitespace and backslashes.

### Q6: What is the difference between `[ ]` and `[[ ]]`?
**Answer:** `[[ ]]` is a bash keyword with enhanced features: supports regex (`=~`), pattern matching, logical `&&`/`||`, and no word splitting. `[ ]` is POSIX `test`.

### Q7: How do you define a function and declare a local variable inside it?
**Answer:** `myfunc() { local var="value"; echo "$var"; }` — `local` scopes the variable to the function.

### Q8: What exit code indicates success? What indicates failure?
**Answer:** `0` = success, any non-zero (1-255) = failure.

### Q9: How do you pass a default value if a variable is unset?
**Answer:** `${var:-default}` — returns "default" if `var` is unset or null. Use `${var:=default}` to also assign it.

### Q10: What does `declare -i` do? What about `declare -l` and `declare -u`?
**Answer:** `declare -i` marks a variable as integer type (arithmetic, not string). `declare -l` auto-lowercases assigned values. `declare -u` auto-uppercases assigned values.

### Q11: Write a for loop that iterates over all `.txt` files.
**Answer:** `for f in *.txt; do echo "$f"; done`

### Q12: What does `trap cleanup EXIT` do?
**Answer:** Registers the `cleanup` function to run automatically when the script exits (for any reason), ensuring cleanup happens.

### Q13: How do you schedule a script to run every day at 3:30 AM?
**Answer:** `crontab -e` then add: `30 3 * * * /path/to/script.sh`

### Q14: What is the difference between running a script and sourcing it?
**Answer:** Running creates a child process; sourcing executes in the current shell, so variable/function changes persist.

### Q15: How would you write a function that logs a timestamped message?
**Answer:** `log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }` — called as `log "Disk space low"`.

### Q16: How do you check if a file exists before operating on it?
**Answer:** `if [[ -f "$filename" ]]; then ... fi` — `-f` checks for a regular file.


*Linux SysAdmin Course | Part 6 of ∞ | Reverse Engineering Approach*
*Previous → Part 5: Pipes, Redirection, and Streams*
*Next → Part 7: Finding Things — grep, find, locate, and Beyond*

[← Previous](19-whats-coming-in-part-7.md) | [↑ Index](index.md) | [Next →](21-section-6-arithmetic-and-expansions.md)

[← Previous](19-whats-coming-in-part-7.md) | [↑ Index](index.md)
