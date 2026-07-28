## 📝 Self-Test — Can You Answer These?

1. What is a kernel module and why is it used instead of building everything into the kernel?
2. How do you list all currently loaded kernel modules?
3. What does `modinfo` show about a module?
4. What is the difference between `modprobe` and `insmod`?
5. How do you unload a kernel module?
6. What does `depmod -a` do and when should you run it?
7. How do you pass parameters to a kernel module?
8. What is module blacklisting and how do you do it?
9. How do you check which kernel module is driving a PCI device?
10. What is udev and what does it do?
11. What does `vermagic` mean in a kernel module?
12. How do you build a custom kernel module?
13. What does `module_init()` and `module_exit()` do?
14. What happens when a module dependency is missing?
15. How do you troubleshoot a device that isn't working?

**Score:** 12/15 correct = congratulations, you've mastered Part 24!


## Answer Key

### Q1: What is a kernel module and why is it used instead of building everything into the kernel?
**Answer:** A loadable kernel module (LKM) extends the kernel at runtime without rebooting. Allows modular driver loading, smaller kernel image, and easier updates.

### Q2: How do you list all currently loaded kernel modules?
**Answer:** `lsmod` — shows all loaded modules and their dependency chains.

### Q3: What does `modinfo` show about a module?
**Answer:** Module metadata: author, license, description, parameters, dependencies, vermagic, and file path.

### Q4: What is the difference between `modprobe` and `insmod`?
**Answer:** `insmod` loads a module directly (no dependency resolution). `modprobe` loads a module and automatically loads its dependencies.

### Q5: How do you unload a kernel module?
**Answer:** `rmmod module_name` (if not in use) or `modprobe -r module_name` (removes with dependencies).

### Q6: What does `depmod -a` do and when should you run it?
**Answer:** Rebuilds the module dependency map in `/lib/modules/$(uname -r)/`. Run after installing new modules.

### Q7: How do you pass parameters to a kernel module?
**Answer:** At load time: `modprobe module param=value`. Persistently: add to `/etc/modprobe.d/custom.conf`.

### Q8: What is module blacklisting and how do you do it?
**Answer:** Preventing a module from loading. Create `/etc/modprobe.d/blacklist.conf` with `blacklist module_name`.

### Q9: How do you check which kernel module is driving a PCI device?
**Answer:** `lspci -k` — shows kernel drivers and modules in use for each PCI device.

### Q10: What is udev and what does it do?
**Answer:** udev is the device manager that dynamically creates/removes device nodes in `/dev/` and manages device events via rules.

### Q11: What does `vermagic` mean in a kernel module?
**Answer:** A string encoding the kernel version, compiler, and SMP config. A module only loads if vermagic matches the running kernel exactly.

### Q12: How do you build a custom kernel module?
**Answer:** Write the `.c` source, create a `Makefile` with `obj-m := module.o`, run `make -C /lib/modules/$(uname -r)/build M=$(pwd) modules`.

### Q13: What does `module_init()` and `module_exit()` do?
**Answer:** Register the entry point (called when module loads) and exit point (called when module unloads).

### Q14: What happens when a module dependency is missing?
**Answer:** `modprobe` fails with "Unknown symbol" or "Required key not available" errors.

### Q15: How do you troubleshoot a device that isn't working?
**Answer:** Check `dmesg` for errors, verify the module is loaded (`lsmod`), check `lspci -k` for driver binding, verify device permissions.


*Linux SysAdmin Course | Part 24 of ∞ | Reverse Engineering Approach*
*Previous → Part 23: Virtual Terminals and Console Management*


[← Previous](part23.md)



[← Previous](15-whats-next.md) | [↑ Index](index.md)
