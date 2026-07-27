## Deep Understanding

### How CI Systems Work Internally

**Polling vs Webhooks:** Polling checks the repo periodically (e.g., Jenkins `pollSCM` every 5 min). Most polls waste resources but work behind firewalls. Webhooks send HTTP POST on each event — instant, no wasted requests. GitHub goes to `/github-webhook/`, GitLab to project webhooks.

**How Runners Pick Up Jobs:** GitHub Actions runners poll `api.github.com` with JWT, receive work envelope (job ID, URL, token), download steps, execute, stream logs. GitLab runners poll `api/v4/jobs/request` with tags; server returns 409 (no job) or 201 (assigned). Jenkins agents connect via SSH/JNLP/WebSocket; master sends jobs when executors are free.

**Container Runners:** Docker-in-Docker (DinD) uses a sibling `docker:dind` container as Docker daemon for builds. Kubernetes pod runners (GitLab K8s executor) create a pod per job with build + service + optional dind containers, deleted when done.

**Composite Actions (GitHub):** Runner reads `action.yml`, parses `runs.steps`, injects each step into the calling workflow's step list at the `uses` point — syntactic AST-level step injection, not a function call.

**Reusable Workflows:** Caller dispatches a new isolated workflow run. Inputs/secrets passed via API (encrypted). Outputs propagated via `$GITHUB_OUTPUT` back through the API. The callee checks out its own code — no workspace sharing.

**Jenkins Pipeline DSL → Groovy AST:** The DSL is parsed by `groovy-parser` into AST, transformed by CPS AST transformers (`org.jenkinsci.plugins.workflow.cps.DSL`), compiled to bytecode, and run inside a **Continuation Passing Style** engine. CPS serializes each stage's execution state to disk when the pipeline pauses (waiting for input/agent) and deserializes on resume. This is why all variables must be `Serializable`.

**CI vs CD Infrastructure:** CI = build servers, test runners, caches — CPU-heavy, short-lived, auto-scalable. CD = deployment agents, orchestrators, load balancers — need network access to targets, secrets, rollback. CI *produces* artifacts; CD *consumes* them in environments. Network topology: CI in isolated build network; CD has controlled production access via bastions/VPN/service mesh.

---



---

[← Previous](13-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](15-command-reference.md)
