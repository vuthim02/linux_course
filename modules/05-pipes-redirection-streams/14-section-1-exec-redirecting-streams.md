## 🔍 Section 1: exec — Redirecting Streams for the Entire Shell

The `exec` command can redirect streams for the **current shell**, not just a single command.

```bash
# Redirect all stdout of this shell session to a file
exec > session.log

# Now every command's output goes to the file
ls -la          # Goes to session.log
date            # Goes to session.log
echo "Done"     # Goes to session.log

# Restore stdout by saving it first
exec 3>&1       # Save original stdout to FD 3
exec > session.log
echo "This goes to the log file"
exec >&3        # Restore stdout from FD 3
echo "This goes back to the screen"
```

### Real Use Case — Logging an Entire Script

```bash
#!/bin/bash
# At the top of your script:
exec 2>&1        # Send stderr to stdout
exec > >(tee -a script.log)   # Send stdout to both screen and log

# Now ALL output (including errors) goes to the log AND screen
echo "Script started at $(date)"
ls /nonexistent  # This error will be logged too
echo "Script finished"
```





[← Previous](13-level-2-practices.md) | [↑ Index](index.md) | [Next →](15-section-2-process-substitution-and.md)
