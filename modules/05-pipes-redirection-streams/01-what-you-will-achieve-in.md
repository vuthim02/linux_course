## 🎯 What You Will Achieve in Part 5

| Level | What You Will Master |
|-------|---------------------|
| ⭐ **Level 1: Basic** | Understand stdin, stdout, and stderr — what they are and where they go. Redirect output to files (overwrite and append). Redirect input from files. Use pipes to chain commands into powerful data pipelines. |
| ⭐ **Level 2: Intermediary** | Redirect errors separately from normal output. Combine multiple streams into one. Use `tee` to see output AND save it simultaneously. Understand named pipes (FIFOs) for inter-process communication. Use heredocs and herestrings for multi-line input. |
| ⭐ **Level 3: Advanced** | Use `exec` to redirect streams for the entire shell. Master process substitution `<()` and `>()`. Create custom file descriptors beyond 0/1/2. Understand how streams work in the kernel. Build professional system reports with advanced redirection. |


# ⭐ Level 1: Basic — Understanding the Three Streams

![POSIX pipeline of standard streams showing terminal, stdin, stdout, stderr between two programs](https://upload.wikimedia.org/wikipedia/commons/f/f6/Pipeline.svg)
*Diagram: POSIX pipeline of standard streams. Credit: XcepticZP / TuukkaH, Public Domain.*

> **Level 1 Goal:** Understand stdin, stdout, stderr, basic redirection (`>`, `>>`, `<`), and pipes (`|`) to chain simple commands into data-processing pipelines.




[↑ Index](index.md) | [Next →](02-section-1-the-three-streams.md)
