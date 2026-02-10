# Create EC2 Instance for Faro Receiver
resource "aws_instance" "faro_receiver" {
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name              = var.key_name
  iam_instance_profile  = aws_iam_instance_profile.faro_ec2_profile.name
  vpc_security_group_ids = [
    aws_security_group.faro-ssh.id,
    aws_security_group.faro-receiver.id
  ]

  # User data script with variable substitution
  user_data = templatefile("${path.module}/faro-install.sh", {
    BUCKET_NAME = var.bucket_name
    AWS_REGION  = var.aws_region
  })

  # Increase root volume size for Docker images and logs
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "faro-receiver-instance"
    Environment = "Production"
    Purpose     = "Frontend Monitoring with Faro"
  }

  # Ensure IAM role is created before the instance
  depends_on = [
    aws_iam_role_policy_attachment.faro_s3_attach
  ]
}
