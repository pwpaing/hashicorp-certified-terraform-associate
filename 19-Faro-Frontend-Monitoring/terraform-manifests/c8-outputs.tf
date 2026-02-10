# Output Values
output "faro_receiver_public_ip" {
  description = "Public IP address of the Faro receiver EC2 instance"
  value       = aws_instance.faro_receiver.public_ip
}

output "faro_receiver_public_dns" {
  description = "Public DNS name of the Faro receiver EC2 instance"
  value       = aws_instance.faro_receiver.public_dns
}

output "faro_endpoint_url" {
  description = "Faro receiver endpoint URL"
  value       = "http://${aws_instance.faro_receiver.public_ip}:12345"
}

output "status_page_url" {
  description = "Status page URL"
  value       = "http://${aws_instance.faro_receiver.public_ip}"
}

output "s3_bucket_name" {
  description = "S3 bucket name for source maps"
  value       = aws_s3_bucket.source_maps.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for source maps"
  value       = aws_s3_bucket.source_maps.arn
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i terraform-key.pem ec2-user@${aws_instance.faro_receiver.public_ip}"
}

output "source_maps_mount_path" {
  description = "Path where S3 bucket is mounted on EC2 instance"
  value       = "/mnt/source-maps"
}
