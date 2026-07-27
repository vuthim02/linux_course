## Command Reference

### Equivalent Concepts Across All Four Tools

| Concept | Puppet | Salt | Chef | Ansible |
|---------|--------|------|------|---------|
| Config file | `.pp` manifest | `.sls` state | `.rb` recipe | `.yml` playbook |
| Server | Puppet Server (JRuby) | Salt Master (Python) | Chef Server (Erlang) | None |
| Agent | `puppet agent` | `salt-minion` | `chef-client` | None (SSH) |
| System data | Facter → `$facts` | Grains → `grains` | Ohai → `node['...']` | `ansible_*` |
| Package | `package {'n': ensure}` | `pkg.installed` | `package 'n'` | `package:` |
| Service | `service {'n': ensure}` | `service.running` | `service 'n'` | `service:` |
| File | `file {'/p': content}` | `file.managed` | `file|template` | `copy|template` |
| User | `user {'n': ensure}` | `user.present` | `user 'n'` | `user:` |
| Execute | `exec {'c': command}` | `cmd.run` | `execute 'c'` | `command|shell` |
| Cron | `cron {'j': command}` | `cron.present` | `cron 'j'` | `cron:` |
| Dependencies | require/before/notify/subscribe | require/watch/onchanges | notifies/subscribes | when/notify |
| Dry run | `--noop` | `test=True` | `--why-run` | `--check` |
| Templates | ERB (`template()`), EPP (`epp()`) | Jinja | ERB | Jinja |
| Secrets | hiera-eyaml | GPG renderer, vault | encrypted data bags | ansible-vault |
| Module repo | Puppet Forge | SaltStack Formulas | Chef Supermarket | Ansible Galaxy |
| Dependency mgmt | Puppetfile + r10k | saltutil.sync_all + git | Berksfile + Berkshelf | requirements.yml |
| Testing | rspec-puppet, beaker | testinfra | ChefSpec, test-kitchen | molecule |
| Environments | env dir + r10k | top.sls + file_roots | env JSON db | inventory groups |
| Classification | site.pp + Hiera | top.sls | roles + environments | inventory |
| Orchestration | Bolt / Puppet Tasks | salt-run + reactor | knife ssh / push jobs | AWX/Tower |
| Event driven | No (polling) | Yes (ZeroMQ event bus) | No (polling) | No (push) |
| GUI | PE Console | SaltStack Enterprise | Chef Automate | AWX/Ansible Tower |

---



---

[← Previous](15-deep-understanding.md) | [↑ Index](index.md) | [Next →](17-whats-coming-in-part-55.md)
