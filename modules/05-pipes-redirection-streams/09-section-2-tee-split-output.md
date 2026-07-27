## 🔍 Section 2: tee — Split Output to Screen AND File

`tee` splits a stream: one copy goes to a file, another continues to stdout.

```bash
command | tee output.txt
```

```
                    ┌──────────────► Screen
                    │
┌──────────┐    ┌───┴────┐
│ command  │───►│  tee   │
└──────────┘    └───┬────┘
                    │
                    └──────────────► file.txt
```

### Real Uses

```bash
# See the output AND save it
ls -la /etc | tee etc_listing.txt

# Append to file (don't overwrite)
ls -la /etc | tee -a etc_listing.txt

# Capture errors too
find / -name "hosts" 2>&1 | tee full_search.txt

# Log a command while watching it live
sudo apt update 2>&1 | tee apt_update_$(date +%Y%m%d).log
```

> 💡 `tee` is invaluable during maintenance. Run a command, watch it live, AND have a log file for later debugging.

---



---

[← Previous](08-section-1-redirecting-stderr-the.md) | [↑ Index](index.md) | [Next →](10-section-3-named-pipes-fifos.md)
