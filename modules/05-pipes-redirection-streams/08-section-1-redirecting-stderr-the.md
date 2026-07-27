## 🔍 Section 1: Redirecting stderr — The `2>` Operator

Errors and normal output are separate. You can redirect them independently.

```bash
# Send errors to a file, normal output stays on screen
find / -name "hosts" 2> errors.txt

# Send errors to /dev/null (the bit bucket — discard them)
find / -name "hosts" 2> /dev/null

# Send both stdout and stderr to different files
find / -name "hosts" > results.txt 2> errors.txt
```

### /dev/null — The Black Hole

```bash
# Discard ALL output
command > /dev/null 2>&1

# Discard only errors
command 2> /dev/null

# Discard only normal output
command > /dev/null
```

> 💡 `/dev/null` is a special device file. Whatever you write to it disappears forever. Whatever you read from it returns nothing (EOF immediately).

### Redirecting Both Streams to the Same File

```bash
# Method 1: Redirect stderr to stdout, then stdout to file
find / -name "hosts" > all_output.txt 2>&1

# Method 2: Bash shorthand (cleaner)
find / -name "hosts" &> all_output.txt

# Method 3: Append both
find / -name "hosts" &>> all_output.txt
```

### Understanding `2>&1`

Read it right to left:

```
> file     → Send stdout to "file"
2>&1       → Send stderr (2) to where stdout (1) is going

So:  > file 2>&1
     means: stdout goes to file, stderr follows stdout to file
```

Order matters:

```bash
# CORRECT: stdout to file, then stderr to stdout's location
command > file 2>&1

# WRONG: stderr goes to stdout's location (still the screen),
#        then stdout goes to file
command 2>&1 > file
# Result: stderr goes to screen, stdout goes to file (not what you wanted)
```

---



---

[← Previous](07-level-1-practices.md) | [↑ Index](index.md) | [Next →](09-section-2-tee-split-output.md)
