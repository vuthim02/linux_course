## 🔍 Section 1: What Is Ansible?

### The Problem Ansible Solves

Imagine you have 50 servers:
- Install Nginx on all of them
- Ensure the `nginx.conf` is identical
- Restart the service if config changes
- Create user `deploy` with a specific SSH key on every server

Without automation: SSH into each one, type the same commands 50 times, pray you didn't miss one. With Ansible: one command, all 50 servers converge to the exact same state.

### Key Concepts

| Concept | Meaning |
|---------|---------|
| **Agentless** | No software installed on managed nodes — Ansible uses SSH only |
| **Push-based** | Control node pushes config to managed nodes (vs pull-based like Puppet) |
| **SSH** | Transport protocol — Ansible connects over SSH (default) |
| **YAML** | Playbooks and inventory are written in YAML Ain't Markup Language |
| **Idempotency** | Running the same playbook multiple times produces the same result — it won't break anything if already applied |
| **Inventory** | List of hosts Ansible manages |
| **Modules** | Reusable units of work (install package, copy file, start service) |
| **Playbooks** | YAML files that define automation workflows |

### How Ansible Works Internally (Reverse Engineering)

```
┌─────────────────────┐         SSH          ┌─────────────────────┐
│   Control Node      │ ──────────────────→  │   Managed Node 1    │
│   (where you run    │                      │   (target server)   │
│    ansible-playbook)│                      │                     │
│                     │                      │  /tmp/ansible-tmp/  │
│  1. Read playbook   │                      │  ┌───────────────┐  │
│  2. Gather facts?   │                      │  │ ansible_mod.py│  │
│  3. Push Python     │                      │  │ (module code) │  │
│     module to /tmp/ │                      │  └───────────────┘  │
│  4. Execute module  │                      │                     │
│  5. Collect results │                      │  Python executes    │
│  6. Remove module   │                      │  module, writes     │
│                     │                      │  result to stdout   │
└─────────────────────┘                      └─────────────────────┘
```

**Step by step:**
1. Ansible reads the inventory and playbook on the control node
2. Opens an SSH connection to each managed host
3. Copies the Python module code (generated from the YAML task) to `/tmp/ansible-tmp-*` on the target
4. Executes the module via SSH with JSON arguments
5. The module runs, checks current state vs desired state, makes changes if needed
6. Results (JSON) are written to stdout, Ansible collects and displays them
7. Module files are cleaned up — no persistent agent remains

### Idempotency Design

Every Ansible module is built with idempotency in mind:

```python
# Pseudocode of how a module thinks:
def ensure_package_installed(name="nginx", state="present"):
    if package_is_installed(name):
        return {"changed": False, "msg": "already installed"}
    else:
        install_package(name)
        return {"changed": True, "msg": "package installed"}
```

Running it once installs Nginx. Running it again does nothing — the state already matches.

---



---

[← Previous](02-level-1-basic-foundations.md) | [↑ Index](index.md) | [Next →](04-section-2-installation.md)
