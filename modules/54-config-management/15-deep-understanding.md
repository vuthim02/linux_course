## Deep Understanding

### How Puppet Compiles Catalogs

```
Facts → Puppet Server (HTTPS POST /puppet/v3/catalog)
  → site.pp node matching → Parser (Lexer → AST)
  → Evaluator (conditionals, loops, Hiera lookups)
  → Dependency resolver (require/before/notify/subscribe)
  → Compiler → Catalog (JSON DAG of resources + edges)
  → Signed with server cert → Agent
  → Walks DAG, per resource: provider checks state vs catalog
  → Out of sync → converge; in sync → skip → Report → PuppetDB
```

### How Salt's Event-Driven System Works

```
ZeroMQ PUB (4505): Master → All minions (job announcements)
ZeroMQ REQ/REP (4506): Master ↔ Minion (job results)
Event Bus (IPC): Every component publishes events → Reactor matches tags → SLS actions

Example: Minion detects disk >90% (beacon)
  → Publishes salt/beacon/diskusage/web01 event
  → Reactor matches pattern (salt/beacon/diskusage/*)
  → Runs reactor SLS: alert PagerDuty, migrate data
```

```python
# Any process can subscribe to event bus
import salt.config, salt.utils.event
opts = salt.config.client_config('/etc/salt/master')
event = salt.utils.event.get_event('master', opts, listen=True)
for e in event.iter_events():
    print(e['tag'], e['data'])
```

### How Chef's Search API Works

```
Recipe calls search(:node, 'role:web_server')
  → Chef Client → HTTPS GET /search/node?q=role:web_server
  → Chef Server → Queries Solr/Elasticsearch index
  → Index updated after every chef-client run (node object stored)
  → Returns array of partial node objects

Search syntax:
  search(:node, 'platform:ubuntu AND chef_environment:production')
  search(:node, 'fqdn:*.example.com')
  search(:node, 'role:web_server', filter_result: { 'ip' => ['ipaddress'] })
  search(:users, 'groups:admin')     # data bag search
```

### Resource Abstraction Layer

| Resource | Provider | OS Command |
|----------|----------|------------|
| Puppet `package` | `apt` provider | `apt-get install` |
| Puppet `package` | `yum` provider | `yum install` |
| Salt `pkg.installed` | `aptpkg` | `apt-get install` |
| Salt `pkg.installed` | `yumpkg` | `yum install` |
| Chef `package` | `apt` provider | `apt-get install` |
| Chef `service` | `systemd` provider | `systemctl start` |

Providers selected via `defaultfor :operatingsystem => :ubuntu` (Puppet), grains `os_family` (Salt), `provides :service, platform_family: 'debian'` (Chef).

### Convergence and Idempotency

**Puppet**: Each resource defines `insync?`. `file` checks stat (owner/group/mode/checksum). `package` checks `dpkg -l` / `rpm -q`. `service` checks `systemctl is-active`. If `insync?` → skip. `--noop` for dry-run.

**Salt**: State modules have `_check` (validate) and `_mod` (converge) methods. `pkg.installed`: checks pkg database, skips if version matches. `test=True` for dry-run.

**Chef**: `load_current_resource` loads state → compares with desired. `converge_by` blocks for idempotency. `--why-run` for dry-run.





[← Previous](14-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](16-command-reference.md)
