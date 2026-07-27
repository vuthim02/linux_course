## 🔍 Section 4: Hidden Files — Linux's Secret System

In Linux, any file or folder whose name starts with a **dot (.)** is hidden.

```bash
ls ~            # Shows only visible files
ls -a ~         # Shows ALL files including hidden
```

Example output of `ls -a ~`:
```
.  ..  .bash_history  .bash_logout  .bashrc  .profile  Documents  Downloads
```

### Why Do Hidden Files Exist?

Hidden files store **configuration** for programs. Each program you install puts its settings in your home directory as a hidden file or folder.

```
~/.bashrc           ← Bash shell configuration
~/.bash_history     ← Every command you've ever typed
~/.ssh/             ← SSH keys and config (VERY important for sysadmins)
~/.profile          ← Login settings
~/.config/          ← Modern apps store config here
~/.vimrc            ← Vim editor settings (Part 4)
```

> 🔍 **Reverse Engineering Insight:** When something behaves unexpectedly, a sysadmin's first instinct is to check these hidden config files. If `bash` is acting strange, check `~/.bashrc`. If SSH won't connect, check `~/.ssh/config`.

---



---

[← Previous](05-section-3-the-ls-command.md) | [↑ Index](index.md) | [Next →](07-section-5-creating-directories-and.md)
