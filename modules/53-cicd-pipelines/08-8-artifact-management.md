## 8. Artifact Management

**GitHub Actions:** `actions/upload-artifact@v4` (name, path, retention-days) / `actions/download-artifact@v4`
**GitLab CI:** `artifacts: { paths, expire_in, expose_as }` — auto-downloaded via `dependencies`
**Jenkins:** `archiveArtifacts artifacts: 'target/*.jar'` — available at `${BUILD_URL}artifact/`

### Docker Registries

| Registry | Login | Push |
|----------|-------|------|
| Docker Hub | `docker login -u $USER -p $PASS` | `docker push myorg/app:tag` |
| GHCR | `docker/login-action@v3` with GITHUB_TOKEN | `ghcr.io/${{ github.repository }}:${{ github.sha }}` |
| GitLab | `docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY` | `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA` |
| Nexus | `docker login nexus.example.com:5000` | `nexus.example.com:5000/my-app:tag` |
| Artifactory | `docker login myrepo.jfrog.io` | `myrepo.jfrog.io/docker-local/my-app:tag` |

### Artifact Versioning

| Strategy | Example | When |
|----------|---------|------|
| Semantic | `1.2.3` | Tagged releases |
| Commit SHA | `a1b2c3d4` | Every build |
| Build number | `build-142` | Sequential |
| Git describe | `1.2.3-5-gabc1234` | Git-derived |





[← Previous](07-7-jenkins-pipeline.md) | [↑ Index](index.md) | [Next →](09-9-pipeline-security.md)
