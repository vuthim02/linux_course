## 1. CI/CD Concepts

### Continuous Integration (CI)

Automatically build and test every commit: detect change → checkout → install deps → run tests → report results. Broken code never reaches main.

### Continuous Delivery (CD)

CI + auto-deploy tested artifact to staging. Human approves production push. Produces a release-ready artifact (JAR, Docker image, DEB) every time.

### Continuous Deployment

Full automation — every passing commit deploys to production. No human gate. Requires extreme confidence in test suite and rollback mechanisms.

### Pipeline Stages

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  BUILD  │ → │  TEST   │ → │ SCAN    │ → │ DEPLOY  │ → │ VERIFY  │
│ compile │   │ unit    │   │ SAST    │   │ staging │   │ smoke   │
│ package │   │ integ   │   │ container│   │         │   │ tests   │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Trunk-Based vs GitFlow

| Aspect | Trunk-Based | GitFlow |
|--------|------------|---------|
| Branching | Single `main` branch, short-lived feature branches | `develop`, `main`, `feature/*`, `release/*`, `hotfix/*` |
| CI frequency | Every commit to trunk | Every commit to develop, release branches |
| Deploy model | Continuous Deployment | Release-based |
| Complexity | Low | High |
| Best for | SaaS, DevOps-mature teams | Enterprise, regulated, release-train |

---



---

[↑ Index](index.md) | [Next →](02-2-github-actions.md)
