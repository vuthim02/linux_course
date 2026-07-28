## 🔍 Section 6: Users and Permissions — Who Controls What

Linux was designed from the beginning for **multiple users**. Every file has an **owner** and **permissions**.

### Three Types of Users

1. **Root (superuser)** — has FULL control of everything. UID = 0
2. **Regular users** — limited power. UID = 1000+
3. **System users** — used by services (web server, database). UID = 1-999

### Check Who You Are

```bash
whoami
```

```bash
id
```

Example output:
```
uid=1000(john) gid=1000(john) groups=1000(john),27(sudo),1001(docker)
```

This tells you:
- Your **user id** (uid)
- Your **primary group** (gid)
- All **groups** you belong to (sudo means you can become root)





[← Previous](08-section-5-the-file-system.md) | [↑ Index](index.md) | [Next →](10-section-7-your-first-terminal.md)
