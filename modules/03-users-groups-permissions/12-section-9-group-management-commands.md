## 🔍 Section 9: Group Management Commands

### groupadd — Create a Group

```bash
sudo groupadd developers
sudo groupadd -g 2000 developers     # Specific GID
sudo groupadd -r backend              # System group (GID < 1000)
```

### groupmod — Modify a Group

```bash
sudo groupmod -n newname oldname      # Rename group
sudo groupmod -g 2500 developers      # Change GID
```

### groupdel — Delete a Group

```bash
sudo groupdel oldproject
# Fails if group is a primary group for any user
```

### gpasswd — Manage Group Membership

```bash
# Add user to group
sudo gpasswd -a alice developers

# Remove user from group
sudo gpasswd -d alice developers

# Set group administrators (users who can add/remove members)
sudo gpasswd -A alice developers
```

### groups — See Group Membership

```bash
# Show your groups
groups

# Show another user's groups
groups alice

# Show all groups a user belongs to (primary + supplementary)
id alice
# uid=1001(alice) gid=1001(alice) groups=1001(alice),4(adm),27(sudo),1002(developers)
```

### The `newgrp` Command — Change Primary Group Temporarily

```bash
# If you belong to multiple groups, change your effective group
newgrp developers
# All files created now will have 'developers' as group
# Type 'exit' to go back to original group
```





[← Previous](11-section-8-user-management-commands.md) | [↑ Index](index.md) | [Next →](13-section-10-sudo-becoming-root.md)
