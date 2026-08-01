## Section 8: gVisor, Kata Containers, IMA/EVM

### gVisor — Userspace Kernel for Isolation

gVisor intercepts syscalls with a userspace kernel (Sentry) for container sandboxing.

```bash
# Use with Docker
docker run --runtime=runsc hello-world

# Use with containerd
# /etc/containerd/config.toml
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
#   runtime_type = "io.containerd.runsc.v1"

# gVisor components:
# Sentry  — userspace kernel (handles most syscalls)
# Gofer  — file proxy (reduces attack surface)
# Platform — KVM, ptrace, or SELinux for host bridging
```

### Kata Containers — Lightweight VMs

Kata runs each container in its own lightweight VM (using QEMU, Firecracker, or Cloud Hypervisor).

```bash
# Install Kata
sudo apt install kata-runtime kata-containers

# Use with Docker
docker run --runtime=kata-runtime -it alpine

# Use with Kubernetes (containerd)
# RuntimeClass: kata-qemu or kata-clh (Cloud Hypervisor)
```

### IMA/EVM — Integrity Measurement Architecture

```bash
# Kernel config required
# CONFIG_IMA=y, CONFIG_EVM=y
# Boot params: ima_appraise=fix ima_template_fmt=ima-ng

# Measure files
ima_hash /bin/bash              # Show hash
getfattr -d -m - /etc/shadow    # Show security.ima xattr

# Policy: /etc/ima/ima-policy
# appraise func=BPRM_CHECK fowner=0 appraise_type=imasig

# EVM protects extended attributes (security.evm)
# Protects against offline attribute tampering
```

| Feature | gVisor | Kata | IMA/EVM |
|---------|--------|------|---------|
| Model | Userspace kernel | Lightweight VM | Kernel integrity |
| Attack surface | ~250 syscalls | Full VM + HW | Filesystem metadata |
| Performance | ~80–90% native | ~85–95% native | Minimal overhead |
| Best for | Multi-tenant containers | Strong isolation | Compliance (FIPS, PCI) |
