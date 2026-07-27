## 9. Pipeline Security

### Secret Scanning

**GitHub Secret Scanning:**
Automatically detects secrets in public repositories. Partner patterns (AWS, GCP, Azure, GitHub tokens, npm, etc.) + custom patterns.

Enable: Repository → Settings → Code security & analysis → Secret scanning → Enable

Custom patterns:
```
# Example: detect internal API tokens
ghs_[a-zA-Z0-9]{36}
```

**GitLab Secret Detection:**
```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml

secret_detection:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH =~ /^(main|develop)$/
```

Uses Gitleaks and TruffleHog under the hood.

**TruffleHog (standalone):**
```yaml
trufflehog:
  stage: scan
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog filesystem --directory=$CI_PROJECT_DIR --json | tee trufflehog-report.json
  artifacts:
    paths:
      - trufflehog-report.json
    when: always
```

### Signed Commits

```bash
# Configure GPG signing
gpg --full-generate-key
git config --global user.signingkey KEY_ID
git config --global commit.gpgsign true

# Verify signatures
git log --show-signature

# GitHub: Settings → SSH and GPG keys → New GPG key
# Enable: Settings → "Flag unsigned commits as unverified"
```

GitLab verified commits: Settings → Repository → Push rules → **Reject unsigned commits**

### SBOM Generation (CycloneDX)

```yaml
# GitHub Actions: uses: CycloneDX/gh-node-module-generatebom@v1 with path: . output: ./bom.json
# GitLab CI: npm install -g @cyclonedx/bom && cyclonedx-bom -o gl-sbom-$CI_COMMIT_SHORT_SHA.json
```

### Supply-Chain Security (SLSA)

SLSA 1–4 framework: build documented → version control + signed provenance → non-falsifiable provenance → two-person review. Use `slsa-framework/slsa-github-generator` for SLSA 3 provenance in GitHub Actions.

---



---

[← Previous](08-8-artifact-management.md) | [↑ Index](index.md) | [Next →](10-10-testing-in-ci.md)
