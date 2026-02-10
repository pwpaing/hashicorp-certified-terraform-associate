# Create Security Group - SSH Traffic
resource "aws_security_group" "faro-ssh" {
  name        = "faro-ssh"
  description = "Allow SSH traffic for Faro receiver instance"
  
  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # WARNING: 0.0.0.0/0 allows access from any IP address
    # For production, restrict this to your specific IP or IP range
    # Example: cidr_blocks = ["203.0.113.0/24"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "faro-ssh-sg"
  }
}

# Create Security Group - Faro Receiver Traffic
resource "aws_security_group" "faro-receiver" {
  name        = "faro-receiver"
  description = "Allow HTTP/HTTPS traffic for Faro receiver"
  
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 12345 for Faro Receiver"
    from_port   = 12345
    to_port     = 12345
    protocol    = "tcp"
    # WARNING: 0.0.0.0/0 allows access from any IP address
    # For production, restrict this to your frontend app origins or CDN IPs
    # Example: cidr_blocks = ["203.0.113.0/24", "198.51.100.0/24"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "faro-receiver-sg"
  }
}
