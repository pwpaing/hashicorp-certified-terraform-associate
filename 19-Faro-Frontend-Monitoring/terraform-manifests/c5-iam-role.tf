# IAM Role for EC2 Instance
resource "aws_iam_role" "faro_ec2_role" {
  name = "faro-ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "faro-ec2-role"
  }
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "faro_s3_policy" {
  name        = "faro-s3-access-policy"
  description = "Policy to allow EC2 instance to access S3 bucket for source maps"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.source_maps.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.source_maps.arn}/*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "faro_s3_attach" {
  role       = aws_iam_role.faro_ec2_role.name
  policy_arn = aws_iam_policy.faro_s3_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "faro_ec2_profile" {
  name = "faro-ec2-instance-profile"
  role = aws_iam_role.faro_ec2_role.name
}
