## 9. Chef Architecture

### Core Components

```
                    ┌─────────────────────────┐
                    │   Chef Infra Server      │
                    │  Erlang, Port 443 HTTPS  │
                    │  PostgreSQL + Solr/ES    │
                    └──────────┬──────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │   Chef Workstation      │
                    │  knife, berks, kitchen  │
                    └──────────┬──────────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
     ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
     │ chef-client │   │ chef-client │   │ chef-client │
     │ + Ohai      │   │ + Ohai      │   │ + Ohai      │
     └─────────────┘   └─────────────┘   └─────────────┘
```

1. **Chef Infra Server**: Erlang backend. Stores cookbooks, nodes, roles, environments, data bags. Search via Solr/Elasticsearch. PostgreSQL persistence.
2. **Chef Workstation**: Admin tools: `knife`, `berks`, `kitchen`, `chef-client`.
3. **Chef Infra Client**: Ruby agent. Runs Ohai for system profiling, then connects to Server, downloads run_list, compiles and applies resources.
4. **Ohai**: System profiling — platform, CPU, memory, network, filesystem → `node['...']`.
5. **Chef Supermarket**: `https://supermarket.chef.io` — community cookbooks.
6. **chef-zero**: In-memory Chef Server for testing. `chef-client --local-mode`.

### Bootstrap Flow

```bash
knife bootstrap 10.0.0.5 \
  --ssh-user ubuntu --sudo \
  --node-name web01 \
  --run-list 'role[web_server]'
# 1. SSH to node, 2. Install chef-client (omnibus), 3. Create /etc/chef/client.rb
# 4. Run chef-client: registers as web01, downloads run_list, runs Ohai, applies
```

---



---

[← Previous](08-8-saltstack-advanced.md) | [↑ Index](index.md) | [Next →](10-10-chef-dsl.md)
