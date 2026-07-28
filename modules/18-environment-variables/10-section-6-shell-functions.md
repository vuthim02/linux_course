## 🔍 Section 6: Shell Functions

Functions are more powerful than aliases — they can accept arguments.

### Simple Functions

```bash
# Define a function (can be in ~/.bashrc or ~/.bash_profile)
mydir() {
    mkdir -p "$1" && cd "$1"
}

# Use it
mydir /tmp/newproject
# Creates directory AND changes into it
```

### Practical Sysadmin Functions

```bash
# Extract any archive regardless of type
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.gz)  tar -xzf "$1" ;;
            *.tar.bz2) tar -xjf "$1" ;;
            *.tar.xz)  tar -xJf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "Unknown archive type" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

# Find large files
findbig() {
    find / -type f -size +"${1:-100}"M -exec ls -lh {} \; 2>/dev/null
}

# Show disk usage by directory
dusort() {
    du -sh "${1:-.}"/* | sort -rh
}

# Backup a file with timestamp
bak() {
    cp "$1" "$1.$(date +%Y%m%d_%H%M%S).bak"
}

# Create a temporary directory and go there
tmpdir() {
    cd "$(mktemp -d)"
}
```

### Listing and Removing Functions

```bash
# List all functions
declare -f

# List function names only
declare -F

# Remove a function
unset -f mydir
```





[← Previous](09-level-3-advanced-shell-functions.md) | [↑ Index](index.md) | [Next →](11-section-7-the-prompt-ps1.md)
