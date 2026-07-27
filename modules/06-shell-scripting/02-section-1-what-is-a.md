## 🔍 Section 1: What Is a Shell Script?

A shell script is a **text file containing commands** that bash executes line by line.

```bash
#!/bin/bash
echo "Hello, World!"
```

That is a complete shell script. The `#!` line (called **shebang**) tells the system which interpreter to use.

### The Shebang Explained

```bash
#!/bin/bash       # Use bash
#!/bin/sh         # Use the system shell (might be dash on Debian)
#!/usr/bin/python3 # Use Python
#!/usr/bin/env bash # Use bash wherever it is installed (more portable)
```

> 💡 Always use `#!/bin/bash` for scripts that use bash-specific features (like `[[ ]]`, arrays, `source`). Use `#!/bin/sh` for maximum portability.

### How to Run a Script

```bash
# Method 1: Make executable and run
chmod +x myscript.sh
./myscript.sh

# Method 2: Pass to bash explicitly (no execute permission needed)
bash myscript.sh

# Method 3: Source it (runs in current shell, not a subshell)
source myscript.sh
. myscript.sh        # Same as source
```

### The Difference Between Running and Sourcing

```bash
# Running — creates a subshell:
./script.sh
# Changes to variables/cd are LOST when script ends

# Sourcing — runs in current shell:
source script.sh
# Changes to variables/cd PERSIST after script ends
```

---



---

[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-2-variables-storing-data.md)
