## 🔍 Section 3: Named Pipes (FIFOs) — Connect Processes Without Files

A **named pipe** (also called a FIFO — First In, First Out) is a special file that connects two processes. Data written to one end is read from the other.

```bash
# Create a named pipe
mkfifo mypipe

# Verify
ls -la mypipe
# prw-r--r-- 1 alice alice 0 Jan 15 10:30 mypipe
# The 'p' means it's a pipe
```

### How It Works

```bash
# Terminal 1: Write to the pipe
echo "Hello through pipe" > mypipe
# This BLOCKS until someone reads from the pipe

# Terminal 2: Read from the pipe
cat < mypipe
# "Hello through pipe" appears
# Both commands then complete
```

### Real Use Case — Server Log Monitoring

```bash
# Create a named pipe for log monitoring
mkfifo /tmp/logpipe

# Terminal 1: Write logs to the pipe
tail -f /var/log/syslog > /tmp/logpipe

# Terminal 2: Read and process logs in real time
cat /tmp/logpipe | grep "ERROR" | tee errors.log
```

### Unnamed Pipes vs Named Pipes

| Aspect | Unnamed Pipe (`\|`) | Named Pipe (`mkfifo`) |
|--------|---------------------|----------------------|
| Persistence | Exists only while commands run | Exists as a file until removed |
| Connection | Connects two running commands | Can connect commands at different times |
| Scope | Current shell session | Any process on the system |

---



---

[← Previous](09-section-2-tee-split-output.md) | [↑ Index](index.md) | [Next →](11-section-4-heredocs-and-herestrings.md)
