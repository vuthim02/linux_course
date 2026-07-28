## 12. Comparative Analysis

| Dimension | Puppet | Salt | Chef | Ansible |
|-----------|--------|------|------|---------|
| Language | Ruby DSL → catalog JSON | YAML + Jinja | Ruby DSL | YAML |
| Architecture | Master/Agent | Master/Minion (or SSH) | Server/Client | Agentless (SSH) |
| Transport | HTTPS (REST) | ZeroMQ (pub/sub) | HTTPS (REST) | SSH |
| Push/Pull | Pull | Both (push default) | Pull | Push |
| Idempotency | Built-in (catalog) | Built-in (state) | Built-in (resource) | YAML modules |
| State storage | PuppetDB (Postgres) | Master memory + file | Chef Server (Solr+PG) | None (stateless) |
| Scale | 1K-10K+ nodes | 1K-10K+ nodes | 1K-5K nodes | 500-1K (SSH) |
| Learning curve | Medium (Ruby DSL) | Low (YAML+Jinja) | Medium-High (Ruby) | Low (YAML) |
| Windows | Good | Good | Excellent | Good |
| Container native | Poor | Fair | Poor | Excellent |
| Community | Large (Forge) | Medium | Large (Supermarket) | Largest (Galaxy) |
| Enterprise | Puppet Enterprise | SaltStack (VMware) | Chef (Progress) | Red Hat |
| Testing | rspec-puppet, beaker | testinfra | ChefSpec, test-kitchen | molecule |
| Secrets | hiera-eyaml | GPG renderer, vault | encrypted data bags | ansible-vault |

### When to Use Which

**Puppet**: Large standardized fleets (1K-10K+), heavy compliance (PCI-DSS, SOC2, HIPAA). Banks, government, large enterprises that need a single source of truth with strong data separation.

**Salt**: High-frequency operations, event-driven infrastructure at scale. SRE teams needing both config and orchestration in one tool. Hybrid push/pull environments.

**Chef**: Ruby-shop teams, DevOps-mature organizations with strong testing culture (ChefSpec + test-kitchen). Treating infrastructure as a "compiled" API.

**Ansible**: Simplest setup (no agents). Best for small-medium infrastructure, network automation, containerized envs, CI/CD tasks, teams new to CM.

### Strengths and Weaknesses

**Puppet**: ✅ Strong resource abstraction (providers for every OS), Hiera data separation is mature, Roles/Profiles forces clean architecture, PuppetDB queries. ❌ JRuby server complex to debug (memory, GC), slow run cycle (default 30 min), verbose DSL for simple tasks.

**Salt**: ✅ ZeroMQ fast (millisecond pub/sub), event-driven reactor unique, flexible targeting (grains, compound, glob), agentless mode. ❌ YAML+Jinja becomes unmanageable without discipline, master is SPOF (mitigated by multi-master), state ordering bugs in complex trees.

**Chef**: ✅ Ruby DSL expressive, Ohai richest introspection, Search API makes dynamic config natural, best testing story. ❌ Ruby requires real programming, Chef Server complex (Erlang/Solr), attribute precedence confusing, slower converge times.





[← Previous](11-11-chef-in-practice.md) | [↑ Index](index.md) | [Next →](13-13-modern-era.md)
