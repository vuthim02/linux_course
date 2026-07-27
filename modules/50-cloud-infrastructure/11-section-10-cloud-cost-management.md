## 🔍 Section 10: Cloud Cost Management

### Tagging Strategy

```bash
# AWS: Tag resources
aws ec2 create-tags \
  --resources i-0abcdef1234567890 \
  --tags Key=Environment,Value=Production \
         Key=CostCenter,Value=CC-1234 \
         Key=Owner,Value=devops-team \
         Key=Project,Value=my-app

# GCP: Label resources
gcloud compute instances add-labels my-instance \
  --labels=environment=production,cost-center=cc-1234,owner=devops

# Azure: Tag resources
az tag create \
  --resource-id /subscriptions/SUB_ID/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM \
  --tags Environment=Production CostCenter=CC-1234 Owner=DevOps
```

### Billing Alerts

```bash
# AWS: Create a budget
# Can be done via CLI with budgets.json:
cat > budget.json << 'EOF'
{
    "BudgetName": "Monthly-Development-Budget",
    "BudgetLimit": {
        "Amount": "1000",
        "Unit": "USD"
    },
    "CostFilters": {
        "TagKeyValue": [
            "Environment$Development"
        ]
    },
    "CostTypes": {
        "IncludeTax": true,
        "IncludeSubscription": true,
        "UseBlended": false
    },
    "TimeUnit": "MONTHLY",
    "BudgetNotifications": [
        {
            "Notification": {
                "NotificationType": "ACTUAL",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 80,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "devops@example.com"
                }
            ]
        },
        {
            "Notification": {
                "NotificationType": "FORECASTED",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 100,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "devops@example.com"
                }
            ]
        }
    ]
}
EOF

aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json

# GCP: Create a budget
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Dev Budget" \
  --budget-amount=1000 \
  --threshold-rules=percent=0.5 \
  --threshold-rules=percent=0.8 \
  --threshold-rules=percent=1.0 \
  --notifications-rule-pubsub-topic=projects/my-project/topics/budget-alerts \
  --notifications-rule-schema-update=true \
  --notifications-rule-disable-default-iam-recipients=false \
  --filter-projects=projects/my-project-id

# Azure: Create a budget
az consumption budget create \
  --budget-name "MonthlyBudget" \
  --category cost \
  --amount 1000 \
  --time-grain monthly \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --notifications \
    '{"operator":"GreaterThan","threshold":80,"contact-emails":["devops@example.com"],"enabled":true}' \
  --resource-group myResourceGroup
```

### Reserved Instances and Savings Plans

```bash
# AWS: Purchase reserved instance
# (Use console — CLI is complex, but here's the concept)
# Standard RI: 1yr or 3yr, can modify AZ/instance size within family
# Convertible RI: Can change instance family, higher discount, but flexible

# AWS Savings Plans
# Compute Savings Plans: Apply to any compute (EC2, Fargate, Lambda)
# EC2 Instance Savings Plans: Apply to specific instance family in a region

# GCP: Committed Use Discounts (CUDs)
# 1yr or 3yr commitment for vCPUs and memory
gcloud compute commitments create my-commitment \
  --region=us-central1 \
  --plan=36-month \
  --resources=vcpu=50,memory=200GB

# Azure: Reserved VM Instances
# 1yr or 3yr, pay upfront/partial/monthly
az reservation calculate --sku Standard_D2s_v3 --location eastus

# Azure Savings Plan for Compute
# Similar to AWS — commit to hourly spend for 1yr or 3yr
```

### Right-Sizing

```bash
# AWS: Get right-sizing recommendations
aws compute-optimizer get-ec2-instance-recommendations \
  --instance-arns arn:aws:ec2:us-east-1:123456789012:instance/i-0abcdef1234567890

# GCP: Rightsizing recommendations
gcloud recommender recommendations list \
  --project=my-project \
  --location=us-central1-a \
  --recommender=google.compute.instance.MachineTypeRecommender \
  --format="json"

# Azure: Advisor recommendations
az advisor recommendation list \
  --resource-group myResourceGroup \
  --category Cost
```

---



---

[← Previous](10-section-9-cloud-ssh-access.md) | [↑ Index](index.md) | [Next →](12-section-11-multi-cloud-comparison.md)
