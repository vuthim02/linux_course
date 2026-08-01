## Section 7: TOMOYO, Smack, and Other LSMs

Linux Security Modules (LSMs) framework supports multiple access control models beyond SELinux and AppArmor.

### TOMOYO Linux

- **Pathname-based** MAC: uses process execution history to define security policies
- **Learning mode**: automatically generates policies from observed behavior
- **Use case**: embedded systems, desktops where SELinux complexity is unwanted

```bash
# Ubuntu
sudo apt install tomoyo-tools
# Enable: add lsm=...,tomoyo,... to kernel cmdline (lsm= kernel parameter)
# Or use: security=tomoyo (legacy, older kernels)
sudo tomoyo-init
sudo tomoyo-loadpolicy < policy.conf
```

### Smack (Simplified Mandatory Access Control Kernel)

- **Label-based** MAC: assigns labels (strings) to objects and subjects
- **Used by**: Tizen, embedded Linux, some medical devices
- **Lighter weight** than SELinux

```bash
# Check if Smack is active
cat /sys/kernel/security/lsm
# Smack labels
ls -Z /tmp          # Show Smack labels
chsmack -a Label file  # Set Smack label
```

### Choosing an LSM

| LSM | Complexity | Policy Language | Best For |
|-----|-----------|-----------------|----------|
| SELinux | High | Type Enforcement | RHEL/CentOS, multi-service servers |
| AppArmor | Medium | Profile-based | Ubuntu, easy app profiling |
| TOMOYO | Medium | Path-based | Learning mode auto-policy |
| Smack | Low | Label-based | Embedded, simplicity |
