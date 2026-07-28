## ⭐ Level 1: Basic — Package Management Fundamentals

![Linux software stack that updates affect at every layer](https://upload.wikimedia.org/wikipedia/commons/3/30/IO_stack_of_the_Linux_kernel.svg)

*Linux software stack showing the layers that updates touch (Fischer & Schönberger / Wikimedia Commons / CC-BY-SA-4.0)*

> **Level 1 Goal:** Understand where updates come from, how to check for them, how to apply them safely, and how to choose between LTS and rolling release distributions.

### What You'll Cover
- Where updates come from: upstream projects, distro maintainers, security teams
- Security updates vs feature updates: why the distinction matters
- Checking for available updates: `apt list --upgradable`, `dnf check-update`
- Applying updates safely: `apt upgrade`, `dnf update`
- LTS vs rolling release: stability trade-offs

### Key Concepts to Remember

**Updates are not all the same.** A security patch fixes a vulnerability that attackers can exploit. A feature update adds new functionality. A bug fix corrects broken behavior. Knowing which is which determines whether you apply an update at 2 AM or schedule it for next month.

**Package managers are your single source of truth.** Never download and install software from a random website. Use your distro's package manager. It tracks dependencies, handles upgrades, and knows what is installed on your system. Fighting the package manager creates problems that compound over time.

**LTS means Long Term Support.** Ubuntu LTS releases get five years of security updates. They sacrifice cutting-edge features for stability. Rolling releases like Arch give you the latest software constantly but require more attention. Choose based on your tolerance for change and your need for stability.

> ⚠️ Never run `apt upgrade` or `dnf update` on a production server without first checking what will change. Review the package list, check release notes, and ideally test on a staging system.



[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-the-update-lifecycle.md)
