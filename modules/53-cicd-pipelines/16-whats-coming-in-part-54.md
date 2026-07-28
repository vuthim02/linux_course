## What's Coming in Part 54

**Part 54: Advanced Configuration Management — Puppet, Salt, Chef**

### Why Configuration Management Matters

In Part 53 you built CI/CD pipelines that deploy artifacts automatically. But what happens *after* deployment? Configuration drift — where servers slowly diverge from their intended state — is one of the most common causes of production incidents. Configuration management tools solve this by enforcing idempotent, version-controlled state across your fleet.

### What You'll Learn

- Declarative vs imperative configuration management paradigms
- **Puppet:** manifests, modules, classes, resources, Hiera, PuppetDB, Puppet Server
- **Salt:** Salt Master/Minion, states, pillars, grains, Salt SSH, Salt Cloud
- **Chef:** cookbooks, recipes, resources, Chef Server, Chef Solo, Ohai, data bags
- Comparison and migration paths between tools
- Integrating CM with CI/CD pipelines (GitOps for configs)
- Idempotency, convergence, drift detection, compliance as code
- Real-world patterns: using CM to enforce CIS benchmarks across 500 servers

### How It Connects to CI/CD

Configuration management is the "last mile" of deployment. Your CI pipeline builds the artifact; CM ensures the target server is in the right state to run it. Puppet, Salt, and Chef all integrate with CI/CD tools — you'll see how in Part 54.





[← Previous](15-command-reference.md) | [↑ Index](index.md) | [Next →](17-self-test.md)
