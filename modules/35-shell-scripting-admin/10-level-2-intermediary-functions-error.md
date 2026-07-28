## ⭐ Level 2: Intermediary — Functions, Error Handling, and Robust Scripts

![Automation diagram showing script-driven administration workflow](https://upload.wikimedia.org/wikipedia/commons/6/6a/Bash_screenshot.png)

> *"A script that crashes on unexpected input is worse than no script at all — it gives you false confidence. Real sysadmin scripts have error handlers, input validation, logging, and cleanup routines. `set -euo pipefail` is not optional — it's the minimum bar for professional-grade automation."*

### What You'll Cover
- Functions: definition, local variables, return values, scope
- `set -euo pipefail` — the defensive scripting standard
- `trap` for cleanup on EXIT, ERR, INT, TERM
- `getopts` for parsing command-line arguments
- Arrays: indexed, iteration, element expansion
- Here-docs and here-strings for multi-line input
- `read` for interactive input, `mapfile` for reading into arrays

At this level your scripts evolve from one-off tasks to reusable tools. Functions, error handling, and argument parsing are the difference between a script that works on your machine and one that works everywhere.

At this level you will practice:

- **Functions**: `myfunc() { local result="done"; echo "$result"; }` — use `local` for variables to avoid polluting global scope. Return values via `return` (exit status) or `echo` (output). Functions are the building blocks of maintainable scripts.
- **`set -euo pipefail`**: `set -e` exits on error. `set -u` errors on unset variables. `set -o pipefail` makes pipelines fail if any command fails. This is the minimum bar for professional scripts — without it, errors propagate silently.
- **`trap`**: `trap 'rm -f /tmp/lockfile' EXIT` ensures cleanup runs even if the script crashes. `trap 'echo "Interrupted"; exit 1' INT` handles Ctrl+C. Always clean up temp files, lock files, and background processes.
- **`getopts`**: `while getopts "vf:o:" opt; do case $opt in v) verbose=1 ;; f) file=$OPTARG ;; o) output=$OPTARG ;; esac; done` parses flags like `-v -f input.txt -o output.txt`. The colon after a letter means it takes an argument (`$OPTARG`).
- **Arrays**: `arr=(one two three)` creates an array. `${arr[0]}` accesses element 0. `${arr[@]}` expands all elements. `${#arr[@]}` gives the length. Arrays are essential for processing lists of hosts, files, or configuration values.


[← Previous](09-6-loops.md) | [↑ Index](index.md) | [Next →](11-7-functions.md)
