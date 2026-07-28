## 2. Puppet Architecture

### Core Components

```
                    ┌──────────────────────┐
                    │  Puppet Server (JRuby)│
                    │  Port 8140 HTTPS     │
                    └──────┬───────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐ ┌────▼────┐  ┌──────▼─────┐
     │ Puppet Agent│ │PuppetDB │  │  r10k      │
     │ (Ruby,      │ │(Postgres│  │ (Git env   │
     │  systemd)   │ │ +Solr) │  │  builder)  │
     └─────────────┘ └─────────┘  └────────────┘
```

1. **Puppet Server**: JVM-based, port 8140 HTTPS. Compiles **catalogs** for each agent. Certificate-based auth.
2. **PuppetDB**: Stores facts, catalogs, reports. PostgreSQL. Queryable via PQL. Used for exported resources.
3. **Puppet Agents**: Ruby daemon. Runs as `puppet.service`. Submits facts, receives catalog, applies it, reports.
4. **r10k**: Git-based environment deployment. Reads `Puppetfile`, deploys modules per environment.
5. **Puppetfile**: Lists modules with versions (like Gemfile for Puppet).

### Certificate Signing

```
Agent → CSR → Puppet Server → autosign or pending → puppetserver ca sign --certname <name>
```

### Environments and Modulepath

```
/etc/puppetlabs/code/environments/
├── production/manifests/site.pp
├── production/modules/{nginx,stdlib,...}
├── production/Puppetfile
├── development/...
└── testing/...
```

Each environment has its own `modulepath` — different module versions per env. r10k builds environments from Git branches.





[← Previous](01-1-configuration-management-paradigms.md) | [↑ Index](index.md) | [Next →](03-3-puppet-dsl.md)
