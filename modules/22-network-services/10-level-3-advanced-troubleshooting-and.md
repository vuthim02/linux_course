## ⭐ Level 3: Advanced — Troubleshooting and Internals

![TCP/IP model and protocol layers](https://upload.wikimedia.org/wikipedia/commons/c/c4/OSI_Model_v1.svg)

*OSI model — network communication layers (Wikimedia Commons / public domain)*

> **Level 3 Goal:** Diagnose and resolve complex service failures, understand service internals, and develop systematic troubleshooting approaches.

### What You'll Cover
- Systematic troubleshooting methodology for failed services
- Reading and interpreting `systemctl status` output
- Using `journalctl` with time ranges and priority filters
- Checking port bindings and socket activation issues
- Understanding the OSI model in the context of service debugging

### Why This Level Matters

When a network service fails in production, you do not have time to guess. You need a systematic approach that narrows down the problem fast. Level 3 gives you that approach: check the process, check the logs, check the ports, check the network. Each step eliminates a category of problems.

The OSI model is not just exam material. It is a debugging framework. When a web server is not responding, you work from the bottom up: Is the network interface up (Layer 1)? Is there an IP address (Layer 3)? Is the port open (Layer 4)? Is the HTTP response correct (Layer 7)? This layered approach prevents you from chasing ghosts.

### What You'll Practice

- Using `systemctl status` to read exit codes and failure reasons
- Filtering `journalctl` by time range and priority to find the exact failure point
- Checking port bindings with `ss -tlnp` and `lsof -i :PORT`
- Walking through the OSI model to diagnose a simulated service failure
- Interpreting `journalctl -u SERVICE --since "1 hour ago"` for targeted log analysis

> 💡 When a service fails, the first question is always: "Did it start and then crash, or did it never start?" `systemctl status` answers this in two seconds. Make it your first stop.





[← Previous](09-section-6-monitoring-network-services.md) | [↑ Index](index.md) | [Next →](11-section-7-troubleshooting-network-services.md)
