#!/bin/bash

MAX=60

for ((i=0; i<=MAX; i++)); do
    file="part${i}.md"

    echo "" >> "$file"

    if [ "$i" -eq 0 ]; then
        echo "[Next →](part1.md)" >> "$file"

    elif [ "$i" -eq "$MAX" ]; then
        prev=$((i - 1))
        echo "[← Previous](part${prev}.md)" >> "$file"

    else
        prev=$((i - 1))
        next=$((i + 1))
        echo "[← Previous](part${prev}.md) | [Next →](part${next}.md)" >> "$file"
    fi
done