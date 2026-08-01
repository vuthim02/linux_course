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

### Variable Attributes with declare/typeset

```bash
# Readonly variable (cannot be changed)
declare -r DB_PASS="s3cret"
DB_PASS="new"  # Error: readonly variable

# Integer variable (arithmetic, not string)
declare -i COUNT=5
COUNT=COUNT+3     # Result: 8 (no $ needed)
echo "$COUNT"     # 8

# Array variable
declare -a FRUITS=("apple" "banana" "cherry")
echo "${FRUITS[0]}"  # apple

# Associative array (key-value)
declare -A USER_IDS=(["alice"]=1001 ["bob"]=1002)
echo "${USER_IDS[alice]}"  # 1001

# Lowercase/uppercase (bash 4+)
declare -l NAME="HELLO"   # Automatically lowercase
echo "$NAME"              # hello
declare -u NAME="hello"   # Automatically uppercase
echo "$NAME"              # HELLO

# Export all variables automatically
set -a    # allexport — every variable is exported
MYVAR="test"  # automatically exported
set +a    # disable
```

### Safe Variable Handling

```bash
# Print variable safely quoted (for reuse in shell)
printf '%q\n' "$PATH"

# Check if variable is set
[[ -v HOME ]] && echo "HOME is set"

# Use default value if unset
echo "${MYVAR:-default}"   # prints "default" if MYVAR is not set
echo "${MYVAR:=default}"   # assigns default if unset, then prints
echo "${MYVAR:?error msg}" # error if not set (good for required vars)

# Substring removal (for paths)
path="/home/user/file.txt"
echo "${path##*/}"   # file.txt  (remove longest */ prefix)
echo "${path%/*}"    # /home/user (remove shortest /* suffix)
echo "${path%.*}"    # /home/user/file (remove shortest .* suffix)
```





[← Previous](09-level-3-advanced-shell-functions.md) | [↑ Index](index.md) | [Next →](11-section-7-the-prompt-ps1.md)
