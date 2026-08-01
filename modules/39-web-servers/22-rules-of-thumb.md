## 📏 Rules of Thumb

### The Web Server Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always test config** | `nginx -t` or `apachectl configtest` | Prevent restart failures |
| **Check error logs** | First step in debugging | Find root cause |
| **Use reverse proxy** | Don't expose app directly | Security |
| **Enable gzip** | Compress responses | Performance |

---

**Why these rules matters:** Following these rules ensures reliable web server operation.

[← Previous](19-self-test-can-you-answer-these.md) | [↑ Index](index.md)
