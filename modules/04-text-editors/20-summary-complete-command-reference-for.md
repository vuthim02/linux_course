## 📋 Summary — Complete Command Reference for Part 4

### Level 1: Basic — Getting Started with Terminal Editors

**Nano**
| Command | Action |
|---------|--------|
| `nano file` | Open file |
| `Ctrl+O` | Save |
| `Ctrl+X` | Exit |
| `Ctrl+W` | Search |
| `Ctrl+K` | Cut line |
| `Ctrl+U` | Paste |
| `Ctrl+_` | Go to line |
| `Alt+U` | Undo |

**Vim — Opening and Closing**
| Command | Action |
|---------|--------|
| `vim file` | Open file |
| `vim +25 file` | Open at line 25 |
| `:q` | Quit (fails if unsaved) |
| `:q!` | Force quit without saving |
| `:w` | Save |
| `:wq` | Save and quit |
| `:x` | Save and quit (same as :wq) |

**Vim — Modes**
| Key | Mode |
|-----|------|
| `i` | Insert mode (type text) |
| `v` | Visual mode (select text) |
| `V` | Visual line mode |
| `Ctrl+v` | Visual block mode |
| `Esc` | Return to Normal mode |
| `:` | Command mode |

### Level 2: Intermediary — Efficient Editing

**Vim — Navigation**
| Key | Action |
|-----|--------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |
| `w` | Next word |
| `b` | Previous word |
| `0` | Start of line |
| `$` | End of line |
| `gg` | Start of file |
| `G` | End of file |
| `:50` | Go to line 50 |
| `Ctrl+f` | Page down |
| `Ctrl+b` | Page up |

**Vim — Editing**
| Key | Action |
|-----|--------|
| `x` | Delete character |
| `dd` | Delete (cut) line |
| `dw` | Delete word |
| `yy` | Copy (yank) line |
| `yw` | Copy word |
| `p` | Paste below |
| `P` | Paste above |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `.` | Repeat last command |

**Vim — Search and Replace**
| Command | Action |
|---------|--------|
| `/term` | Search forward |
| `?term` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `:s/old/new` | Replace first on line |
| `:s/old/new/g` | Replace all on line |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirm |

### Level 3: Advanced — Professional Editor Workflows

**Vim — Multi-file & Windows**
| Command | Action |
|---------|--------|
| `:next` | Next file |
| `:previous` | Previous file |
| `:files` | List buffers |
| `:split file` | Horizontal split |
| `:vsplit file` | Vertical split |
| `Ctrl+w j` | Down to next split |
| `Ctrl+w k` | Up to previous split |
| `vim -d f1 f2` | Diff two files |
| `]c` | Next diff |
| `[c` | Previous diff |
| `:!command` | Run shell command from Vim |
| `:r !command` | Insert command output into file |





[← Previous](19-deep-understanding-how-terminal-editors.md) | [↑ Index](index.md) | [Next →](21-whats-coming-in-part-5.md)
