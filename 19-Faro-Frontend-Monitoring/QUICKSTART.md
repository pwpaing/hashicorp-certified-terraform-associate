# Quick Start Guide - Faro Frontend Monitoring

## Overview
This guide will help you quickly set up Grafana Faro receiver with S3 bucket integration for frontend monitoring and source map storage.

## Quick Setup (5 minutes)

### Step 1: Prepare AWS Credentials
Ensure your AWS credentials are configured:
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region
```

### Step 2: Create SSH Key Pair (if not exists)
```bash
aws ec2 create-key-pair --key-name terraform-key --query 'KeyMaterial' --output text > terraform-key.pem
chmod 400 terraform-key.pem
```

### Step 3: Navigate to Terraform Directory
```bash
cd terraform-manifests
```

### Step 4: Configure Variables
```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values (especially bucket_name - must be unique)
nano terraform.tfvars
```

Required changes:
- `bucket_name`: Change to a unique name (e.g., `faro-sourcemaps-yourcompany-123`)

### Step 5: Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

### Step 6: Get Your Endpoints
```bash
terraform output
```

You'll see:
- **Faro Endpoint**: `http://<ip>:12345` - Use this in your frontend app
- **Status Page**: `http://<ip>` - Verify the installation
- **S3 Bucket**: Bucket name for uploading source maps

## Using Faro in Your Frontend App

### Install Faro SDK
```bash
npm install @grafana/faro-web-sdk
```

### Initialize in Your App
```javascript
import { initializeFaro } from '@grafana/faro-web-sdk';

// Get the endpoint from terraform output
const faroEndpoint = 'http://YOUR_EC2_IP:12345';

initializeFaro({
  url: faroEndpoint,
  app: {
    name: 'my-awesome-app',
    version: '1.0.0',
    environment: 'production',
  },
});
```

## Upload Source Maps

### Option 1: Using AWS CLI
```bash
# Upload all source maps
aws s3 cp dist/ s3://YOUR-BUCKET-NAME/ --recursive --exclude "*" --include "*.map"
```

### Option 2: Using SSH
```bash
# Copy to the mounted S3 path
scp -i terraform-key.pem *.map ec2-user@YOUR_EC2_IP:/mnt/source-maps/
```

### Option 3: Build Integration
Add to your build script (package.json):
```json
{
  "scripts": {
    "deploy:sourcemaps": "aws s3 sync dist/ s3://YOUR-BUCKET-NAME/ --exclude '*' --include '*.map'"
  }
}
```

## Verify Everything Works

### 1. Check Status Page
```bash
curl http://YOUR_EC2_IP
```

### 2. Check Faro Receiver
```bash
curl http://YOUR_EC2_IP:12345/healthz
```

### 3. SSH to Instance
```bash
ssh -i terraform-key.pem ec2-user@YOUR_EC2_IP

# Verify S3 mount
df -h | grep source-maps

# Check Docker container
sudo docker ps

# View logs
sudo docker logs faro-receiver
```

## Next Steps

1. **Configure Backend Endpoints**: Update the Alloy config with your Loki/Tempo endpoints
2. **Set Up HTTPS**: Add SSL certificates for production use
3. **Restrict Access**: Update security groups to allow only your frontend's IP ranges
4. **Add Monitoring**: Set up CloudWatch alarms for the EC2 instance
5. **Automate Source Map Uploads**: Integrate with your CI/CD pipeline

## Common Issues

### Port 12345 Not Accessible
- Check security group allows inbound traffic on port 12345
- Verify Docker container is running: `sudo docker ps`

### S3 Mount Not Working
- SSH to instance and manually mount:
  ```bash
  sudo s3fs BUCKET_NAME /mnt/source-maps -o iam_role=auto -o url=https://s3-us-east-1.amazonaws.com
  ```

### Faro Not Receiving Data
- Verify CORS is enabled (it's set to allow all in default config)
- Check browser console for errors
- Verify the URL is correct

## Clean Up

When you're done testing:
```bash
terraform destroy
```

## Support

- Terraform Issues: Check `terraform-manifests/` directory
- Faro Configuration: Check `/opt/faro-receiver/config.alloy` on EC2
- S3 Access: Verify IAM role and policy in AWS console

## Architecture Diagram

```
┌─────────────────┐
│  Frontend App   │
│  (Browser)      │
└────────┬────────┘
         │ Faro SDK sends data
         │ (port 12345)
         ▼
┌─────────────────────────┐
│   EC2 Instance          │
│  ┌──────────────────┐   │
│  │ Faro Receiver    │   │
│  │ (Grafana Alloy)  │   │
│  └──────────────────┘   │
│  ┌──────────────────┐   │
│  │ S3FS Mount       │   │
│  │ /mnt/source-maps │   │
│  └──────────────────┘   │
└─────────┬───────────────┘
          │ IAM Role
          ▼
  ┌────────────────┐
  │   S3 Bucket    │
  │  Source Maps   │
  │  (Encrypted)   │
  └────────────────┘
```

## Resources

- [Grafana Faro Documentation](https://grafana.com/docs/faro/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [s3fs Documentation](https://github.com/s3fs-fuse/s3fs-fuse)
