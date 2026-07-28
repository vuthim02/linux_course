## 🔍 Section 3: Module Dependencies

### Module Dependency Tree

```bash
# Show dependencies of a module
modinfo ext4 | grep depends
# depends:        mbcache,jbd2

# Show entire dependency tree
modprobe --show-depends ext4

# Display dependency graph (human readable)
lsmod | grep ext4
```

### Module Loading Order

```
When you load a module, modprobe:
1. Checks if module exists
2. Checks dependencies
3. Loads dependencies in order (if not already loaded)
4. Loads the requested module

When you unload:
1. Checks if other modules depend on this one
2. If dependencies exist, refuses to unload
3. If no dependencies, unloads the module
4. Optionally unloads unused dependencies (-r flag)
```

### modules.dep

```bash
# The dependency database
cat /lib/modules/$(uname -r)/modules.dep | grep ext4

# Format: module.ko: dependency1.ko dependency2.ko
# Example:
# kernel/fs/ext4/ext4.ko: kernel/fs/mbcache/mbcache.ko kernel/fs/jbd2/jbd2.ko

# Rebuild dependency database
sudo depmod -a
```





[← Previous](05-section-2-loading-and-unloading.md) | [↑ Index](index.md) | [Next →](07-section-4-module-parameters.md)
