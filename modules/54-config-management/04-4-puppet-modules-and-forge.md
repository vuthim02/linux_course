## 4. Puppet Modules and Forge

### Using Forge Modules (Puppetfile)

```puppet
forge 'https://forge.puppet.com'
mod 'puppetlabs/stdlib',      '9.4.0'
mod 'puppetlabs/concat',      '8.1.0'
mod 'puppet/nginx',           '3.3.0'
mod 'puppetlabs/postgresql',  '9.3.0'
mod 'puppetlabs/firewall',    '3.4.0'
mod 'profile_base',
  git: 'https://git.example.com/puppet/profile_base.git',
  ref: 'v1.2.3'
```

### Module Skeleton

```
my_module/
├── manifests/init.pp, install.pp, config.pp, service.pp
├── templates/config.epp, config.erb
├── files/default.conf
├── lib/puppet/type/         # custom types
├── lib/puppet/provider/     # custom providers
├── lib/facter/              # custom facts
├── data/common.yaml
├── spec/classes/            # unit tests
├── metadata.json
└── README.md
```

### metadata.json

```json
{
  "name": "myorg-apache", "version": "1.2.0",
  "dependencies": [
    { "name": "puppetlabs/stdlib", "version_requirement": ">= 6.0.0 < 10.0.0" }
  ]
}
```

### Dependency Resolution (r10k)

```bash
r10k puppetfile install --moduledir=/etc/puppetlabs/code/environments/production/modules
r10k deploy environment production -v
```





[← Previous](03-3-puppet-dsl.md) | [↑ Index](index.md) | [Next →](05-5-puppet-in-practice-roles.md)
