## ⭐ Level 1: Basic — Foundations

![Ansible control node to managed nodes](https://docs.ansible.com/projects/sdk/en/latest/_images/sdk-local-executor.svg)

> *"Automation is not about replacing humans — it's about freeing them from repetitive tasks so they can solve harder problems."*

### What You'll Cover
- What Ansible is: agentless, push-based, Python over SSH
- Installation: `pip install ansible`, package managers
- Inventory: static INI/YAML, dynamic inventory scripts
- Ad-hoc commands: `ansible all -m ping`, `ansible webservers -m yum`
- Playbooks: YAML structure, tasks, handlers, hosts, roles
- Checking mode (`--check`) and diff mode (`--diff`)

Ansible is an automation platform that pushes configuration to managed nodes over SSH. No agent to install, no daemon to manage — just SSH and Python.

At this level you will learn:

- **Architecture**: Ansible runs on a control node and connects to managed nodes via SSH. It pushes modules (small Python scripts) to each node, executes them, and returns results. No persistent connection or agent is required on the target.
- **Inventory**: INI format: `[webservers]\nweb1.example.com\nweb2.example.com`. YAML format: `all:\n  children:\n    webservers:\n      hosts:\n        web1.example.com`. Dynamic inventory scripts query external sources (AWS, GCP, CMDB) for host lists.
- **Ad-hoc commands**: `ansible all -m ping` tests connectivity. `ansible webservers -m yum -a "name=nginx state=present"` installs nginx. `ansible all -m command -a "uptime"` runs a command. Quick one-off tasks without writing a playbook.
- **Playbooks**: YAML files with `hosts`, `tasks`, `handlers`, and `vars`. `ansible-playbook site.yml` executes a playbook. Tasks are ordered; handlers run only when notified. `become: yes` enables privilege escalation.
- **Idempotency**: Ansible is designed so running the same playbook twice produces the same result. This is achieved through module design — `yum` checks if a package is already installed before trying to install it.


[← Previous](01-what-you-will-achieve.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-ansible.md)
