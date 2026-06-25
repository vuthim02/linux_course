#!/bin/bash
# Organize course part files into modules/ directory
# Usage: ./script.sh

mkdir -p modules

for i in {1..60}; do
    file="part${i}.md"
    if [ -f "$file" ]; then
        mv "$file" modules/
        echo "Moved $file to modules/"
    fi
done

echo "Done! All part files are now in modules/"
