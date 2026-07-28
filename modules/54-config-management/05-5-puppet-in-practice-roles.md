## 5. Puppet in Practice — Roles and Profiles

### The Pattern

```
site.pp → node 'web01' { role('web_server') }

roles/manifests/web_server.pp
  → class role::web_server {
      include profile::base
      include profile::nginx
      include profile::firewall
    }

profiles/manifests/
├── base.pp   → class profile::base { ... }     # OS config, users, repos
├── nginx.pp  → class profile::nginx { ... }    # Nginx with business logic
└── firewall.pp → class profile::firewall { .. } # Firewall rules
```

**Roles** are pure compositions — never contain business logic.
**Profiles** wrap upstream Forge modules with your org's defaults:

```puppet
class profile::nginx (
  Array[String] $vhosts    = lookup('profile::nginx::vhosts'),
  Integer       $worker    = lookup('profile::nginx::worker_process'),
) {
  class { 'nginx': worker_processes => $worker }
  $vhosts.each |$vhost| {
    nginx::resource::server { $vhost['server_name']:
      listen_port => $vhost['port'], ssl => $vhost['ssl'],
      ssl_cert    => $vhost['ssl_cert'], ssl_key => $vhost['ssl_key'],
      www_root    => $vhost['docroot'],
    }
  }
  include profile::monitoring::nginx
}
```

### hiera-eyaml for Secrets

```bash
eyaml createkeys
eyaml encrypt -s 's3kr3t!' --pkcs7-private-key=pkcs7_key.pem --pkcs7-public-key=pkcs7_key.pem
```

```yaml
# data/common.yaml
profile::app::db_password: >
  ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIB...]
```





[← Previous](04-4-puppet-modules-and-forge.md) | [↑ Index](index.md) | [Next →](06-6-saltstack-architecture.md)
