## 🔍 Section 1: The Three Streams — stdin, stdout, stderr

Every Linux program starts with three open streams:

```
┌─────────────────────┐
│                     │
│     PROGRAM         │
│                     │
│  stdin  (0)  ◄──────┼───── Keyboard (by default)
│  stdout (1)  ──────►├───── Terminal screen (by default)
│  stderr (2)  ──────►├───── Terminal screen (by default)
│                     │
└─────────────────────┘
```

| Stream | Number | Default | Purpose |
|--------|--------|---------|---------|
| **stdin** | 0 | Keyboard | Input to the program |
| **stdout** | 1 | Screen | Normal output from the program |
| **stderr** | 2 | Screen | Error messages from the program |

### The Key Insight

stdout and stderr both go to the screen by default. **This is why errors and normal output appear together.** Separating them is one of the most powerful things a sysadmin can do.

### Identifying Streams in Practice

```bash
# This command produces both normal output and errors:
find / -name "hosts"
# Normal output: paths to files named "hosts"
# Error output: "Permission denied" messages

# Both look the same on screen. But they come from different streams.
```

---



---

[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-redirecting-stdout-the.md)
