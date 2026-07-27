## 📋 Summary — Complete Command Reference for Part 3

### Level 1: Basic — Permission Fundamentals

**Reading Permissions**
| Command | What It Does |
|---------|-------------|
| `ls -l file` | Show permissions of file |
| `ls -ld dir` | Show permissions of directory itself |

**Changing Permissions (chmod)**
| Command | What It Does |
|---------|-------------|
| `chmod u+x file` | Add execute for owner |
| `chmod go-w file` | Remove write for group and others |
| `chmod 755 file` | Set to rwxr-xr-x (numeric) |
| `chmod -R 755 dir` | Recursively change directory |

**Changing Ownership**
| Command | What It Does |
|---------|-------------|
| `chown user file` | Change owner |
| `chown user:group file` | Change owner and group |
| `chown :group file` | Change only group |
| `chgrp group file` | Change group |
| `chown -R user dir` | Recursively change |

### Level 2: Intermediary — User & Group Administration

**User Management**
| Command | What It Does |
|---------|-------------|
| `useradd -m -s /bin/bash bob` | Create user with home and shell |
| `useradd -D` | Show default user creation settings |
| `usermod -aG sudo bob` | Add user to supplementary group |
| `usermod -L bob` | Lock user account |
| `usermod -U bob` | Unlock user account |
| `usermod -l newname bob` | Change username |
| `userdel -r bob` | Delete user and home directory |
| `passwd bob` | Set/change password |
| `passwd -l bob` | Lock password |
| `passwd -e bob` | Expire password (force change) |
| `passwd -S bob` | Show password status |

**Group Management**
| Command | What It Does |
|---------|-------------|
| `groupadd developers` | Create group |
| `groupmod -n newname oldname` | Rename group |
| `groupdel developers` | Delete group |
| `gpasswd -a user group` | Add user to group |
| `gpasswd -d user group` | Remove user from group |
| `groups user` | Show user's groups |
| `id user` | Show UID, GID, and all groups |
| `newgrp group` | Temporarily change primary group |

**Sudo**
| Command | What It Does |
|---------|-------------|
| `sudo command` | Run command as root |
| `sudo -u user command` | Run command as another user |
| `sudo -l` | List allowed commands |
| `sudo -s` | Root shell (current dir) |
| `sudo -i` | Root login shell (root's env) |
| `sudo -e file` | Edit file as root safely |
| `visudo` | Safely edit /etc/sudoers |

### Level 3: Advanced — Advanced Access Control

**Special Permissions**
| Command | What It Does |
|---------|-------------|
| `chmod u+s file` | Set SUID |
| `chmod g+s dir` | Set SGID on directory |
| `chmod o+t dir` | Set Sticky Bit |
| `chmod 4755 file` | Set SUID (numeric) |
| `chmod 2755 dir` | Set SGID (numeric) |
| `chmod 1777 dir` | Set Sticky Bit (numeric) |
| `find / -perm -4000` | Find all SUID files |

**Default Permissions (umask)**
| Command | What It Does |
|---------|-------------|
| `umask` | Show current umask |
| `umask 0027` | Set umask temporarily |
| `umask 0027` in `~/.profile` | Set umask permanently |

**ACLs**
| Command | What It Does |
|---------|-------------|
| `getfacl file` | View ACL |
| `setfacl -m u:user:rwx file` | Give user specific access |
| `setfacl -m g:group:rx file` | Give group specific access |
| `setfacl -x u:user file` | Remove user's ACL entry |
| `setfacl -b file` | Remove all ACLs |
| `setfacl -R -m u:user:rwx dir` | Recursively apply ACL |
| `setfacl -dm g:group:rwx dir` | Set default ACL for new files |

---



---

[← Previous](20-deep-understanding-how-permissions-really.md) | [↑ Index](index.md) | [Next →](22-whats-coming-in-part-4.md)
