## 🔍 Section 14: The Complete Permission Checklist — Troubleshooting

When a user says "I can't access this file," follow this checklist in order:

```
1. Can they see the file?           ── Need r on the directory
2. Can they enter the directory?    ── Need x on the directory
3. Check each parent directory      ── All parents need x
4. Can they read the file?          ── Need r on the file
5. Can they write the file?         ── Need w on the file
6. Can they run the file?           ── Need x on the file
7. Are they the owner?              ── Check chown
8. Are they in the group?           ── Check groups + /etc/group
9. Is there an ACL?                 ── Check getfacl
10. Is SELinux/AppArmor blocking?   ── Check audit log (future parts)
```

### Common Permission Problems

```bash
# Problem: "I copied a file but can't read it"
# Solution: Check parent directory permissions, not just the file

# Problem: "I added user to group but they still can't access"
# Solution: User must LOG OUT and back in for group changes to take effect
# Faster: exec su - $USER   (or newgrp)

# Problem: "My script won't run"
./script.sh
# -bash: ./script.sh: Permission denied
chmod +x script.sh

# Problem: "sudo says I'm not in the sudoers file"
# Solution: Someone must add you using visudo

# Problem: "I can't delete my own file from /tmp"
# Solution: Sticky bit. Only owner can delete.
```





[← Previous](17-section-13-access-control-lists.md) | [↑ Index](index.md) | [Next →](19-practice-section-20-hands-on-exercises.md)
