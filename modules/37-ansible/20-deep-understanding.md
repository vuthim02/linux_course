## 🧠 Deep Understanding

### How Ansible Works Internally

#### SSH Connection Flow

```
1.  Control Node opens SSH connection to Managed Node
2.  Creates temporary directory: /tmp/ansible-tmp-<random>/
3.  Writes module arguments as JSON to temp dir
4.  Transfers module Python file to temp dir
5.  Executes module via SSH:
       /usr/bin/python3 /tmp/ansible-tmp-*/AnsiballZ_module.py
6.  Module runs, connects to system APIs (apt, systemd, etc.)
7.  Module outputs JSON result to stdout
8.  Control Node captures stdout, closes SSH connection
9.  Control Node cleans up temp directory
10. Displays result to user
```

#### Idempotency Design

Each module follows a **state-check → state-change** pattern:

```
┌─────────────┐
│  Read       │  ← Query current state (is package installed?)
│  Current    │
│  State      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Compare    │  ← Does current match desired?
│  with       │     (state: present, port: 80, etc.)
│  Desired    │
└──────┬──────┘
       │
       ├── Match ──→ Return {"changed": false}
       │
       └── No match ──→ Apply change ──→ Return {"changed": true}
```

#### Fact Caching

By default, facts are gathered at the start of every playbook run. For large environments, enable fact caching:

```ini
# ansible.cfg
[defaults]
gathering = smart
fact_caching = redis
fact_caching_timeout = 86400
fact_caching_connection = localhost:6379:0
```

```bash
# Or use JSON file caching
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
```

#### Async and Polling

For long-running tasks (30+ seconds), use async mode:

```yaml
- name: Long running task
  ansible.builtin.shell: /opt/long_task.sh
  async: 7200           # max runtime: 2 hours
  poll: 30              # check every 30 seconds (0 = fire and forget)

- name: Fire and forget
  ansible.builtin.shell: /opt/background_job.sh
  async: 3600
  poll: 0               # don't wait for completion
```

Retrieve results later:

```yaml
- name: Check async job
  ansible.builtin.async_status:
    jid: "{{ background_result.ansible_job_id }}"
  register: job_status
  until: job_status.finished
  retries: 60
  delay: 10
```

#### Connection Plugins

| Plugin | Use Case | Example |
|--------|----------|---------|
| `local` | Run on control node | `connection: local` |
| `ssh` | Default SSH connection | `ansible_user=admin` |
| `docker` | Manage Docker containers | `connection: docker` |
| `winrm` | Manage Windows hosts | `ansible_connection: winrm` |
| `podman` | Manage Podman containers | `connection: podman` |

### Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│                    CONTROL NODE                          │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │ Inventory │  │ Playbook │  │ ansible-playbook CLI │  │
│  └─────┬────┘  └────┬─────┘  └──────────┬───────────┘  │
│        │            │                   │              │
│        ▼            ▼                   ▼              │
│  ┌───────────────────────────────────────────────┐     │
│  │           Ansible Engine (Python)              │     │
│  │  • Parse inventory                             │     │
│  │  • Compile playbook into tasks                 │     │
│  │  • Resolve variables / facts                   │     │
│  │  • Determine task order & dependencies         │     │
│  └────────────────────┬──────────────────────────┘     │
│                       │                                │
│                       ▼                                │
│  ┌───────────────────────────────────────────────┐     │
│  │           SSH / Connection Layer               │     │
│  │  • Open connection                            │     │
│  │  • Push module + arguments                    │     │
│  │  • Execute Python module                      │     │
│  │  • Collect JSON result                        │     │
│  │  • Close connection                           │     │
│  └───────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────┘
```





[← Previous](19-section-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](21-command-reference.md)
