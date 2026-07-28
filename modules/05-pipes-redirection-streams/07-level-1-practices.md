## 💻 Level 1 Practices

### ✅ Practice 1: Redirect stdout

```bash
cd ~/linux-course/part5
mkdir -p ~/linux-course/part5

# List files and save to a file
ls -la /etc > etc_list.txt

# View the file
cat etc_list.txt

# Append more data
echo "---END OF LIST---" >> etc_list.txt

# Verify
tail -5 etc_list.txt
```


### ✅ Practice 2: Pipe Basics

```bash
# Filter ls output
ls /etc | grep "conf"

# Chain three commands
ls /etc | grep "conf" | wc -l

# How many conf files are in /etc?
echo "Number of .conf files in /etc: $(ls /etc | grep '\.conf' | wc -l)"
```


### ✅ Practice 3: Build a Pipeline Step by Step

```bash
cd ~/linux-course/part5

# Problem: What are the 10 most common words in your bash history?
# Step 1: Get history
history > my_history.txt

# Step 2: Extract just the commands (second column)
awk '{print $2}' my_history.txt > commands.txt

# Step 3: Sort them
sort commands.txt > sorted_commands.txt

# Step 4: Count unique occurrences
uniq -c sorted_commands.txt > counted_commands.txt

# Step 5: Sort by frequency (reverse numeric)
sort -rn counted_commands.txt > frequency.txt

# Step 6: Top 10
head -10 frequency.txt

# OR all in one pipeline:
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10
```


### ✅ Practice 4: Redirect stdin From a File

```bash
cd ~/linux-course/part5

# Create a data file
echo -e "banana\napple\ncherry\ndate" > fruits.txt

# Sort with stdin redirect
sort < fruits.txt

# Count lines
wc -l < fruits.txt

# Compare: many commands accept both
sort fruits.txt          # argument
sort < fruits.txt        # stdin redirect
# Same result
```


# ⭐ Level 2: Intermediary — Error Handling and Advanced Redirection

![Schema of POSIX and C standard streams showing terminal, process, stdin, stdout, stderr](https://upload.wikimedia.org/wikipedia/commons/7/70/Stdstreams-notitle.svg)
*Diagram: Standard streams (stdin, stdout, stderr) between terminal and process. Credit: Danielpr85 / TuukkaH, Public Domain.*

> **Level 2 Goal:** Master stderr redirection, combine streams, use `tee` for simultaneous viewing and logging, create named pipes for IPC, and write multi-line input with heredocs and herestrings.




[← Previous](06-common-pipe-patterns-every-sysadmin.md) | [↑ Index](index.md) | [Next →](08-section-1-redirecting-stderr-the.md)
