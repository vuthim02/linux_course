## 🔍 Section 4: chown and chgrp — Changing Ownership

### chown — Change Owner

```bash
# Change only the user owner
sudo chown alice file.txt

# Change both user and group
sudo chown alice:developers file.txt

# Change only the group (colon without username)
sudo chown :developers file.txt

# Change recursively (entire directory tree)
sudo chown -R alice:developers /home/alice/project

# Use reference file to copy ownership
sudo chown --reference=template.txt target.txt
```

### chgrp — Change Group Only (Simpler When You Only Need Group)

```bash
sudo chgrp developers file.txt
sudo chgrp -R developers /shared/project
```

> 💡 `chown alice:group file` changes both in one command. This is the most common pattern professionals use.

### Who Can Change Ownership?

Only **root** can change the owner of a file to another user. This is a security rule: you cannot "give away" your files to avoid responsibility.

However, a user can change the **group** of their own files to any group they belong to:

```bash
# alice is in group "developers"
chgrp developers myfile.txt   # Works — alice belongs to developers
chgrp admins myfile.txt       # Fails — alice is not in admins
```





[← Previous](05-section-3-chmod-changing-permissions.md) | [↑ Index](index.md) | [Next →](07-level-2-intermediary-user-group.md)
