## 🔍 Section 5: Creating Directories and Files

### `mkdir` — Make Directory

```bash
mkdir projects                    # Create one directory
mkdir -p projects/web/css         # Create nested directories in one command
mkdir -p projects/{web,api,docs}  # Create multiple directories at once
```

The `-p` flag means "make parent directories too, and don't error if they exist."

Without `-p`:
```bash
mkdir projects/web/css
# ERROR: projects/web doesn't exist yet!
```

With `-p`:
```bash
mkdir -p projects/web/css
# Creates: projects/ then projects/web/ then projects/web/css/
# All in one command. No errors.
```

### `touch` — Create Empty Files (and Update Timestamps)

```bash
touch file.txt                    # Create empty file
touch file1.txt file2.txt         # Create multiple files at once
touch -m file.txt                 # Update only modification time
touch -t 202401151030 file.txt    # Set a specific timestamp
```

> 🔍 **What `touch` really does:** Originally designed to "touch" a file's timestamp (update when it was last modified). Creating an empty file is a side effect — if the file doesn't exist, `touch` creates it. Sysadmins use this to create flag files that scripts check for.

### `echo` and Redirection — Create Files With Content

```bash
# Write text into a file (overwrites if exists)
echo "Hello, Linux" > myfile.txt

# APPEND text to a file (adds to the end, doesn't overwrite)
echo "Second line" >> myfile.txt

# Create a multi-line file using heredoc
cat > config.txt << EOF
server=localhost
port=8080
debug=true
EOF
```

> ⚠️ **Critical difference:**
> - `>` = **overwrite** (destroys existing content)
> - `>>` = **append** (adds to existing content)
>
> Many beginners accidentally destroy files by using `>` when they meant `>>`.





[← Previous](06-section-4-hidden-files-linuxs.md) | [↑ Index](index.md) | [Next →](08-section-6-reading-file-contents.md)
