## 🔍 Section 13: coredumpctl — Crash Dump Analysis

Modern Linux uses `systemd-coredump` to capture and manage core dumps via the journal.

### Listing Core Dumps

```bash
# List all stored core dumps
coredumpctl list

# Filter by PID, command, or time
coredumpctl list --since yesterday
coredumpctl list /usr/bin/nginx
coredumpctl list --pid 1234
```

### Inspecting a Core Dump

```bash
# Get detailed info
coredumpctl info
coredumpctl info 1234          # By PID
coredumpctl info /usr/bin/myapp  # By command name
coredumpctl info 1e23 4c56     # By journal cursor

# Output as JSON
coredumpctl --json=pretty info
```

### Extracting and Debugging

```bash
# Extract core dump to file
coredumpctl dump > core.dump
coredumpctl dump 1234 > crash.dump

# Open directly in gdb
coredumpctl gdb
coredumpctl gdb 1234
coredumpctl gdb /usr/bin/myapp

# In gdb session:
# (gdb) bt           # Backtrace (call stack)
# (gdb) info locals  # Local variables
# (gdb) list         # Source code around crash
# (gdb) quit
```

### Core Dump Configuration

```bash
# systemd-coredump settings
cat /etc/systemd/coredump.conf

# [Coredump]
# Storage=journal      # Store in journal (default)
# Storage=external     # Store as separate file in /var/lib/systemd/coredump/
# Storage=none         # Don't store
# Compress=yes
# ProcessSizeMax=2G    # Max size to process
# ExternalSizeMax=2G   # Max external file size
# JournalSizeMax=100M  # Max in journal

# Enable/disable coredump storage
# ulimit -c unlimited   # Enable core dumps for current session
# /etc/security/limits.conf:
# *                soft    core            unlimited
```

### Real-World Crash Investigation

```bash
# 1. Set up core dumps
echo "* soft core unlimited" | sudo tee /etc/security/limits.d/core.conf

# 2. Trigger a test crash
cat > crash-test.sh << 'EOF'
#!/bin/bash
kill -SEGV $$    # Self-inflicted segfault
EOF
chmod +x crash-test.sh
./crash-test.sh

# 3. Find the dump
coredumpctl list
coredumpctl info crash-test.sh

# 4. Analyze
coredumpctl gdb
# (gdb) bt full
# (gdb) info registers
# (gdb) quit

# 5. Clean up
coredumpctl delete  # Remove all stored dumps
```



[← Previous](22-section-12-auditd-linux-audit-framework.md) | [↑ Index](index.md) | [Next →](24-level-4-mastery-scenarios.md)
