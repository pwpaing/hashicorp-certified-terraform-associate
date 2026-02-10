# Module 19: Faro Frontend Monitoring with S3 and EC2

## Overview

This module demonstrates how to set up a complete frontend monitoring infrastructure using:
- **Grafana Faro Receiver** (via Grafana Alloy) for collecting frontend telemetry
- **AWS S3** for storing JavaScript source maps
- **AWS EC2** with S3FS to mount the S3 bucket for seamless access
- **IAM roles** for secure, keyless authentication

## What You'll Learn

By completing this module, you will learn how to:

1. ✅ Create an S3 bucket with encryption and versioning using Terraform
2. ✅ Set up IAM roles and policies for EC2-to-S3 access
3. ✅ Deploy an EC2 instance with automated setup via user data
4. ✅ Configure security groups for web traffic and monitoring endpoints
5. ✅ Mount an S3 bucket on EC2 using s3fs-fuse
6. ✅ Run containerized applications (Docker) on EC2
7. ✅ Integrate frontend applications with Grafana Faro
8. ✅ Manage source maps for error stack trace decoding

## Module Structure

```
19-Faro-Frontend-Monitoring/
├── README.md                    # Complete setup guide
├── QUICKSTART.md               # 5-minute quick start guide
├── ARCHITECTURE.md             # Architecture diagrams and details
├── INTEGRATION-EXAMPLES.md     # Frontend integration code samples
└── terraform-manifests/        # Terraform configuration files
    ├── c1-versions.tf          # Terraform and provider versions
    ├── c2-variables.tf         # Input variables
    ├── c3-security-groups.tf   # Security group definitions
    ├── c4-s3-bucket.tf         # S3 bucket configuration
    ├── c5-iam-role.tf          # IAM role and policies
    ├── c6-ami-datasource.tf    # AMI data source
    ├── c7-ec2-instance.tf      # EC2 instance configuration
    ├── c8-outputs.tf           # Output values
    ├── faro-install.sh         # User data script
    └── terraform.tfvars.example # Example variables file
```

## Getting Started

### Prerequisites

- AWS account with appropriate permissions
- AWS CLI configured with credentials
- Terraform >= 1.4 installed
- SSH key pair in AWS (default name: `terraform-key`)
- Basic understanding of frontend JavaScript applications

### Quick Start

Follow these steps to get started:

1. **Read the [QUICKSTART.md](./QUICKSTART.md)** for a 5-minute setup guide
2. **Review [README.md](./README.md)** for detailed instructions
3. **Check [ARCHITECTURE.md](./ARCHITECTURE.md)** to understand the infrastructure
4. **Use [INTEGRATION-EXAMPLES.md](./INTEGRATION-EXAMPLES.md)** to integrate your frontend app

### Deployment Steps

```bash
# 1. Navigate to terraform directory
cd terraform-manifests

# 2. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Initialize Terraform
terraform init

# 4. Review the plan
terraform plan

# 5. Deploy
terraform apply

# 6. Get outputs
terraform output
```

## Use Cases

This setup is ideal for:

- 🎯 **Production Monitoring**: Track errors, performance, and user behavior in production
- 🐛 **Error Debugging**: Use source maps to decode minified JavaScript errors
- 📊 **Performance Tracking**: Monitor Web Vitals and custom metrics
- 🔍 **User Analytics**: Understand how users interact with your application
- 📈 **Business Insights**: Track conversion funnels and user journeys

## What Gets Created

When you run `terraform apply`, the following AWS resources are created:

### Core Infrastructure
- **1 EC2 Instance** (t2.small by default)
  - Running Amazon Linux 2
  - 30GB encrypted EBS volume
  - Docker + Grafana Alloy container
  - Nginx status page

### Storage
- **1 S3 Bucket**
  - AES256 encryption enabled
  - Versioning enabled
  - Public access blocked
  - Mounted on EC2 at `/mnt/source-maps`

### Security & Access
- **2 Security Groups**
  - SSH access (port 22)
  - Web traffic (ports 80, 443, 12345)
- **1 IAM Role**
  - EC2 assume role policy
  - S3 read/write permissions
- **1 IAM Policy**
  - Scoped to specific S3 bucket
- **1 IAM Instance Profile**
  - Attached to EC2 instance

### Networking
- Uses default VPC
- Public IP assigned to EC2
- Internet Gateway for outbound access

## Architecture Highlights

```
Frontend App → Faro SDK → EC2:12345 → Grafana Alloy
                                           ↓
                                    Process Data
                                           ↓
                        Export to Loki/Tempo/Prometheus

EC2 Instance → IAM Role → S3 Bucket
     ↓                        ↓
S3FS Mount              Source Maps
```

## Key Features

### 🔐 Security
- IAM role-based authentication (no hardcoded credentials)
- Encrypted storage (S3 and EBS)
- Private S3 bucket
- Configurable security groups

### 📦 Automated Setup
- Complete infrastructure as code
- Automated software installation
- Docker containerization
- Persistent S3 mounting

### 🔄 Production Ready
- S3 versioning for source maps
- Encrypted data at rest
- Scalable architecture
- Easy to customize

### 📚 Well Documented
- Comprehensive README
- Quick start guide
- Architecture documentation
- Integration examples for React, Vue, Angular

## Costs

Estimated monthly cost in `us-east-1` region:

| Resource | Cost |
|----------|------|
| EC2 t2.small (24/7) | ~$17/month |
| S3 storage | ~$0.023/GB/month |
| Data transfer | First 100GB free |
| **Total** | **~$17-25/month** |

💡 **Tip**: Use Reserved Instances to save 40-60% on EC2 costs.

## Next Steps

After deploying the infrastructure:

1. ✅ Access the status page at `http://<ec2-ip>`
2. ✅ Verify Faro receiver at `http://<ec2-ip>:12345`
3. ✅ Integrate your frontend app (see INTEGRATION-EXAMPLES.md)
4. ✅ Upload source maps to S3
5. ✅ Monitor your application!

## Troubleshooting

Common issues and solutions:

- **Terraform apply fails**: Check AWS credentials and permissions
- **Can't access port 12345**: Verify security group rules
- **S3 mount not working**: Check IAM role attachment
- **Source maps not applied**: Verify filenames match exactly

See [README.md](./README.md#troubleshooting) for detailed troubleshooting.

## Learning Objectives Achieved

After completing this module, you will have hands-on experience with:

✅ **Terraform Resources**:
- `aws_s3_bucket` and related resources
- `aws_instance` with user data
- `aws_iam_role`, `aws_iam_policy`, `aws_iam_instance_profile`
- `aws_security_group`
- `data.aws_ami` data source

✅ **Terraform Features**:
- Template files (`templatefile()` function)
- Output values
- Variable management
- Resource dependencies

✅ **AWS Services**:
- EC2 instance management
- S3 bucket configuration
- IAM role-based access
- Security groups
- VPC networking

✅ **DevOps Practices**:
- Infrastructure as Code
- Automated provisioning
- Container orchestration
- CI/CD integration

## Related Modules

This module builds upon concepts from:
- **Module 04**: Terraform Resources
- **Module 05**: Terraform Variables
- **Module 06**: Terraform Datasources
- **Module 09**: Terraform Provisioners

## Additional Resources

### Documentation
- [Grafana Faro](https://grafana.com/docs/faro/)
- [Grafana Alloy](https://grafana.com/docs/alloy/)
- [AWS S3](https://docs.aws.amazon.com/s3/)
- [AWS IAM](https://docs.aws.amazon.com/iam/)
- [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse)

### Terraform Registry
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Cleanup

To destroy all resources and avoid charges:

```bash
cd terraform-manifests
terraform destroy
```

⚠️ **Note**: Empty the S3 bucket before destroying, or use the AWS console to force delete.

## Support and Contributions

This is a learning module for the HashiCorp Certified Terraform Associate course.

For issues:
- **Terraform**: Check official documentation
- **Faro**: Visit Grafana community forums
- **AWS**: Consult AWS documentation

## License

Educational material for HashiCorp Terraform certification preparation.

---

**Ready to get started?** Head over to [QUICKSTART.md](./QUICKSTART.md) for a 5-minute setup guide!
