## 🔍 Section 11: Cloud Secrets Managers

### AWS Secrets Manager

```
aws secretsmanager create-secret --name production/db-password \
    --secret-string '{"username":"admin","password":"SuperS3cret!"}'
aws secretsmanager get-secret-value --secret-id production/db-password --query SecretString --output text
aws secretsmanager rotate-secret --secret-id production/db-password \
    --rotation-lambda-arn arn:aws:lambda:...:function:rotate-db
```

### GCP Secret Manager

```
gcloud secrets create production-db-password --replication-policy=user-managed --locations=us-east1
echo -n "SuperS3cret!" | gcloud secrets versions add production-db-password --data-file=-
gcloud secrets versions access latest --secret=production-db-password
gcloud secrets add-iam-policy-binding production-db-password \
    --member=serviceAccount:my-app-sa@... --role=roles/secretmanager.secretAccessor
```

### Azure Key Vault

```
az keyvault create --name my-vault --resource-group my-rg --enable-soft-delete true
az keyvault secret set --vault-name my-vault --name db-password --value "SuperS3cret!"
az keyvault secret show --vault-name my-vault --name db-password --query value --output tsv
az keyvault network-rule add --name my-vault --ip-address 10.0.0.0/24
```

### When to Run Vault vs Cloud Native

| Scenario | Choice |
|----------|--------|
| Single cloud, few secrets | Cloud native |
| Multi-cloud or on-prem | Vault |
| Dynamic DB creds needed | Vault |
| PKI/TLS needed | Vault |
| Encryption-as-a-service | Vault |
| Small team, minimal ops | Cloud native |





[← Previous](11-section-10-sealed-secrets-bitnami.md) | [↑ Index](index.md) | [Next →](13-section-12-best-practices.md)
