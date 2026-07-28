## 🔍 Section 2: Professional Script Template

```bash
#!/bin/bash
#=======================================================================
# Script:     backup.sh
# Author:     Your Name
# Date:       2024-01-15
# Description: Backup important directories to /backup
# Usage:      ./backup.sh [options]
# Options:    -v       Verbose output
#             -d DIR   Directory to backup (default: /home)
#             -o FILE  Output log file
#=======================================================================

set -Eeuo pipefail

#--- Constants ---
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

#--- Config ---
VERBOSE=0
BACKUP_DIR="/backup"
SOURCE_DIR="/home"
LOG_FILE=""

#--- Functions ---
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

Options:
    -v          Verbose mode
    -d DIR      Directory to backup (default: $SOURCE_DIR)
    -o FILE     Log file
    -h          Show this help

Version: $VERSION
EOF
    exit 0
}

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    if [ "$VERBOSE" -eq 1 ] || [ "$level" = "ERROR" ]; then
        echo "[$timestamp] [$level] $message" >&2
    fi
}

cleanup() {
    log "INFO" "Cleaning up temporary files..."
    # Add cleanup code here
    log "INFO" "Script finished."
}

check_dependencies() {
    local deps=("rsync" "tar" "gzip")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR" "Required command '$cmd' not found."
            exit 1
        fi
    done
}

do_backup() {
    local src="$1"
    local dest="$2"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local archive="backup_$(basename "$src")_$timestamp.tar.gz"
    
    log "INFO" "Starting backup of $src"
    
    if [ ! -d "$src" ]; then
        log "ERROR" "Source directory '$src' does not exist."
        return 1
    fi
    
    mkdir -p "$dest"
    
    tar -czf "$dest/$archive" -C "$(dirname "$src")" "$(basename "$src")"
    
    log "INFO" "Backup created: $dest/$archive"
    return 0
}

#--- Main ---

# Set up trap
trap cleanup EXIT

# Parse arguments
while getopts "vd:o:h" opt; do
    case "$opt" in
        v) VERBOSE=1 ;;
        d) SOURCE_DIR="$OPTARG" ;;
        o) LOG_FILE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check dependencies
check_dependencies

# Run backup
do_backup "$SOURCE_DIR" "$BACKUP_DIR"
```

### Parsing Options With getopts

```bash
#!/bin/bash

usage() {
    echo "Usage: $0 [-v] [-o output_file] [-n count] name"
    exit 1
}

verbose=0
output=""
count=1

while getopts "vo:n:" opt; do
    case "$opt" in
        v) verbose=1 ;;
        o) output="$OPTARG" ;;
        n) count="$OPTARG" ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
    usage
fi

name="$1"
echo "Name: $name, Count: $count, Output: $output, Verbose: $verbose"
```

```bash
$ ./script.sh -v -o report.txt -n 5 Alice
# Name: Alice, Count: 5, Output: report.txt, Verbose: 1
```





[← Previous](13-level-2-practices.md) | [↑ Index](index.md) | [Next →](15-section-3-scheduling-scripts-with.md)
