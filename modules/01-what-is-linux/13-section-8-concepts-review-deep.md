## 🧠 Section 8: Concepts Review — Deep Understanding

Let's connect everything you just did:

### The Path of a Command

When you type `ls`:

```
You type: ls
    ↓
Shell (bash) receives "ls"
    ↓
Shell searches PATH for "ls" → finds /usr/bin/ls
    ↓
Shell asks kernel to run /usr/bin/ls
    ↓
Kernel loads the program, gives it memory
    ↓
Program runs, reads current directory from kernel
    ↓
Program outputs file names
    ↓
Shell displays output to your terminal
    ↓
You see the result
```

Every single command you type goes through this process.

### Why `/proc` Is Magic

`/proc` does not exist on your disk. It is created **live** by the kernel every time you look at it.

```bash
cat /proc/uptime
# Shows seconds since boot — live, real-time data
```

This is what "everything is a file" means in practice — even live system data is accessed like a file.





[← Previous](12-level-3-advanced-how-linux.md) | [↑ Index](index.md) | [Next →](14-summary-what-you-learned-in.md)
