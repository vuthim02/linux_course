## 🧠 Deep Understanding — How Streams Really Work

### Every File Is a Stream

Remember "everything is a file" from Part 1? stdin, stdout, stderr are **file descriptors** — numbers that point to open files.

```bash
# See the file descriptors of your current shell
ls -la /proc/$$/fd
# lrwx------ 1 alice alice 64 Jan 15 10:30 0 -> /dev/pts/0
# lrwx------ 1 alice alice 64 Jan 15 10:30 1 -> /dev/pts/0
# lrwx------ 1 alice alice 64 Jan 15 10:30 2 -> /dev/pts/0

# All three point to your terminal device
```

When you redirect:

```bash
ls > file.txt 2>&1
# Before:  1 -> /dev/pts/0, 2 -> /dev/pts/0
# After:   1 -> /path/to/file.txt, 2 -> /path/to/file.txt
# The redirect just changes where the file descriptor points
```

### What Happens in the Kernel

```
1. Shell forks a child process for the command
2. Before exec'ing the command, shell rearranges file descriptors:
   - Opens the target file
   - Uses dup2() to copy the file descriptor to 1 (stdout)
   - Closes the original fd
3. Child process inherits the modified file descriptors
4. Command writes to stdout — it goes to the file without knowing
```

### Why Pipes Are More Efficient Than Temporary Files

```bash
# Without pipe (uses disk):
ls > /tmp/temp.txt
wc -l < /tmp/temp.txt
rm /tmp/temp.txt

# With pipe (stays in memory):
ls | wc -l
```

The pipe buffer lives in kernel memory, not on disk. For large data, pipes avoid disk I/O entirely.

### The Pipe Buffer Size

```bash
# The pipe buffer is typically 64KB on Linux
# When a pipe is full, the writer blocks
# When a pipe is empty, the reader blocks
# This is automatic flow control

# Check pipe size:
ulimit -a | grep pipe
# pipe size            (512 bytes, -p) 8
# This means 8 * 512 = 4096 bytes default pipe size
```





[← Previous](17-section-4-redirection-gotchas-common.md) | [↑ Index](index.md) | [Next →](19-level-3-practices.md)
