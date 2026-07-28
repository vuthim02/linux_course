## ⭐ Level 2: Intermediary — Automation and Strategy

![Simplified Linux kernel structure — update automation affects every subsystem](https://upload.wikimedia.org/wikipedia/commons/2/26/Simplified_Structure_of_the_Linux_Kernel.svg)

*Simplified Linux kernel structure showing subsystems affected by automated updates (ScotXW / Wikimedia Commons / CC-BY-SA-4.0)*

> **Level 2 Goal:** Configure unattended-upgrades for automatic security patching, implement production update strategies, and manage kernel updates safely.

### What You'll Cover
- Configuring `unattended-upgrades` for Debian/Ubuntu
- Setting up automatic security updates with `dnf-automatic` on RHEL
- Production update strategies: staging, testing, rollout windows
- Kernel updates: when to reboot and how to plan downtime
- Monitoring update status across multiple servers

### Why This Level Matters

Manual updates do not scale. If you manage three servers, you might remember to update them weekly. If you manage thirty, you will miss one, and that one will be the one that gets compromised. Automation is not laziness — it is reliability.

Production update strategy is where theory meets reality. You need a staging environment that mirrors production, a testing process that catches breakage, and a rollout window that minimizes downtime. Getting this wrong means outages. Getting it right means sleep.

### What You'll Practice

- Writing an `unattended-upgrades` config that only applies security updates
- Setting up `dnf-automatic` with email notifications for RHEL systems
- Creating a staging-to-production rollout checklist
- Planning kernel reboots with `needs-restarting` and live patching

> 💡 Start with automatic security updates on non-critical systems first. Build confidence in the process before applying it to production databases.





[← Previous](06-section-5-lts-vs-rolling.md) | [↑ Index](index.md) | [Next →](08-section-4-unattended-upgrades.md)
