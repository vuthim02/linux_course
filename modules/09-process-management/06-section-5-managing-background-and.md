## 🔍 Section 5: Managing Background and Foreground Jobs

### Running a Process in Background

```bash
# Add & at the end
long_running_command &

# Or press Ctrl+Z to suspend, then bg to background
long_running_command
# Press Ctrl+Z
[1]+  Stopped                 long_running_command
bg
[1]+ long_running_command &
```

### Managing Jobs

```bash
# List background jobs
jobs

# Bring a job to foreground
fg %1

# Run a stopped job in background
bg %1

# Kill a job
kill %1
```

### Output from Background Jobs

```bash
# Background jobs still write to the terminal
# This can be annoying:
find / > output.txt &
# It's fine if output is redirected

# To suppress all output:
find / > /dev/null 2>&1 &
```





[← Previous](05-section-4-signals-how-to.md) | [↑ Index](index.md) | [Next →](07-section-6-nohup-disown-and.md)
