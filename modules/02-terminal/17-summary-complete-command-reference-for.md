## 📋 Summary — Complete Command Reference for Part 2

### Level 1: Basic — Navigation & File Operations

**Navigation**
| Command | What It Does |
|---------|-------------|
| `pwd` | Show current directory |
| `cd /path` | Go to absolute path |
| `cd subdir` | Go to relative path |
| `cd ..` | Go up one level |
| `cd ~` | Go to home directory |
| `cd -` | Go to previous directory |

**Listing**
| Command | What It Does |
|---------|-------------|
| `ls` | List files |
| `ls -la` | List all files with full details |
| `ls -lh` | Human-readable sizes |
| `ls -lt` | Sort by time, newest first |
| `ls -ltr` | Sort by time, oldest first |
| `ls -ld /dir` | Show directory itself, not contents |

**Creating**
| Command | What It Does |
|---------|-------------|
| `mkdir dir` | Create directory |
| `mkdir -p a/b/c` | Create nested directories |
| `touch file` | Create empty file |
| `echo "text" > file` | Create file with content |
| `echo "text" >> file` | Append to file |

**Reading**
| Command | What It Does |
|---------|-------------|
| `cat file` | Print entire file |
| `cat -n file` | Print with line numbers |
| `less file` | Page through file |
| `head -n 20 file` | First 20 lines |
| `tail -n 20 file` | Last 20 lines |
| `tail -f file` | Follow file live |
| `wc -l file` | Count lines |

**Copying and Moving**
| Command | What It Does |
|---------|-------------|
| `cp file dest` | Copy file |
| `cp -r dir dest` | Copy directory |
| `cp -i file dest` | Ask before overwrite |
| `mv old new` | Move or rename |

**Deleting**
| Command | What It Does |
|---------|-------------|
| `rm file` | Delete file |
| `rm -i file` | Ask before deleting |
| `rm -r dir` | Delete directory and contents |

### Level 2: Intermediary — Finding & Links

**Finding**
| Command | What It Does |
|---------|-------------|
| `find . -name "*.txt"` | Find by name |
| `find . -type d` | Find only directories |
| `find . -size +1M` | Find large files |
| `find . -mtime -7` | Modified in last 7 days |

**Links**
| Command | What It Does |
|---------|-------------|
| `ln -s src dest` | Create symbolic link |
| `ln src dest` | Create hard link |

---



---

[← Previous](16-section-11-deep-understanding-how.md) | [↑ Index](index.md) | [Next →](18-whats-coming-in-part-3.md)
