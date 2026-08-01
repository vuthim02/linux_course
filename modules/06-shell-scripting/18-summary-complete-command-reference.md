## 📋 Summary — Complete Command Reference

### Level 1: Basic Commands

**Shebang and Execution**

| Syntax | Purpose |
|--------|---------|
| `#!/bin/bash` | Shebang for bash |
| `#!/usr/bin/env bash` | Portable shebang |
| `chmod +x file && ./file` | Execute script |
| `bash file` | Run with bash explicitly |
| `source file` or `. file` | Run in current shell |

**Variables**

| Code | Purpose |
|------|---------|
| `name="value"` | Assign variable |
| `"$var"` | Use variable (always quote) |
| `${var:-default}` | Default if unset |
| `${#var}` | String length |
| `${var:offset:len}` | Substring |
| `${var/old/new}` | Replace first match |
| `${var//old/new}` | Replace all matches |
| `readonly var=N` | Make read-only |
| `declare -i var=N` | Integer attribute |
| `declare -r var=N` | Read-only (same as `readonly`) |
| `declare -l var=S` | Auto-lowercase on assign |
| `declare -u var=S` | Auto-uppercase on assign |
| `declare -x var=N` | Export to environment |
| `declare -g var=N` | Global scope (in function) |
| `declare -a arr=()` | Indexed array |
| `declare -A map=()` | Associative array |
| `declare -n ref=v` | Nameref (alias) |
| `declare -p var` | Print attributes and value |
| `typeset var=N` | Older synonym for `declare` |

**Conditionals**

| Code | Purpose |
|------|---------|
| `[ condition ]` | Test (old syntax) |
| `[[ condition ]]` | Test (new bash, safer) |
| `-f file` | Is regular file |
| `-d dir` | Is directory |
| `-e path` | Exists |
| `-z string` | Is empty |
| `-n string` | Is not empty |
| `=~ regex` | Regex match |
| `&&` | AND |
| `\|\|` | OR |


### Level 2: Intermediary Commands

**Loops**

| Code | Purpose |
|------|---------|
| `for i in list; do done` | Iterate |
| `for ((i=0; i<n; i++)); do done` | C-style loop |
| `while condition; do done` | While true |
| `until condition; do done` | Until true |
| `break` | Exit loop |
| `continue` | Next iteration |

**Functions**

| Code | Purpose |
|------|---------|
| `func() { ... }` | Define function |
| `local var` | Local variable in function |
| `return N` | Return exit code |

**Input/Output**

| Code | Purpose |
|------|---------|
| `read var` | Read user input |
| `read -p "prompt" var` | Read with prompt |
| `read -s var` | Read silently (password) |
| `read -t 5 var` | Read with timeout |
| `while IFS= read -r line; do done < file` | Read file line by line |

**Arrays**

| Code | Purpose |
|------|---------|
| `arr=(a b c)` | Create array |
| `"${arr[0]}"` | First element |
| `"${arr[@]}"` | All elements |
| `"${#arr[@]}"` | Array length |
| `arr+=(d)` | Append element |
| `declare -A map` | Associative array |


### Level 3: Advanced Commands

**Script Safety**

| Code | Purpose |
|------|---------|
| `set -e` | Exit on error |
| `set -u` | Error on undefined var |
| `set -o pipefail` | Fail on pipe error |
| `set -Eeuo pipefail` | Full safety |
| `trap cmd EXIT` | Run on exit |
| `trap cmd INT TERM` | Run on interrupt |

**getopts**

| Code | Purpose |
|------|---------|
| `getopts "vo:n:" opt` | Parse options |
| `$OPTARG` | Option argument value |
| `shift $((OPTIND-1))` | Remove processed options |

**Cron**

| Code | Purpose |
|------|---------|
| `crontab -e` | Edit cron jobs |
| `crontab -l` | List cron jobs |
| `crontab -r` | Remove all jobs |





[← Previous](17-level-3-practices.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-7.md)
