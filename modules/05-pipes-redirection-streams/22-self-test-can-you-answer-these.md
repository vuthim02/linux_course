## 📝 Self-Test — Can You Answer These?

1. What are the three standard streams and their file descriptor numbers?
2. What is the difference between `>` and `>>`?
3. How do you redirect stderr to a file while letting stdout go to the screen?
4. How do you redirect both stdout and stderr to the same file? (give two methods)
5. What does `2>&1` mean and why does the order matter?
6. What does the pipe operator `|` do?
7. What is the difference between `cmd > file 2>&1` and `cmd 2>&1 > file`?
8. How is a named pipe different from an unnamed pipe?
9. What does the `tee` command do? When would you use it?
10. How do you create a multi-line input using heredoc?
11. What is the difference between `<< EOF` and `<< 'EOF'`?
12. What does `wc -w <<< "hello world"` output?
13. How do you create a named pipe?
14. What does `/dev/null` do?
15. Build a single pipeline that: lists all files in `/etc`, filters for `.conf` files, sorts them alphabetically, and counts them.

**Score:** 12/15 correct = ready for Part 6.


## Answer Key

### Q1: What are the three standard streams and their file descriptor numbers?
**Answer:** stdin (0), stdout (1), stderr (2).

### Q2: What is the difference between `>` and `>>`?
**Answer:** `>` overwrites the file; `>>` appends to it.

### Q3: How do you redirect stderr to a file while letting stdout go to the screen?
**Answer:** `command 2> file.txt` — only stderr goes to the file.

### Q4: How do you redirect both stdout and stderr to the same file?
**Answer:** Method 1: `command > file 2>&1` (order matters). Method 2: `command &> file` (bash shorthand).

### Q5: What does `2>&1` mean and why does the order matter?
**Answer:** Redirects stderr (fd 2) to where stdout (fd 1) currently points. In `cmd > file 2>&1`, stdout goes to file, then stderr follows. In `cmd 2>&1 > file`, stderr goes to terminal (stdout's original destination), stdout goes to file.

### Q6: What does the pipe operator `|` do?
**Answer:** Takes stdout of the left command and feeds it as stdin to the right command.

### Q7: What is the difference between `cmd > file 2>&1` and `cmd 2>&1 > file`?
**Answer:** `> file 2>&1` redirects both stdout and stderr to file. `2>&1 > file` sends stderr to terminal (original stdout) and only stdout to file.

### Q8: How is a named pipe different from an unnamed pipe?
**Answer:** A named pipe (FIFO) exists as a file in the filesystem, allowing unrelated processes to communicate. An unnamed pipe only works between related processes (parent/child).

### Q9: What does the `tee` command do?
**Answer:** Reads stdin and writes to both stdout and a file simultaneously. Used to "tee" output to a file while still seeing it on screen.

### Q10: How do you create a multi-line input using heredoc?
**Answer:** `cat <<EOF` then type lines, end with `EOF` on its own line. The delimiter marks start and end of input.

### Q11: What is the difference between `<< EOF` and `<< 'EOF'`?
**Answer:** `<< EOF` performs variable expansion and command substitution inside the heredoc. `<< 'EOF'` treats everything literally (no expansion).

### Q12: What does `wc -w <<< "hello world"` output?
**Answer:** `2` — counts two words ("hello" and "world") from the string via here-string.

### Q13: How do you create a named pipe?
**Answer:** `mkfifo /tmp/mypipe` — creates a FIFO special file.

### Q14: What does `/dev/null` do?
**Answer:** It's a black hole — anything written to it is discarded. Used to suppress output: `command > /dev/null`.

### Q15: Build a single pipeline that lists files in `/etc`, filters `.conf`, sorts, and counts.
**Answer:** `ls /etc | grep '\.conf$' | sort | wc -l`


*Linux SysAdmin Course | Part 5 of ∞ | Reverse Engineering Approach*
*Previous → Part 4: Text Editors — Vim, Nano, and Why They Matter*
*Next → Part 6: Shell Scripting — Automate Everything*

[← Previous](part4.md) | [Next →](part6.md)



[← Previous](21-whats-coming-in-part-6.md) | [↑ Index](index.md)
