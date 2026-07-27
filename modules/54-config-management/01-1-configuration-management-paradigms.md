## 1. Configuration Management Paradigms

### Declarative vs Procedural

| Aspect | Declarative | Procedural |
|--------|------------|------------|
| What you write | Desired end state | Step-by-step instructions |
| How it runs | Tool decides order | You control order |
| Idempotency | Inherent | Must be coded manually |
| Examples | Puppet, Salt states, Chef, Terraform | Shell scripts, Ansible playbooks (mostly) |

Declarative: `package { 'nginx': ensure => installed }` — say *what*, not *how*.
Procedural: `apt-get install -y nginx` — say *how*, step by step.

### Master/Agent vs Agentless vs Solo

| Model | Description | Tools |
|-------|-------------|-------|
| Master/Agent | Central server + client daemon | Puppet, Salt (minion), Chef |
| Agentless | Push via SSH, no agent | Ansible, Salt SSH |
| Solo/Local | No server, apply locally | `puppet apply`, chef-zero |

### Pull vs Push

- **Pull**: Agents periodically connect to master, fetch catalog, apply. Scales to thousands. Default for Puppet and Chef.
- **Push**: Master pushes commands. Salt supports both — push via ZeroMQ or pull via scheduled states.
- **Hybrid**: Salt master sends "run now" signal, minion pulls state and applies.

### Idempotency

Operation is **idempotent** if applying it N times produces the same result as one application. `ensure => installed` checks `dpkg -l` / `rpm -q` before installing. `file` resource checks content checksum. If already correct, skip.

### Resource Abstraction Layer

Each tool wraps OS-native operations behind a **resource/provider** abstraction:

```puppet
package { 'nginx': ensure => installed }
```

On Ubuntu: `apt-get install nginx`. On RHEL: `yum install nginx`. On FreeBSD: `pkg install nginx`. The provider handles platform details. The resource declaration is identical.

---



---

[↑ Index](index.md) | [Next →](02-2-puppet-architecture.md)
