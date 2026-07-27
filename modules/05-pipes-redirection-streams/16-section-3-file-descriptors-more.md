## 🔍 Section 3: File Descriptors — More Than Just 0, 1, 2

Linux allows more than just 0/1/2. You can create custom file descriptors.

```bash
# Open file descriptor 3 for writing to a file
exec 3> custom_output.txt

# Write to it
echo "This goes to FD 3" >&3
echo "This also goes to FD 3" >&3

# Close it
exec 3>&-
```

### Practical Example — Log to Multiple Files

```bash
# Create two log channels
exec 3> debug.log
exec 4> error.log

# Use them
echo "Debug: starting process" >&3
echo "Error: something failed" >&4
echo "Normal: continuing"       # Goes to stdout

# Close when done
exec 3>&-
exec 4>&-
```

---



---

[← Previous](15-section-2-process-substitution-and.md) | [↑ Index](index.md) | [Next →](17-section-4-redirection-gotchas-common.md)
