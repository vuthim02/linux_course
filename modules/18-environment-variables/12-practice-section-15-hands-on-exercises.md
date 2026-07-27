## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: Environment Basics

---

### ✅ Practice 1: Explore Your Current Environment

```bash
mkdir -p ~/linux-course/part18
cd ~/linux-course/part18

# View all environment variables
env | sort > all_env.txt
echo "Total environment variables: $(wc -l < all_env.txt)"
head -20 all_env.txt

# Check specific important variables
echo ""
echo "=== Important variables ==="
for var in PATH HOME USER SHELL LANG TERM EDITOR PAGER; do
    echo "$var = ${!var:-NOT SET}"
done
```

---

### ✅ Practice 2: PATH Exploration

```bash
cd ~/linux-course/part18

# Show PATH with one directory per line
echo "$PATH" | tr ':' '\n'

# Count directories in PATH
echo ""
echo "Number of PATH entries: $(echo "$PATH" | tr ':' '\n' | wc -l)"

# Find which directory provides common commands
echo ""
echo "=== Command locations ==="
for cmd in ls cp mv cat less grep; do
    which "$cmd"
done
```

---

### Level 2 Practices: Configuration, Startup Files, and Aliases

### ✅ Practice 3: Create and Export Variables

```bash
cd ~/linux-course/part18

# Create a shell variable
MYNAME="Linux Student"
echo "Shell variable: $MYNAME"

# Create a child shell — MYNAME is NOT available
echo "In child shell (without export):"
bash -c 'echo "MYNAME = ${MYNAME:-NOT SET}"'

# Export it
export MYNAME
echo ""
echo "In child shell (after export):"
bash -c 'echo "MYNAME = $MYNAME"'
```

---

### ✅ Practice 4: Set Variable for One Command

```bash
cd ~/linux-course/part18

# Set a variable just for this command
LANGUAGE=fr date

# The variable is NOT set in the current shell
echo "LANGUAGE = ${LANGUAGE:-NOT SET}"

# Set multiple variables
LANG=fr_FR.UTF-8 LC_TIME=fr_FR.UTF-8 date
```

---

### ✅ Practice 5: Explore Shell Startup Files

```bash
cd ~/linux-course/part18

# Check which startup files exist
echo "=== Your startup files ==="
for file in ~/.bash_profile ~/.bash_login ~/.profile ~/.bashrc ~/.bash_logout; do
    if [ -f "$file" ]; then
        echo "EXISTS: $file ($(wc -l < "$file") lines)"
    else
        echo "MISSING: $file"
    fi
done

# Check system-wide files
echo ""
echo "=== System-wide startup files ==="
for file in /etc/profile /etc/bash.bashrc /etc/environment; do
    if [ -f "$file" ]; then
        echo "EXISTS: $file ($(wc -l < "$file") lines)"
    fi
done

# List profile.d scripts
echo ""
echo "=== /etc/profile.d scripts ==="
ls /etc/profile.d/ 2>/dev/null
```

---

### ✅ Practice 6: Read Your .bashrc

```bash
cd ~/linux-course/part18

if [ -f ~/.bashrc ]; then
    echo "=== Your .bashrc ==="
    cat ~/.bashrc
else
    echo ".bashrc does not exist — creating a basic one"
    cat > ~/.bashrc << 'EOF'
# ~/.bashrc: executed by bash for interactive non-login shells

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias lt='ls -ltr'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -ch'
alias free='free -h'

# Prompt
export PS1='\u@\h:\w\$ '

# PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
    echo "Created ~/.bashrc"
fi
```

---

### ✅ Practice 7: Create Useful Aliases

```bash
cd ~/linux-course/part18

# Create temporary aliases
alias ll='ls -la'
alias lt='ls -ltr'
alias dfh='df -h'
alias dus='du -sh *'
alias myip='hostname -I'

# Test them
echo "Testing aliases:"
ll
dfh

# List the new aliases
echo ""
echo "=== Current aliases ==="
alias | grep -E "ll|lt|dfh|dus|myip"

# Unalias
unalias ll lt dfh dus myip
```

---

### Level 3 Practices: Functions, Prompt, Debugging, and Auditing

### ✅ Practice 8: Create Shell Functions

```bash
cd ~/linux-course/part18

# Create a useful function
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Test it
mkcd /tmp/mkcd-test
pwd
cd -

# Create a backup function
bak() {
    cp -r "$1" "${1}_$(date +%Y%m%d_%H%M%S).bak"
}

# Test it
touch /tmp/testfile.txt
bak /tmp/testfile.txt
ls -la /tmp/testfile*

# Create a function with error handling
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.gz|*.tgz)  tar -xzf "$1" ;;
            *.tar.bz2) tar -xjf "$1" ;;
            *.tar.xz)  tar -xJf "$1" ;;
            *.zip)     unzip "$1" ;;
            *)         echo "Cannot extract: $1 (unknown type)" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

# Clean up
rm -f /tmp/testfile.txt /tmp/testfile*.bak
```

---

### ✅ Practice 9: Customize Your Prompt

```bash
cd ~/linux-course/part18

# Save current prompt
OLD_PS1="$PS1"

# Try different prompts
echo "=== Prompt variations ==="
PS1='[\t] \u@\h:\w\$ '
echo "Try this prompt: PS1='[\t] \u@\h:\w\$ '"

PS1='\u@\h:\n\$ '
echo "Or multi-line: PS1='\u@\h:\n\$ '"

# Restore
PS1="$OLD_PS1"
```

---

### ✅ Practice 10: Environment Inheritance

```bash
cd ~/linux-course/part18

# Demonstrate inheritance
export COURSE_VAR="Part18"

# Run a script
bash -c 'echo "In child: COURSE_VAR=$COURSE_VAR"'

# Subshell also inherits
(
    echo "In subshell: COURSE_VAR=$COURSE_VAR"
)

# Unset and verify
unset COURSE_VAR
bash -c 'echo "After unset: COURSE_VAR=${COURSE_VAR:-NOT SET}"'
```

---

### ✅ Practice 11: Locale Settings

```bash
cd ~/linux-course/part18

# Current locale
echo "Current locale: $LANG"
locale | head -10

# List available locales (first 20)
echo ""
echo "=== Available locales (first 10) ==="
locale -a | head -10

# Try different date formats
echo ""
echo "=== Date in different locales ==="
LANG=en_US.UTF-8 date
LANG=de_DE.UTF-8 date
LANG=fr_FR.UTF-8 date
LANG=ja_JP.UTF-8 date
```

---

### ✅ Practice 12: Add to PATH Temporarily

```bash
cd ~/linux-course/part18

# Create a personal bin directory
mkdir -p ~/bin

# Create a custom script
cat > ~/bin/hello-course << 'EOF'
#!/bin/bash
echo "Hello from PATH! Course: Part 18"
EOF
chmod +x ~/bin/hello-course

# Add to PATH
export PATH="$HOME/bin:$PATH"

# Run it
hello-course

# Check which
which hello-course

# Clean up
rm ~/bin/hello-course
```

---

### ✅ Practice 13: Debug Shell Configuration

```bash
cd ~/linux-course/part18

# Trace what happens when bash starts (login shell)
echo "=== Tracing bash startup ==="
bash -lx -c 'echo "--- Startup complete ---"' 2>&1 | grep -E "Reading|source|\.bash|\.profile|/etc/profile" | head -20 ||
  echo "Would show startup file loading order"

# Check environment size
echo ""
echo "=== Environment size ==="
env | wc -c
echo "bytes"
```

---

### ✅ Practice 14: .bash_logout

```bash
cd ~/linux-course/part18

# Check if .bash_logout exists
if [ -f ~/.bash_logout ]; then
    echo "=== Your .bash_logout ==="
    cat ~/.bash_logout
else
    echo ".bash_logout does not exist"
    echo "This runs when you log out (for cleanup)"
    echo "Example content:"
    cat << 'EOF'
# ~/.bash_logout
# Clear console on logout
clear
# Or: save history
history -a
EOF
fi
```

---

### ✅ Practice 15: Real SysAdmin Scenario — Environment Audit

```bash
cd ~/linux-course/part18

cat > environment_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="environment_audit_report.txt"

echo "============================================" > "$REPORT"
echo "  ENVIRONMENT AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: Shell info
echo "1. SHELL INFORMATION" >> "$REPORT"
echo "  Shell: $SHELL" >> "$REPORT"
echo "  Version: $(bash --version | head -1)" >> "$REPORT"
echo "" >> "$REPORT"

# Section 2: PATH analysis
echo "2. PATH ANALYSIS" >> "$REPORT"
echo "  PATH has $(echo "$PATH" | tr ':' '\n' | wc -l) directories" >> "$REPORT"
echo "  PATH length: ${#PATH} characters" >> "$REPORT"
echo "" >> "$REPORT"

# Section 3: Key variables
echo "3. KEY ENVIRONMENT VARIABLES" >> "$REPORT"
for var in HOME USER SHELL LANG TERM EDITOR PAGER DISPLAY TZ; do
    echo "  $var = ${!var:-NOT SET}" >> "$REPORT"
done
echo "" >> "$REPORT"

# Section 4: Startup files status
echo "4. STARTUP FILES STATUS" >> "$REPORT"
for file in /etc/profile ~/.bash_profile ~/.bashrc ~/.profile ~/.bash_logout; do
    if [ -f "$file" ]; then
        echo "  EXISTS: $file ($(wc -l < "$file") lines)" >> "$REPORT"
    else
        echo "  MISSING: $file" >> "$REPORT"
    fi
done
echo "" >> "$REPORT"

# Section 5: Aliases
echo "5. ACTIVE ALIASES" >> "$REPORT"
alias | sed 's/^/  /' >> "$REPORT" || echo "  No aliases" >> "$REPORT"
echo "" >> "$REPORT"

# Section 6: Custom PATH entries
echo "6. CUSTOM PATH ENTRIES" >> "$REPORT"
echo "$PATH" | tr ':' '\n' | grep -E "home|local|private|custom" | sed 's/^/  /' >> "$REPORT" || \
  echo "  No custom PATH entries found" >> "$REPORT"
echo "" >> "$REPORT"

# Section 7: Locale
echo "7. LOCALE SETTINGS" >> "$REPORT"
locale | sed 's/^/  /' >> "$REPORT"
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x environment_audit.sh
./environment_audit.sh
```

---



---

[← Previous](11-section-7-the-prompt-ps1.md) | [↑ Index](index.md) | [Next →](13-deep-understanding-how-the-shell.md)
