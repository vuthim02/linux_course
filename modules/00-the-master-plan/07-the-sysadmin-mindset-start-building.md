## 🧰 The SysAdmin Mindset — Start Building It Now

### 1. Assume Nothing, Verify Everything
```bash
# Beginner thinks:
"The system is fine."

# SysAdmin thinks:
"Let me check:"
systemctl status
df -h
free -h
journalctl -p err -b
```

### 2. Read Error Messages Completely
The error message tells you exactly what is wrong. Beginners stop reading when they see "ERROR". SysAdmins read the next 20 lines.

### 3. Automate Repetitive Work
If you have done something twice, write a script. If you have done it three times, turn it into a systemd service.

### 4. Document Everything
```bash
# Before you change a config file:
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d)

# After you fix something:
echo "2024-01-15: Fixed X by doing Y" >> ~/sysadmin_notes.md
```

### 5. Learn to Learn
The distro you use today may be obsolete in 5 years. The commands change. The tools change. But the **concepts** — processes, files, users, permissions, networking, storage — those never change. Learn the concepts.

---



---

[← Previous](06-suggested-pace.md) | [↑ Index](index.md) | [Next →](08-the-3-books-every-sysadmin.md)
