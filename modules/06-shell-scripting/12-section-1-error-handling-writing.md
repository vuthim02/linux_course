## 🔍 Section 1: Error Handling — Writing Safe Scripts

### Trap — Catch Errors and Clean Up

```bash
#!/bin/bash
set -euo pipefail

# Cleanup function — runs on exit
cleanup() {
    echo "Cleaning up..."
    rm -rf /tmp/mytemp.$$
    echo "Done."
}

# Trap EXIT signal (runs when script exits for ANY reason)
trap cleanup EXIT

# Trap specific signals
trap 'echo "Interrupted!"; exit 1' INT TERM

# Main script
echo "Working..."
mkdir -p /tmp/mytemp.$$
sleep 10
echo "Done working."
```

### Checking for Required Commands

```bash
#!/bin/bash

# Check if required commands exist
for cmd in rsync ssh tar gzip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

echo "All required commands are available."
```

### Validating Arguments

```bash
#!/bin/bash

# Check number of arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_dir> <backup_dir>" >&2
    exit 1
fi

# Check if source exists
if [ ! -d "$1" ]; then
    echo "Error: Source directory '$1' does not exist." >&2
    exit 1
fi

# Check if backup directory is writable
if [ ! -w "$(dirname "$2")" ]; then
    echo "Error: Cannot write to '$2'." >&2
    exit 1
fi

echo "All validations passed."
```





[← Previous](11-section-5-input-and-output.md) | [↑ Index](index.md) | [Next →](13-level-2-practices.md)
