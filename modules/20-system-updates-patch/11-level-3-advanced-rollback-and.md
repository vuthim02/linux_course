## ⭐ Level 3: Advanced — Rollback and Internals

![Linux kernel map — understanding the deep internals of updates](https://upload.wikimedia.org/wikipedia/commons/1/1c/Linux_kernel_diagram.svg)

*Linux kernel architecture diagram — the foundation that updates modify (Kuzux / Wikimedia Commons / CC-BY-SA-2.5)*

> **Level 3 Goal:** Master rollback strategies for failed updates, understand APT and DNF transaction internals, and manage filesystem-level snapshots for recovery.

### What You'll Cover
- APT rollback: `apt-get install pkg=version` and dpkg snapshots
- DNF history: `dnf history undo` for transaction-level rollback
- Btrfs and LVM snapshots for filesystem-level recovery
- Library compatibility: handling soname changes and dependency breaks
- Testing updates in containers or VMs before production deployment

### Why This Level Matters

Updates break things. It is not a matter of if, but when. The sysadmin who can roll back a failed update in five minutes is worth ten times the one who reinstalls the server from scratch. Level 3 gives you that ability.

DNF's transaction history is particularly powerful. Every package operation is recorded with a transaction ID. If an update causes problems, `dnf history undo` reverts the entire transaction — packages, dependencies, and configuration files. This is surgical rollback, not guesswork.

Btrfs and LVM snapshots add another layer of safety. Before any update, you can snapshot the entire filesystem. If the update breaks something, you restore the snapshot in seconds. This is the nuclear option, but it works every time.

### What You'll Practice

- Using `dnf history list` and `dnf history undo` to revert broken updates
- Pinning package versions in APT to prevent unwanted upgrades
- Creating and restoring LVM snapshots before major updates
- Testing updates in containers to catch breakage before production

> ⚠️ LVM snapshots are temporary space-eaters. A snapshot grows as the original volume changes. Delete snapshots promptly after confirming the update is stable.





[← Previous](10-section-7-kernel-updates.md) | [↑ Index](index.md) | [Next →](12-section-8-rollback-strategies.md)
