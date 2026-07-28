## ⭐ Level 3: Advanced — Security, Internals, and Professional-Grade Scripting

![Shell expansion order diagram showing the 8 phases of bash parsing](https://upload.wikimedia.org/wikipedia/commons/7/72/Bash_expansion_order.svg)

> *"The difference between a script that works and a script that's secure is a single unquoted variable. The difference between a script that's maintainable and one that isn't is understanding how the shell actually works — the expansion order, the fork/exec model, and the subshell boundaries."*

### What You'll Cover
- Security: input validation, `mktemp` for temp files, PATH safety
- Associative arrays (Bash 4+): key-value data structures
- The fork/exec model: when subshells are created and why it matters
- Bash expansion order: brace → tilde → parameter → arithmetic → word splitting → glob
- Subshells: `()`, command substitution, process substitution
- Debugging: `set -x`, `set -v`, `PS4`, `bash -x`, shellcheck

At the advanced level, you understand not just how to write scripts, but how Bash actually works — and how that understanding prevents security vulnerabilities and subtle bugs.

At this level you will master:

- **Security**: Always validate input with `[[ "$input" =~ ^[0-9]+$ ]]` before using it in commands. Use `mktemp` for temporary files — never `echo $$ > /tmp/myscript.$$` (race condition). Keep `PATH` minimal at the top of scripts: `export PATH="/usr/bin:/bin"`.
- **Associative arrays**: `declare -A map; map[name]="value"; echo "${map[name]}"`. Bash 4+ only. Use for configuration parsing, O(1) lookups, and mapping between domains (e.g., IP to hostname).
- **Fork/exec model**: `()` creates a subshell (fork). `command` in the current shell does not fork. `$(command)` forks a subshell to capture output. Understanding when forks happen helps you optimize scripts that run thousands of iterations.
- **Expansion order**: Bash processes expansions in this order: brace `{a,b}` → tilde `~` → parameter `$var` → arithmetic `$(( ))` → word splitting → pathname expansion (glob). Quoting prevents word splitting and glob. This order explains why `"$var"` is safer than `$var`.
- **Debugging**: `set -x` prints each command before execution (prefixed by `+`). `PS4='+${BASH_SOURCE}:${LINENO}: '` adds file and line numbers to trace output. `bash -x script.sh` enables tracing for the whole script. `shellcheck script.sh` catches common mistakes statically.


[← Previous](16-13-real-admin-script-examples.md) | [↑ Index](index.md) | [Next →](18-12-security-in-scripts.md)
