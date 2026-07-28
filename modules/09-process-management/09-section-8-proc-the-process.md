## 🔍 Section 8: /proc — The Process Filesystem

Every running process has a directory in `/proc` with detailed information.

```bash
# View your own process info
ls /proc/$$/
# cmdline          — command that started the process
# cwd              — symlink to current working directory
# environ          — environment variables
# exe              — symlink to executable
# fd/              — open file descriptors
# limits           — resource limits
# maps             — memory mappings
# status           — process status summary

# Read a process's command line
cat /proc/1234/cmdline | tr '\0' ' '

# Read a process's environment
cat /proc/1234/environ | tr '\0' '\n'

# See open files (like lsof)
ls -la /proc/1234/fd/

# Check process status
cat /proc/1234/status
```

### lsof — List Open Files

```bash
# List all open files
lsof

# List files opened by a specific process
lsof -p 1234

# List processes that have a specific file open
lsof /var/log/syslog

# List files opened by a user
lsof -u alice

# List network connections
lsof -i

# List listening ports
lsof -i -P -n | grep LISTEN
```





[← Previous](08-section-7-nice-and-renice.md) | [↑ Index](index.md) | [Next →](10-section-9-zombie-and-orphan.md)
