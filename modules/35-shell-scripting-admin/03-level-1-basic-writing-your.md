## ⭐ Level 1: Basic — Writing Your First Scripts

![Bash logo — GNU Bash the Bourne Again SHell](https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/GNU_bash_logo.svg/320px-GNU_bash_logo.svg.png)

> *"Shell scripting is the glue of Linux administration. When you find yourself typing the same five commands every day, that's a script waiting to happen. A good script is one you forget you wrote because it just works for years."*

### What You'll Cover
- Shebangs: `#!/bin/bash` vs `#!/usr/bin/env bash`
- Variables: assignment, expansion, quoting (`"$var"` vs `$var`)
- Arithmetic: `$(( ))`, `let`, `expr`
- Conditionals: `if`/`elif`/`else`, `[[ ]]` test syntax, `case`
- Loops: `for`, `while`, `until`, `seq`
- Exit codes: `$?`, `&&`, `||`, `true`, `false`
- Script execution: `./script.sh`, `bash script.sh`, `source script.sh`

Shell scripting starts with understanding how Bash interprets your commands. The difference between a working script and a broken one often comes down to quoting and exit codes.

At this level you will learn:

- **Shebangs**: `#!/bin/bash` tells the kernel which interpreter to use. `#!/usr/bin/env bash` searches PATH for bash — more portable across systems. Without a shebang, the script runs in the current shell (which may not be bash).
- **Variables and quoting**: `name="hello"` assigns a variable. `echo "$name"` preserves whitespace. `echo $name` splits on spaces and performs glob expansion. Always double-quote variables unless you specifically need word splitting.
- **Conditionals**: `if [[ -f "$file" ]]; then ... fi` tests if a file exists. `[[ ]]` is bash-specific and supports regex with `=~`. `case $var in pattern) commands ;; esac` is cleaner than multiple `if` statements.
- **Loops**: `for i in 1 2 3; do echo $i; done` iterates over a list. `for f in /var/log/*.log; do ... done` iterates over files. `while read -r line; do ... done < file` reads a file line by line.
- **Exit codes**: `command1 && command2` runs command2 only if command1 succeeds (exit 0). `command1 || command2` runs command2 if command1 fails. `$?` holds the exit code of the last command (0 = success, non-zero = failure).


[← Previous](02-table-of-contents.md) | [↑ Index](index.md) | [Next →](04-1-why-shell-scripting.md)
