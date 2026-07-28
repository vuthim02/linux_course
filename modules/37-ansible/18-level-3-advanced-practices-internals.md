## ⭐ Level 3: Advanced — Practices & Internals

![Advanced Ansible automation](https://docs.ansible.com/ansible/latest/_images/ansible_automatic_diagram.png)

> *"Practice transforms knowledge into instinct. These exercises build production-ready Ansible skills."*

### What You'll Cover
- 15 hands-on practices covering real-world automation scenarios
- Async tasks: `async`/`poll` for long-running operations
- Fact caching: `jsonfile`, `redis`, `memcached` backends
- Custom modules and plugins: when built-in modules aren't enough
- Ansible Vault advanced: password files, vault IDs, multi-vault encryption
- Performance: `pipelining`, `forks`, `mitogen`, SSH control persist
- Deep understanding: how Ansible executes tasks under the hood

At the advanced level, you understand Ansible's internals — how it executes tasks, where bottlenecks lie, and how to scale to hundreds or thousands of nodes.

At this level you will master:

- **Async tasks**: `async: 3600 poll: 0` launches a task and moves on. `async_status` module checks the result later. Essential for long-running tasks like OS upgrades or large package installations that would otherwise timeout.
- **Fact caching**: By default, Ansible gathers facts on every run. Cache them with `fact_caching: jsonfile` and `fact_caching_connection: /tmp/ansible_facts` for faster subsequent runs. Redis or memcached backends work for multi-control-node setups.
- **Performance tuning**: `pipelining = True` in `ansible.cfg` reduces SSH operations by half. `forks = 50` (default is 5) parallelizes across more hosts. `mitogen` is a third-party plugin that eliminates SSH overhead entirely. `ControlPersist` in SSH config maintains persistent connections.
- **Vault advanced**: `ansible-vault create --vault-id prod@prompt secrets.yml` uses vault IDs for multiple encryption passwords. `ansible-vault encrypt_string 'mysecret' --vault-id prod` encrypts inline strings for embedding in playbooks.
- **Execution model**: Ansible parses the playbook into a task queue, gathers facts if needed, connects via SSH, pushes module files to a temporary directory, executes them, and collects JSON results. Understanding this flow helps you debug connection and timeout issues.


[← Previous](17-section-14-error-handling.md) | [↑ Index](index.md) | [Next →](19-section-15-hands-on-practices.md)
