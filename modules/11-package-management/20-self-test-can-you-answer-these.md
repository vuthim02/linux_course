## 📝 Self-Test — Can You Answer These?

1. What are the two major Linux packaging systems?
2. What is the difference between `apt install` and `dpkg -i`?
3. What does `sudo apt update` do and why must you run it before install?
4. What is the difference between `apt remove` and `apt purge`?
5. What does `sudo apt autoremove` do?
6. How do you find which package installed a specific file?
7. What is a PPA and how do you add one?
8. What is the difference between snap and flatpak?
9. How do you prevent a package from being updated?
10. What does `rpm -ql nginx` show?
11. How do you clean the apt package cache?
12. What is EPEL and when would you use it?
13. How do you simulate an installation to see what would happen?
14. What is the difference between .deb and .rpm?
15. How does a package manager verify package integrity?

**Score:** 12/15 correct = ready for Part 12.


## Answer Key

### Q1: What are the two major Linux packaging systems?
**Answer:** DEB (Debian/Ubuntu, managed by dpkg/apt) and RPM (Red Hat/Fedora/CentOS, managed by rpm/dnf/yum).

### Q2: What is the difference between `apt install` and `dpkg -i`?
**Answer:** `apt install` resolves dependencies automatically. `dpkg -i` installs a single .deb but doesn't handle missing dependencies.

### Q3: What does `sudo apt update` do and why must you run it before install?
**Answer:** Downloads the latest package index files from repositories. You must run it first because the local index may be outdated.

### Q4: What is the difference between `apt remove` and `apt purge`?
**Answer:** `remove` deletes the package but keeps config files. `purge` deletes both the package and its config files.

### Q5: What does `sudo apt autoremove` do?
**Answer:** Removes packages that were installed as dependencies but are no longer needed.

### Q6: How do you find which package installed a specific file?
**Answer:** `dpkg -S /path/to/file` (DEB) or `rpm -qf /path/to/file` (RPM).

### Q7: What is a PPA and how do you add one?
**Answer:** PPA (Personal Package Archive) is a third-party repository for Ubuntu. Add with `sudo add-apt-repository ppa:user/repo`.

### Q8: What is the difference between snap and flatpak?
**Answer:** Both are universal package formats. Snap is Canonical-centric (daemon-based, auto-updates). Flatpak is community-driven (sandboxed with Flatpak portals).

### Q9: How do you prevent a package from being updated?
**Answer:** `sudo apt-mark hold package` to pin. `sudo apt-mark unhold package` to release.

### Q10: What does `rpm -ql nginx` show?
**Answer:** Lists all files installed by the nginx package.

### Q11: How do you clean the apt package cache?
**Answer:** `sudo apt clean` (removes all cached .deb files) or `sudo apt autoclean` (removes obsolete packages).

### Q12: What is EPEL and when would you use it?
**Answer:** Extra Packages for Enterprise Linux — a Fedora project providing additional packages for RHEL/CentOS. Use when the default repos lack needed software.

### Q13: How do you simulate an installation to see what would happen?
**Answer:** `apt install --dry-run package` or `apt-cache depends package`.

### Q14: What is the difference between .deb and .rpm?
**Answer:** .deb is the binary package format for Debian systems; .rpm is for Red Hat systems. They contain compiled software, metadata, and scripts.

### Q15: How does a package manager verify package integrity?
**Answer:** Uses GPG signatures — the repository signs packages with a key, and the package manager verifies the signature against trusted keys.


*Linux SysAdmin Course | Part 11 of ∞ | Reverse Engineering Approach*
*Previous → Part 10: The Linux Boot Process*
*Next → Part 12: Systemd and Services — Managing the Modern Linux*




[← Previous](19-whats-coming-in-part-12.md) | [↑ Index](index.md)
