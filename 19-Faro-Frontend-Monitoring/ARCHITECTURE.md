# Architecture Documentation

## Infrastructure Overview

This document describes the architecture and components of the Faro Frontend Monitoring infrastructure with S3 integration.

## High-Level Architecture

```
                           ┌─────────────────────────────────┐
                           │     Frontend Application        │
                           │      (Web Browser)              │
                           │                                 │
                           │  ┌───────────────────────────┐  │
                           │  │  @grafana/faro-web-sdk    │  │
                           │  │  - Logs                   │  │
                           │  │  - Traces                 │  │
                           │  │  - Measurements           │  │
                           │  │  - Errors                 │  │
                           │  └───────────────────────────┘  │
                           └──────────────┬──────────────────┘
                                          │
                                          │ HTTP POST
                                          │ (Port 12345)
                                          ▼
              ┌─────────────────────────────────────────────────┐
              │           AWS EC2 Instance                       │
              │           (Amazon Linux 2)                       │
              │                                                  │
              │  ┌────────────────────────────────────────────┐ │
              │  │         Docker Container                    │ │
              │  │  ┌──────────────────────────────────────┐  │ │
              │  │  │   Grafana Alloy (Faro Receiver)      │  │ │
              │  │  │   - Receives monitoring data         │  │ │
              │  │  │   - Processes source maps            │  │ │
              │  │  │   - Exports to backends              │  │ │
              │  │  └──────────────────────────────────────┘  │ │
              │  └────────────────────────────────────────────┘ │
              │                                                  │
              │  ┌────────────────────────────────────────────┐ │
              │  │  S3FS Mount: /mnt/source-maps             │ │
              │  │  - Mounts S3 bucket as filesystem         │ │
              │  │  - Read/Write access via FUSE             │ │
              │  └────────────────────────────────────────────┘ │
              │                                                  │
              │  ┌────────────────────────────────────────────┐ │
              │  │  IAM Instance Profile                      │ │
              │  │  Role: faro-ec2-s3-access-role            │ │
              │  └────────────────────────────────────────────┘ │
              └──────────────────┬───────────────────────────────┘
                                 │
                                 │ IAM Role Credentials
                                 │ (No keys required)
                                 ▼
                      ┌──────────────────────┐
                      │    AWS S3 Bucket     │
                      │  Source Maps Storage │
                      │                      │
                      │  - Encrypted (AES256)│
                      │  - Versioned         │
                      │  - Private           │
                      └──────────────────────┘
```

## Component Details

### 1. Frontend Application
- **Technology**: Web Browser
- **SDK**: @grafana/faro-web-sdk
- **Data Sent**:
  - Application logs
  - User interactions
  - Performance measurements
  - JavaScript errors and stack traces
  - Web Vitals metrics

### 2. EC2 Instance
- **OS**: Amazon Linux 2 (Latest AMI)
- **Instance Type**: t2.small (configurable)
- **Storage**: 30GB encrypted EBS (gp3)
- **Networking**: 
  - Public IP for internet access
  - Security groups for ports 22, 80, 443, 12345
  
**Software Stack**:
- Docker & Docker Compose
- s3fs-fuse for S3 mounting
- Nginx (status page)
- Grafana Alloy container

### 3. Faro Receiver (Grafana Alloy)
- **Container**: grafana/alloy:latest
- **Port**: 12345
- **Purpose**: 
  - Receives frontend monitoring data via HTTP
  - Processes and enriches telemetry
  - Uses source maps to decode stack traces
  - Exports to observability backends

**Configuration File**: `/opt/faro-receiver/config.alloy`

### 4. S3 Bucket
- **Purpose**: Store JavaScript source maps
- **Access**: Private (IAM role-based)
- **Features**:
  - Server-side encryption (AES256)
  - Versioning enabled
  - Public access blocked
- **Mount Point**: `/mnt/source-maps` on EC2

### 5. IAM Components

**IAM Role**: `faro-ec2-s3-access-role`
- Allows EC2 to assume the role
- No access keys required

**IAM Policy**: `faro-s3-access-policy`
- Permissions:
  - `s3:ListBucket` - List objects in bucket
  - `s3:GetBucketLocation` - Get bucket region
  - `s3:PutObject` - Upload source maps
  - `s3:GetObject` - Download source maps
  - `s3:DeleteObject` - Remove old source maps

**IAM Instance Profile**: `faro-ec2-instance-profile`
- Attached to EC2 instance
- Provides automatic credential rotation

### 6. Security Groups

**faro-ssh** Security Group:
- Inbound: Port 22 (SSH) from 0.0.0.0/0
- Outbound: All traffic

**faro-receiver** Security Group:
- Inbound:
  - Port 80 (HTTP) from 0.0.0.0/0
  - Port 443 (HTTPS) from 0.0.0.0/0
  - Port 12345 (Faro) from 0.0.0.0/0
- Outbound: All traffic

## Data Flow

### 1. Frontend Monitoring Data
```
Browser → Faro SDK → HTTP POST → EC2:12345 → Alloy → Processing → Backends
```

### 2. Source Maps Upload
```
Developer → AWS CLI/SSH → S3 Bucket → S3FS Mount → EC2:/mnt/source-maps
                    ↓
              Alloy reads maps
```

### 3. Stack Trace Processing
```
Error in Browser → Minified Stack Trace → Faro Receiver
                                              ↓
                                        Reads Source Map
                                              ↓
                                   Original Code Location
                                              ↓
                                      Enriched Error
```

## Network Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Internet                                                     │
│                                                               │
│  ┌──────────┐         ┌──────────┐         ┌──────────┐     │
│  │ Browser  │────────▶│   EC2    │────────▶│    S3    │     │
│  │          │ HTTP    │ Instance │  IAM    │  Bucket  │     │
│  │          │         │          │  Role   │          │     │
│  └──────────┘         └──────────┘         └──────────┘     │
│                                                               │
│  Ports:                                                       │
│  - 80 (Status page)                                          │
│  - 443 (HTTPS - optional)                                    │
│  - 12345 (Faro receiver)                                     │
│  - 22 (SSH admin access)                                     │
└──────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Defense in Depth

1. **Network Layer**:
   - Security groups control traffic
   - Only necessary ports open
   - Consider restricting SSH to specific IPs

2. **Application Layer**:
   - CORS configured for Faro receiver
   - Docker container isolation
   - Non-root container execution

3. **Data Layer**:
   - S3 encryption at rest (AES256)
   - EBS volume encryption
   - IAM role-based access (no static keys)
   - S3 public access blocked

4. **Access Control**:
   - IAM least-privilege policy
   - Instance profile for credential management
   - No AWS credentials stored on instance

## Deployment Workflow

```
1. Developer runs:
   terraform apply
        ↓
2. Terraform creates:
   - S3 Bucket
   - IAM Role & Policy
   - Security Groups
   - EC2 Instance
        ↓
3. EC2 User Data executes:
   - Install dependencies
   - Setup s3fs-fuse
   - Mount S3 bucket
   - Install Docker
   - Deploy Alloy container
   - Configure Nginx
        ↓
4. Services start:
   - Faro receiver (port 12345)
   - Nginx status page (port 80)
        ↓
5. Ready to receive data!
```

## Monitoring and Observability

### What to Monitor

1. **EC2 Instance**:
   - CPU utilization
   - Memory usage
   - Disk space (/mnt/source-maps)
   - Network throughput

2. **Faro Receiver**:
   - Container status
   - Request rate
   - Error rate
   - Response times

3. **S3 Bucket**:
   - Storage size
   - Request count
   - Error rate

### Logging

- **Docker Logs**: `sudo docker logs faro-receiver`
- **S3FS Logs**: Check syslog for mount issues
- **System Logs**: `/var/log/messages`, `/var/log/cloud-init.log`

## Scalability Considerations

### Current Setup
- **Suitable for**: Small to medium applications
- **Expected load**: Up to 1000 events/second
- **Storage**: Unlimited (S3 scales automatically)

### Scaling Options

1. **Vertical Scaling**:
   - Change `instance_type` to larger size (t2.medium, t2.large)
   - Increase EBS volume size

2. **Horizontal Scaling**:
   - Use Application Load Balancer
   - Multiple EC2 instances
   - Auto Scaling Group

3. **High Availability**:
   - Deploy in multiple Availability Zones
   - Use Multi-AZ for resilience
   - Implement health checks

## Cost Optimization

### Current Costs (us-east-1)
- EC2 t2.small: ~$17/month
- S3 storage: $0.023/GB/month
- Data transfer: First 100GB free/month
- **Estimated Total**: $17-25/month

### Optimization Tips
1. Use Reserved Instances for 40-60% savings
2. Enable S3 Intelligent-Tiering
3. Use S3 Lifecycle policies to move old source maps to Glacier
4. Monitor and right-size instance

## Backup and Disaster Recovery

### S3 Bucket
- **Versioning**: Enabled (protects against accidental deletions)
- **Backup**: Not needed (S3 has 99.999999999% durability)
- **Cross-Region Replication**: Optional for critical data

### EC2 Instance
- **AMI Snapshots**: Create AMIs periodically
- **Configuration**: Managed by Terraform (infrastructure as code)
- **Recovery**: Redeploy with `terraform apply`

## Maintenance

### Regular Tasks
- Update Grafana Alloy image: `docker-compose pull && docker-compose up -d`
- Rotate SSH keys periodically
- Review CloudWatch metrics
- Clean up old source maps

### Updates
```bash
# SSH to instance
ssh -i terraform-key.pem ec2-user@<instance-ip>

# Update Alloy
cd /opt/faro-receiver
sudo docker-compose pull
sudo docker-compose up -d

# Update system packages
sudo yum update -y
```

## Troubleshooting Guide

### Issue: Faro receiver not responding
**Check**:
1. Security group allows port 12345
2. Docker container is running: `sudo docker ps`
3. Check logs: `sudo docker logs faro-receiver`

### Issue: S3 mount failed
**Check**:
1. IAM role is attached to instance
2. S3 bucket exists and is accessible
3. Remount: `sudo s3fs <bucket> /mnt/source-maps -o iam_role=auto`

### Issue: High latency
**Check**:
1. Instance type is sufficient
2. Network connectivity
3. Check CloudWatch metrics

## Future Enhancements

1. **HTTPS/SSL**: Add Let's Encrypt certificates
2. **Authentication**: Add API key authentication for Faro endpoint
3. **Monitoring**: Integrate with CloudWatch/Prometheus
4. **Auto-scaling**: Implement based on load
5. **Multi-region**: Deploy in multiple regions for better latency
6. **CDN**: Use CloudFront for global distribution

## References

- [Grafana Faro Documentation](https://grafana.com/docs/faro/)
- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [s3fs-fuse Documentation](https://github.com/s3fs-fuse/s3fs-fuse)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
