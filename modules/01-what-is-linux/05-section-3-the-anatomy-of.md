## 🏗️ Section 3: The Anatomy of Linux — 4 Layers

Think of Linux like an **onion**. Each layer wraps around the one inside it.

```
┌─────────────────────────────────────────┐
│           YOU (the user)                │  ← You type commands here
├─────────────────────────────────────────┤
│           SHELL (bash/zsh)              │  ← Translates your words
├─────────────────────────────────────────┤
│        SYSTEM LIBRARIES & TOOLS         │  ← Tools the shell uses
├─────────────────────────────────────────┤
│           LINUX KERNEL                  │  ← Talks to hardware
├─────────────────────────────────────────┤
│           HARDWARE                      │  ← CPU, RAM, Disk, etc.
└─────────────────────────────────────────┘
```

### Layer 1 — The Kernel (The Brain)

The **kernel** is the core of Linux. It is the actual Linux that Linus Torvalds wrote.

It handles:
- **Memory management** — gives RAM to programs
- **Process management** — runs multiple programs at once
- **Device drivers** — talks to hardware
- **File system** — reads/writes your disk

> 🔍 You never talk directly to the kernel. It runs silently in the background.

To see your kernel version:
```bash
uname -r
```

Example output:
```
6.1.0-21-amd64
```

### Layer 2 — System Libraries (The Toolkit)

Programs need tools. The kernel provides raw power but not convenience.

The **C Library (glibc)** and other system libraries give programs ready-made functions like:
- "Open this file"
- "Connect to this network"
- "Display this text"

You don't use these directly either. But every program you run uses them constantly.

### Layer 3 — The Shell (Your Translator)

This is where YOU interact with Linux.

The **shell** is a program that:
- Reads what you type
- Translates it into kernel instructions
- Shows you the result

The most common shell is **Bash** (Bourne Again Shell).

```bash
# When you type this:
ls

# The shell translates it to:
# "Ask the kernel to list the contents of the current directory"
# Then show you the result
```

### Layer 4 — You (The User)

You sit at the top. You give commands in human-readable text. The shell and kernel handle everything below.

---



---

[← Previous](04-section-2-what-is-linux.md) | [↑ Index](index.md) | [Next →](06-section-4-linux-distributions-why.md)
