## 🔍 Section 2: Paths — The Address of Every File

Every file and folder in Linux has an **address** called a **path**.

There are two types:

### Absolute Path

Starts with `/`. Always points to the **same location** no matter where you are.

```
/home/john/documents/report.txt
```

Read this as:
- Start at root `/`
- Go into `home`
- Go into `john`
- Go into `documents`
- The file is `report.txt`

### Relative Path

Does **NOT** start with `/`. It is **relative to where you currently are**.

If you are currently in `/home/john`:
```
documents/report.txt
```
This means: "starting from where I am now, go into documents, find report.txt"

### Special Relative Shortcuts

| Symbol | Meaning | Example |
|--------|---------|---------|
| `.` | Current directory | `./script.sh` = run script in current folder |
| `..` | Parent directory (one level up) | `cd ..` = go up one level |
| `~` | Your home directory | `cd ~` = go to your home |
| `-` | Previous directory | `cd -` = go back to where you just were |

### Visual Example

```
/
└── home/
    └── john/           ← You are HERE (current directory)
        ├── documents/
        │   └── report.txt
        └── pictures/
            └── photo.jpg
```

| Goal | Absolute Path | Relative Path |
|------|--------------|---------------|
| Go to documents | `cd /home/john/documents` | `cd documents` |
| Go to pictures | `cd /home/john/pictures` | `cd pictures` |
| Go up to /home | `cd /home` | `cd ..` |
| Go to /etc | `cd /etc` | `cd ../../etc` |





[← Previous](03-section-1-reverse-engineering-the.md) | [↑ Index](index.md) | [Next →](05-section-3-the-ls-command.md)
