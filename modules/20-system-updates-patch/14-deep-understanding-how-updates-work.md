## 🧠 Deep Understanding — How Updates Work

### The APT Transaction

```
apt upgrade (or apt-get upgrade):
1. Reads /var/lib/dpkg/status (installed packages database)
2. Downloads new Packages.gz from repositories
3. Compares versions
4. Builds list of packages to upgrade
5. Calculates dependency changes
6. Downloads .deb files to /var/cache/apt/archives/
7. Verifies checksums and GPG signatures
8. Runs dpkg on each .deb in dependency order
9. Runs post-installation scripts
10. Updates /var/lib/dpkg/status
```

### Why Reboot After Kernel Update?

```
Old kernel loaded in memory:
  ┌────────────────────┐
  │ Running kernel 6.1 │  ← Active, can't be replaced while running
  └────────────────────┘

New kernel installed to disk:
  /boot/vmlinuz-6.2     ← Available on disk

GRUB configured to boot new kernel:
  /boot/grub/grub.cfg  ← Updated to include both kernels

On reboot:
  GRUB menu → select kernel 6.2 → loads new kernel
  Old kernel still available as fallback
```

### Library Compatibility

```
APR (Application Binary Interface):
When a shared library (libssl.so.3) is updated:
- Old programs linked against libssl.so.1.1 continue to work
- New programs use the new library

SONAME (Shared Object Name):
libssl.so.3  (major version 3)
libssl.so.1.1  (major version 1.1)

Breaking change: when major version changes (1.1 → 3)
  - Old programs may need recompilation
  - Both versions can be installed simultaneously
  - Each program uses the version it was linked against
```





[← Previous](13-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](15-summary-complete-command-reference-for.md)
