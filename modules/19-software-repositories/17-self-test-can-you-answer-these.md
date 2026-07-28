## 📝 Self-Test — Can You Answer These?

1. What is a Linux software repository?
2. What are the four Ubuntu repository components?
3. What is a PPA and how do you add one?
4. What is EPEL and why is it important for RHEL-based systems?
5. What does `sudo apt update` actually do (what is downloaded)?
6. What is the difference between `deb` and `deb-src` in sources.list?
7. How do modern APT configurations use GPG keys?
8. Name three third-party repositories and what they provide.
9. How do you list enabled repositories on Fedora/RHEL?
10. What is the `signed-by` option in sources.list?
11. How does a repository verify package authenticity?
12. What is a Release file and what does it contain?
13. How do you temporarily disable a repository?
14. What is RPM Fusion and what does it provide?
15. How do you find your distribution's codename?

**Score:** 12/15 correct = ready for Part 20.


## Answer Key

### Q1: What is a Linux software repository?
**Answer:** A storage location (server/CDN) hosting software packages and their metadata. Package managers download and install from these sources.

### Q2: What are the four Ubuntu repository components?
**Answer:** `main` (officially supported), `restricted` (proprietary drivers), `universe` (community-maintained), `multiverse` (non-free/universe-dependent).

### Q3: What is a PPA and how do you add one?
**Answer:** PPA (Personal Package Archive) is a third-party Ubuntu repo hosted on Launchpad. Add: `sudo add-apt-repository ppa:user/ppa-name`.

### Q4: What is EPEL and why is it important for RHEL-based systems?
**Answer:** Extra Packages for Enterprise Linux — provides additional packages not in RHEL base repos. Essential for many server tools.

### Q5: What does `sudo apt update` actually do?
**Answer:** Downloads `Packages.gz` index files from all configured repositories, updating the local package cache with available versions.

### Q6: What is the difference between `deb` and `deb-src`?
**Answer:** `deb` provides compiled binary packages. `deb-src` provides source packages for rebuilding/customizing.

### Q7: How do modern APT configurations use GPG keys?
**Answer:** Keys are stored in `/etc/apt/keyrings/` and referenced in `sources.list` with `signed-by=/etc/apt/keyrings/file.gpg` per-repository.

### Q8: Name three third-party repositories and what they provide.
**Answer:** Docker CE (container runtime), HashiCorp (Vault, Terraform), Google Chrome (browser), VS Code (editor).

### Q9: How do you list enabled repositories on Fedora/RHEL?
**Answer:** `dnf repolist` or `yum repolist` — shows all enabled repos and their URLs.

### Q10: What is the `signed-by` option in sources.list?
**Answer:** Specifies which GPG key file to use for verifying packages from that repository (per-repo key pinning).

### Q11: How does a repository verify package authenticity?
**Answer:** Packages are signed with the repository maintainer's GPG key. The package manager verifies the signature against trusted keys before installing.

### Q12: What is a Release file and what does it contain?
**Answer:** A signed file containing repository metadata: suite name, component, architecture, checksums of index files, and signature.

### Q13: How do you temporarily disable a repository?
**Answer:** `sudo apt --disable-repo=repo-name` (for one operation) or add `#` before the repo line in `sources.list`.

### Q14: What is RPM Fusion and what does it provide?
**Answer:** A community repo for Fedora/RHEL providing packages excluded due to legal/patent issues (codecs, drivers, ffmpeg).

### Q15: How do you find your distribution's codename?
**Answer:** `lsb_release -cs` — returns the codename (e.g., `jammy`, `noble`).


*Linux SysAdmin Course | Part 19 of ∞ | Reverse Engineering Approach*
*Previous → Part 18: Environment Variables and Shell Configuration*
*Next → Part 20: System Updates and Patch Management*

[← Previous](part18.md) | [Next →](part20.md)



[← Previous](16-whats-coming-in-part-20.md) | [↑ Index](index.md)
