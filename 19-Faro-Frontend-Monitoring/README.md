# Faro Frontend Monitoring with S3 Source Maps

This Terraform module sets up a complete infrastructure for frontend monitoring using Grafana Faro receiver with S3 bucket integration for source map storage.

## Architecture Overview

This setup creates:
- **EC2 Instance** running Grafana Alloy (Faro receiver) in a Docker container
- **S3 Bucket** for storing frontend source maps with encryption and versioning
- **S3FS Mount** to mount the S3 bucket directly on the EC2 instance at `/mnt/source-maps`
- **IAM Role & Policy** to allow EC2 instance to access the S3 bucket
- **Security Groups** for SSH and Faro receiver access
- **Status Page** accessible via HTTP to verify the setup

## Features

✓ **Faro Receiver**: Accepts frontend monitoring data (logs, traces, measurements)  
✓ **S3 Integration**: Source maps stored in S3 bucket  
✓ **Automatic Mounting**: S3 bucket automatically mounted on EC2 using s3fs-fuse  
✓ **Secure Access**: IAM role-based access (no credentials needed)  
✓ **Encrypted Storage**: S3 bucket encrypted at rest  
✓ **Versioning**: Source map versions tracked in S3  
✓ **Docker-based**: Faro receiver runs in Docker for easy management  

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.4)
3. SSH key pair created in AWS (default: `terraform-key`)
4. AWS account with permissions to create EC2, S3, IAM resources

## Configuration

### Variables

You can customize the following variables in `terraform.tfvars`:

```hcl
aws_region    = "us-east-1"      # AWS region
instance_type = "t2.small"        # EC2 instance type
bucket_name   = "faro-source-maps-bucket"  # S3 bucket name (must be globally unique)
key_name      = "terraform-key"   # SSH key pair name
```

### Creating a terraform.tfvars file

```bash
cat <<EOF > terraform.tfvars
aws_region    = "us-east-1"
instance_type = "t2.small"
bucket_name   = "my-unique-faro-sourcemaps-$(date +%s)"
key_name      = "terraform-key"
EOF
```

## Usage

### 1. Initialize Terraform

```bash
cd terraform-manifests
terraform init
```

### 2. Plan the deployment

```bash
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 4. Get the outputs

After successful deployment, Terraform will output:

- **faro_endpoint_url**: The Faro receiver endpoint URL
- **status_page_url**: Status page to verify the setup
- **s3_bucket_name**: S3 bucket name for source maps
- **ssh_command**: SSH command to connect to the instance

```bash
terraform output
```

## Post-Deployment

### Access the Status Page

Open the status page URL in your browser:
```
http://<instance-ip>
```

### Verify Faro Receiver

The Faro receiver runs on port 12345:
```
http://<instance-ip>:12345
```

### Upload Source Maps

You have multiple options to upload source maps:

#### Option 1: SSH to the instance
```bash
ssh -i terraform-key.pem ec2-user@<instance-ip>
sudo cp your-sourcemap.js.map /mnt/source-maps/
```

#### Option 2: Use AWS CLI
```bash
aws s3 cp your-sourcemap.js.map s3://<bucket-name>/
```

#### Option 3: AWS Console
Upload files directly through the AWS S3 console.

### Configure Your Frontend Application

In your frontend application, configure Faro to send data to the receiver:

```javascript
import { initializeFaro } from '@grafana/faro-web-sdk';

initializeFaro({
  url: 'http://<instance-ip>:12345',
  app: {
    name: 'my-frontend-app',
    version: '1.0.0',
  },
});
```

## Infrastructure Components

### EC2 Instance
- **AMI**: Latest Amazon Linux 2
- **Instance Type**: t2.small (configurable)
- **Storage**: 30GB encrypted EBS volume
- **Software**:
  - Docker & Docker Compose
  - s3fs-fuse for S3 mounting
  - Nginx for status page
  - Grafana Alloy (Faro receiver)

### S3 Bucket
- **Encryption**: AES256 server-side encryption
- **Versioning**: Enabled
- **Public Access**: Blocked
- **Purpose**: Store frontend source maps

### Networking
- **Security Groups**:
  - SSH (port 22)
  - HTTP (port 80)
  - HTTPS (port 443)
  - Faro receiver (port 12345)

### IAM
- **Role**: faro-ec2-s3-access-role
- **Policy**: Allows S3 read/write access to the source maps bucket
- **Instance Profile**: Attached to EC2 instance

## Monitoring and Maintenance

### Check Faro Receiver Status

SSH to the instance and check Docker container:
```bash
ssh -i terraform-key.pem ec2-user@<instance-ip>
sudo docker ps
sudo docker logs faro-receiver
```

### Verify S3 Mount

```bash
ssh -i terraform-key.pem ec2-user@<instance-ip>
df -h | grep source-maps
ls -la /mnt/source-maps
```

### View Alloy Configuration

```bash
ssh -i terraform-key.pem ec2-user@<instance-ip>
cat /opt/faro-receiver/config.alloy
```

## Customization

### Modify Faro Receiver Configuration

1. SSH to the instance
2. Edit the Alloy configuration:
   ```bash
   sudo vi /opt/faro-receiver/config.alloy
   ```
3. Restart the container:
   ```bash
   cd /opt/faro-receiver
   sudo docker-compose restart
   ```

### Add Loki or Tempo Endpoints

Update the `config.alloy` file to point to your actual Loki (logs) and Tempo (traces) endpoints.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Note**: The S3 bucket must be empty before it can be destroyed. If you have uploaded source maps, delete them first or use the AWS console to empty the bucket.

## Cost Estimation

Approximate monthly costs (us-east-1):
- EC2 t2.small instance: ~$17/month
- S3 storage: ~$0.023/GB/month
- Data transfer: Variable based on usage
- **Total**: ~$17-25/month (depending on usage)

## Security Considerations

1. **SSH Access**: Restrict SSH access to your IP address in the security group
2. **Faro Endpoint**: Consider adding authentication or restricting access by IP
3. **HTTPS**: For production, configure SSL/TLS certificates
4. **IAM Permissions**: The EC2 instance can only access the specific S3 bucket
5. **Encryption**: S3 bucket is encrypted at rest

## Troubleshooting

### S3 Mount Issues

If the S3 bucket is not mounted:
```bash
sudo s3fs <bucket-name> /mnt/source-maps -o iam_role=auto -o url=https://s3-us-east-1.amazonaws.com -o allow_other -o use_cache=/tmp
```

### Faro Receiver Not Starting

Check Docker logs:
```bash
sudo docker logs faro-receiver
```

Restart the service:
```bash
cd /opt/faro-receiver
sudo docker-compose restart
```

### Network Issues

Verify security groups are properly configured:
```bash
terraform show | grep security_group
```

## References

- [Grafana Faro](https://grafana.com/docs/faro/)
- [Grafana Alloy](https://grafana.com/docs/alloy/)
- [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues related to:
- Terraform configuration: Check the Terraform AWS provider documentation
- Faro receiver: Check Grafana Faro documentation
- S3 mounting: Check s3fs-fuse GitHub repository

## License

This is a sample configuration for educational purposes as part of the HashiCorp Certified Terraform Associate course.
