# Monitoring & Logging Setup

## Overview

All monitoring and logging infrastructure is provisioned as code via the `terraform/modules/monitoring/` module. Each environment (dev, staging, prod) calls this module with environment-specific thresholds and retention settings.

## Components

### 1. CloudWatch Log Group

Container stdout/stderr is streamed to CloudWatch Logs using the `awslogs` log driver configured in the ECS task definition.

| Environment | Log Group Name                        | Retention |
|-------------|---------------------------------------|-----------|
| dev         | `/ecs/people-assignment-dev`          | 7 days    |
| staging     | `/ecs/people-assignment-staging`      | 30 days   |
| prod        | `/ecs/people-assignment-prod`         | 90 days   |

**Viewing logs:**

```bash
# Stream live logs
aws logs tail /ecs/people-assignment-dev --follow

# Search logs for errors
aws logs filter-log-events \
  --log-group-name /ecs/people-assignment-dev \
  --filter-pattern "ERROR"
```

### 2. CloudWatch Alarms

Three alarms are configured per environment, each sending notifications to an SNS topic (if `alarm_email` is set):

| Alarm                | Metric                              | Condition              | Dev Threshold | Staging | Prod |
|----------------------|-------------------------------------|------------------------|---------------|---------|------|
| CPU High             | ECS `CPUUtilization`                | Average > threshold    | 85%           | 80%     | 70%  |
| 5xx Error Spike      | ALB `HTTPCode_Target_5XX_Count`     | Sum > threshold (5min) | 20            | 10      | 5    |
| Slow Response Time   | ALB `TargetResponseTime`            | Average > threshold    | 3s            | 2s      | 1s   |

**Checking alarm state:**

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix people-assignment-dev
```

### 3. CloudWatch Dashboard

A dashboard is created per environment with six widgets:

1. **ECS CPU Utilization** -- Average CPU usage across all tasks
2. **ECS Memory Utilization** -- Average memory usage across all tasks
3. **ALB Request Count** -- Total requests hitting the load balancer
4. **ALB Target Response Time** -- Average backend response latency
5. **ALB HTTP 5xx Errors** -- Count of server errors (both target and ELB-originated)
6. **Healthy Host Count** -- Number of healthy ECS tasks behind the ALB

**Accessing the dashboard:**

```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=people-assignment-dev
```

### 4. Container Insights

ECS Container Insights is enabled on the cluster, providing additional metrics:

- Per-task CPU and memory usage
- Network I/O
- Storage read/write operations

These metrics appear automatically in the CloudWatch console under **Container Insights**.

### 5. SNS Notifications

When `alarm_email` is configured in `terraform.tfvars`:

1. An SNS topic is created: `people-assignment-{env}-alarms`
2. An email subscription is added
3. AWS sends a confirmation email -- the recipient must click **Confirm subscription**
4. Once confirmed, alarm state changes trigger email notifications

## Sample Dashboard Layout

```
+-----------------------------+-----------------------------+
|    ECS CPU Utilization      |   ECS Memory Utilization    |
|         (timeSeries)        |       (timeSeries)          |
+-----------------------------+-----------------------------+
|  ALB Request Count  | ALB Response Time |  ALB 5xx Errors |
|    (timeSeries)     |   (timeSeries)    |  (timeSeries)   |
+-----------------------------+-----------------------------+
|        Healthy Host Count                                 |
|            (timeSeries)                                   |
+-----------------------------------------------------------+
```

## Extending the Setup

To add custom application metrics (e.g., request latency percentiles, business metrics):

1. Use the `aws-embedded-metrics` Python library in the Flask app
2. Metrics are automatically published to CloudWatch via the log driver
3. Add new widgets to the dashboard in `modules/monitoring/main.tf`
