## 1. Immutable Infrastructure Philosophy

### Mutable vs Immutable

In **mutable infrastructure** (pet model), you provision a server once and then SSH into it to apply updates, patch packages, modify configs, and fix issues. Over time, every server becomes a unique snowflake — nobody knows exactly what's installed, which configs were changed manually, or whether a reboot will break things.

| Aspect | Mutable (Pets) | Immutable (Cattle) |
|--------|---------------|-------------------|
| Updates | SSH in, apt upgrade, restart service | Build new image, replace instance |
| Config changes | Edit files by hand or config mgmt | Change template, rebuild image |
| State | Drift accumulates | Every instance is identical |
| Failure | Try to fix in place | Terminate and replace |
| SSH | Required for daily ops | Blocked / not needed |
| Rollback | Difficult (unwind changes) | Trivial (deploy old image) |

### Golden Images

A **golden image** is a pre-baked machine image containing the OS, security patches, middleware, application dependencies, and hardened configuration. Every instance launched from this image is bit-for-bit identical. There is zero configuration drift.

**Bake vs Fry:**
- **Bake**: Everything is baked into the image at build time. No post-boot configuration needed (except perhaps minimal userdata for environment-specific values).
- **Fry**: Minimal base image, heavy reliance on post-boot userdata scripts or configuration management at first boot.

Immutable infrastructure strongly prefers **baking**.

### No SSH into Production

The rule is simple: you do not SSH into production servers. There is no SSH daemon listening (or it's firewalled), no SSH keys are deployed, and no user accounts exist. If you need to debug, you launch a separate instance from the same image in a sandbox, or use dedicated debugging tools (SSM Session Manager, serial console, log aggregation).

### Replacing Instances Instead of Patching

When a security patch needs to be applied:
1. Build a new image with the patch baked in
2. Deploy new instances from the new image
3. Terminate old instances

This is safer than patching in place because:
- The build process is automated and repeatable
- The new image is tested before deployment
- Rollback means deploying the previous image version
- No partial failures or half-patched servers





[↑ Index](index.md) | [Next →](02-2-packer-overview.md)
