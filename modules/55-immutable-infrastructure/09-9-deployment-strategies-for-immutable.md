## 9. Deployment Strategies for Immutable

### Replacing Instances (Auto Scaling Group)

```bash
# Create a launch template from the new AMI
aws ec2 create-launch-template \
  --launch-template-name webapp-v2 \
  --launch-template-data '{
    "ImageId": "ami-0abcdef1234567890",
    "InstanceType": "t3.medium",
    "SecurityGroupIds": ["sg-12345678"],
    "UserData": "'"$(base64 -w0 userdata.sh)"'"
  }'

# Update ASG with new launch template
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name webapp-prod \
  --launch-template "LaunchTemplateName=webapp-v2,Version=\$Default"

# Start instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name webapp-prod \
  --preferences '{
    "InstanceWarmup": 60,
    "MinHealthyPercentage": 90,
    "SkipMatching": false
  }'

# Monitor
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name webapp-prod
```

### Blue/Green Deployment

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -euo pipefail

NEW_AMI_ID=$1
ENVIRONMENT=${2:-prod}
ASG_BLUE="webapp-${ENVIRONMENT}-blue"
ASG_GREEN="webapp-${ENVIRONMENT}-green"
ALB_NAME="webapp-${ENVIRONMENT}"

echo "=== Blue/Green Deployment ==="
echo "New AMI: $NEW_AMI_ID"
echo "Environment: $ENVIRONMENT"

# Determine current active color
CURRENT_TG=$(aws elbv2 describe-target-groups \
  --names "webapp-${ENVIRONMENT}" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

CURRENT_ASG=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_BLUE" "$ASG_GREEN" \
  --query 'AutoScalingGroups[?length(TargetGroupARNs) > `0`].AutoScalingGroupName' \
  --output text)

if [ "$CURRENT_ASG" = "$ASG_BLUE" ]; then
  NEW_COLOR="green"
  STANDBY_COLOR="blue"
else
  NEW_COLOR="blue"
  STANDBY_COLOR="green"
fi

echo "Current: $CURRENT_ASG"
echo "Deploying to: $NEW_COLOR"

# Create new launch template for new color
aws ec2 create-launch-template-version \
  --launch-template-name "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
  --source-version 1 \
  --launch-template-data "{\"ImageId\":\"$NEW_AMI_ID\"}"

# Update the standby ASG with new AMI
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
  --launch-template "LaunchTemplateName=webapp-${ENVIRONMENT}-${NEW_COLOR},Version=\$Latest"

# Scale up new ASG
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
  --desired-capacity 2

# Wait for instances to be healthy
echo "Waiting for new instances to become healthy..."
aws elbv2 describe-target-health \
  --target-group-arn "$(aws elbv2 describe-target-groups \
    --names "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)" \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`].Length()'

# Switch ALB listener to new target group
aws elbv2 modify-listener \
  --listener-arn "$(aws elbv2 describe-listeners \
    --load-balancer-arn "$(aws elbv2 describe-load-balancers \
      --names "webapp-${ENVIRONMENT}" \
      --query 'LoadBalancers[0].LoadBalancerArn' \
      --output text)" \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text)" \
  --default-actions "Type=forward,TargetGroupArn=$(aws elbv2 describe-target-groups \
    --names "webapp-${ENVIRONMENT}-${NEW_COLOR}" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)"

# Scale down old ASG
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "webapp-${ENVIRONMENT}-${STANDBY_COLOR}" \
  --desired-capacity 0

echo "=== Blue/Green Deployment Complete ==="
echo "Active: ${NEW_COLOR} (AMI: $NEW_AMI_ID)"
echo "Standby: ${STANDBY_COLOR} (scaled to 0)"
```

### Canary Deployment

```bash
# Deploy 10% of traffic to new version
aws elbv2 create-rule \
  --listener-arn "$LISTENER_ARN" \
  --priority 10 \
  --conditions '[
    {"Field":"path-pattern","Values":["/canary/*"]}
  ]' \
  --actions '[
    {"Type":"forward","TargetGroupArn":"'$NEW_TG_ARN'"}
  ]'

# Or use weighted target groups (forward to multiple TGs with weights)
aws elbv2 modify-listener \
  --listener-arn "$LISTENER_ARN" \
  --default-actions '[
    {
      "Type":"forward",
      "ForwardConfig": {
        "TargetGroups": [
          {"TargetGroupArn":"'$OLD_TG_ARN'","Weight":90},
          {"TargetGroupArn":"'$NEW_TG_ARN'","Weight":10}
        ]
      }
    }
  ]'

# Gradually shift traffic
# 10% → 25% → 50% → 75% → 100%
```

### Infrastructure as Code (Terraform)

```hcl
# terraform/deploy.tf
resource "aws_launch_template" "webapp" {
  name          = "webapp-${var.image_version}"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data     = base64encode(file("userdata.sh"))

  vpc_security_group_ids = [aws_security_group.webapp.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.webapp.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "webapp-${var.environment}"
      Version = var.image_version
    }
  }
}

resource "aws_autoscaling_group" "webapp" {
  name                = "webapp-${var.environment}-${var.image_version}"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.webapp.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "webapp-${var.environment}"
    propagate_at_launch = true
  }
}
```

---



---

[← Previous](08-8-security-hardening-in-images.md) | [↑ Index](index.md) | [Next →](10-10-userdata-and-first-boot.md)
