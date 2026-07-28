## 🔍 Section 13: Access Control Lists (ACLs) — Fine-Grained Permissions

Standard permissions only give you three groups: owner, group, others. **ACLs** let you give permissions to specific users or groups.

### Check if ACLs Are Supported

```bash
# Filesystem must be mounted with 'acl'
mount | grep " acl "

# Check filesystem type (ext4, xfs usually support it by default)
df -T /home
```

### ACL Commands

```bash
# View ACL of a file
getfacl file.txt

# Set ACL: give alice read/write access
setfacl -m u:alice:rw file.txt

# Set ACL: give developers group read/execute
setfacl -m g:developers:rx file.txt

# Remove a specific ACL entry
setfacl -x u:alice file.txt

# Remove ALL ACL entries (back to standard permissions)
setfacl -b file.txt

# Apply ACL recursively to a directory
setfacl -Rm u:alice:rwx /shared/project

# Set default ACL — new files inherit this
setfacl -dm u:alice:rwx /shared/project
# Now every file/dir created INSIDE /shared/project gets ACL for alice
```

### How ACLs Show in ls -l

When a file has ACLs, `ls -l` shows a `+` at the end of the permission string:

```bash
-rw-rw-r--+ 1 alice alice 0 Jan 15 10:30 file.txt
#           ↑
#           + means ACLs are set
```

### Real ACL Example — Shared Project Directory

```bash
sudo mkdir -p /shared/project
sudo chown root:project /shared/project
sudo chmod 770 /shared/project

# Give alice (who is not in 'project' group) full access
sudo setfacl -m u:alice:rwx /shared/project

# Give bob read-only access
sudo setfacl -m u:bob:r-x /shared/project

# Verify
getfacl /shared/project
# # file: shared/project
# # owner: root
# # group: project
# user::rwx
# user:alice:rwx
# user:bob:r-x
# group::rwx
# mask::rwx
# other::---
```





[← Previous](16-section-12-umask-default-permissions.md) | [↑ Index](index.md) | [Next →](18-section-14-the-complete-permission.md)
