## 🔍 Section 1: Reverse Engineering the File System — It's Just a Tree

In Part 1, you saw the Linux file system starts from `/`. Let's reverse-engineer why.

### Why does Linux use a single tree?

On Windows, you have `C:\`, `D:\`, `E:\` — every drive is separate.

On Linux, everything is merged into **one tree**:

```
/
├── home/
├── etc/
├── var/
└── mnt/
    └── usb/          ← Your USB drive appears HERE inside the tree
```

When you plug in a USB drive, Linux **mounts** it into the tree at a location like `/mnt/usb` or `/media/username/USB`. The tree grows — you don't get a new `D:\`.

> 💡 **Reverse Engineering Insight:** This design means you can move an entire folder to a different physical disk by just remounting it somewhere else in the tree — without changing any paths your programs use. This is how Linux servers separate `/home`, `/var`, `/tmp` onto different disks for performance and safety.

---



---

[← Previous](02-level-1-basic-navigation-file.md) | [↑ Index](index.md) | [Next →](04-section-2-paths-the-address.md)
