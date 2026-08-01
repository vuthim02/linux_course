## Section 9: CyberArk Conjur and git-crypt

### CyberArk Conjur — Secrets Management for DevOps

Follow-the-leader architecture with one master and many standby nodes.

```yaml
# docker-compose.yml
version: "3"
services:
  conjur-master:
    image: cyberark/conjur
    environment:
      CONJUR_ADMIN_PASSWORD: MySecretP@ss
      CONJUR_ACCOUNT: myorg
    volumes:
      - ./conjur-db:/opt/conjur/postgresql/data
```

```bash
# CLI usage
conjur init -u https://conjur.example.com
conjur authn login -u admin -p MySecretP@ss
conjur variable set -i db/password -v s3cret!
conjur variable get -i db/password
```

### git-crypt — Transparent Git Encryption

Protect sensitive files in git repos with AES-256.

```bash
# Install
sudo apt install git-crypt

# Initialize
git-crypt init

# Create .gitattributes
echo "*.secret filter=git-crypt diff=git-crypt" > .gitattributes
git add .gitattributes
git commit -m "Add git-crypt"

# Add a GPG user
git-crypt add-gpg-user USER_ID

# Lock/unlock
git-crypt lock    # Encrypt working tree
git-crypt unlock  # Decrypt (requires key)
```
