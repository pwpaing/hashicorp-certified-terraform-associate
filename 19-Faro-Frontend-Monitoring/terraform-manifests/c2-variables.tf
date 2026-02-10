# Input Variables
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.small"
}

variable "bucket_name" {
  description = "S3 Bucket name for source maps"
  type        = string
  default     = "faro-source-maps-bucket"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
  default     = "terraform-key"
}
