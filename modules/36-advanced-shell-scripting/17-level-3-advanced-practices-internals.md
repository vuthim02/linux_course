## ⭐ Level 3: Advanced — Practices & Internals

![Advanced terminal](https://upload.wikimedia.org/wikipedia/commons/a/a5/Terminal_icon.svg)

> *"There is no substitute for practice. Internals knowledge turns users into masters."*

### What You'll Cover
- Multi-line sed: hold space, `N`, `H`, `G`, pattern space manipulation
- Advanced awk: associative arrays, multi-file processing, `getline`
- Regex engine internals: NFA vs DFA, backtracking, catastrophic patterns
- Performance optimization: when to use grep vs awk vs sed
- 15 hands-on practices combining all tools from the module
- Building complete admin scripts that solve real-world problems

At the advanced level, you understand the internals of the tools you use — and you can optimize, debug, and extend them for complex tasks.

At this level you will master:

- **Multi-line sed**: The pattern space holds the current line. The hold space is a secondary buffer. `N` appends the next line to the pattern space. `H` appends to the hold space. `G` appends the hold space to the pattern space. Use these to process pairs of lines, merge paragraphs, or extract multi-line blocks.
- **Advanced awk**: `awk '{counts[$1]++} END{for(k in counts) print k, counts[k]}'` counts occurrences. `awk 'FNR==NR{a[$1]=$2; next} $1 in a {print $0, a[$1]}' file1 file2` joins two files. `getline` reads the next line — useful for processing header-data pairs.
- **Regex internals**: NFA (Non-deterministic Finite Automaton) backtracks on partial matches — slow on pathological patterns like `a*a*a*b`. DFA (Deterministic Finite Automaton) processes each character exactly once — faster but uses more memory. Understanding this explains why some regex patterns are slow.
- **Performance**: For simple matching, `grep` is fastest. For field extraction, `awk` is fastest. For substitution, `sed` is fastest. For complex logic, combine tools in a pipeline. Avoid `awk` for simple grep tasks — it has more overhead.
- **Practices**: Build complete scripts for log analysis, configuration auditing, user management, and report generation. Each practice combines multiple tools to solve a realistic sysadmin problem.


[← Previous](16-12-real-world-admin-scripts.md) | [↑ Index](index.md) | [Next →](18-13-hands-on-practices-15.md)
