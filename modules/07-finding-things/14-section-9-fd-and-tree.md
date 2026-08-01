## Section 9: fd and tree — Modern Alternatives

**fd** is a fast, user-friendly alternative to `find`. **tree** visualizes directory structures.

### fd (Modern find)

```bash
# Install
sudo apt install fd-find       # Debian/Ubuntu (binary: fdfind)
sudo dnf install fd-find        # Fedora

# Common usage
fdfind pattern                  # Find files matching pattern
fdfind -e py                    # Find all .py files
fdfind -H pattern               # Include hidden files
fdfind -x wc -l {}              # Execute command on results
```

### tree (Directory Visualization)

```bash
tree                            # Show directory tree
tree -L 2                       # Limit to 2 levels deep
tree -d                         # Directories only
tree -h                         # Human-readable sizes
tree --gitignore                # Respect .gitignore
```
