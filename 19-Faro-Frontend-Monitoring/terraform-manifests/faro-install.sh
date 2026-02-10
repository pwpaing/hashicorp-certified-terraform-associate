#!/bin/bash
# Update system
sudo yum update -y

# Install dependencies
sudo yum install -y wget git gcc gcc-c++ make automake autoconf pkgconfig libcurl-devel libxml2-devel fuse fuse-devel

# Install s3fs-fuse for mounting S3 bucket
cd /tmp
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
sudo make install

# Create mount point for S3 bucket
sudo mkdir -p /mnt/source-maps

# Mount S3 bucket using IAM role (no credentials needed)
sudo s3fs ${BUCKET_NAME} /mnt/source-maps -o iam_role=auto -o url=https://s3-${AWS_REGION}.amazonaws.com -o allow_other -o use_cache=/tmp

# Add to fstab for persistent mounting
echo "${BUCKET_NAME} /mnt/source-maps fuse.s3fs _netdev,iam_role=auto,url=https://s3-${AWS_REGION}.amazonaws.com,allow_other,use_cache=/tmp 0 0" | sudo tee -a /etc/fstab

# Install Docker for running Faro receiver
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directory for Faro receiver configuration
sudo mkdir -p /opt/faro-receiver
cd /opt/faro-receiver

# Create docker-compose.yml for Faro Receiver (Grafana Alloy)
cat <<'EOF' | sudo tee docker-compose.yml
version: '3.8'

services:
  alloy:
    image: grafana/alloy:latest
    container_name: faro-receiver
    ports:
      - "12345:12345"
    volumes:
      - ./config.alloy:/etc/alloy/config.alloy
      - /mnt/source-maps:/source-maps
    command: run --server.http.listen-addr=0.0.0.0:12345 --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy
    restart: unless-stopped
EOF

# Create Alloy configuration for Faro receiver
cat <<'EOF' | sudo tee config.alloy
// Faro receiver configuration
faro.receiver "default" {
  server {
    listen_address = "0.0.0.0"
    listen_port    = 12345
    cors_allowed_origins = ["*"]
  }

  sourcemaps {
    download = true
    locations = [
      {
        path = "/source-maps"
      }
    ]
  }

  output {
    logs   = [loki.write.default.receiver]
    traces = [otlp.exporter.default.input]
  }
}

// Loki endpoint for logs (configure your actual Loki endpoint)
loki.write "default" {
  endpoint {
    url = "http://localhost:3100/loki/api/v1/push"
  }
}

// OTLP exporter for traces (configure your actual tracing backend)
otelcol.exporter.otlp "default" {
  client {
    endpoint = "localhost:4317"
    tls {
      insecure = true
    }
  }
}
EOF

# Start Faro receiver
sudo docker-compose up -d

# Create a simple status page
sudo mkdir -p /var/www/html
cat <<'EOF' | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Faro Receiver Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { background: #d4edda; padding: 20px; border-radius: 5px; }
        .info { margin-top: 20px; }
        code { background: #f4f4f4; padding: 2px 5px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>Faro Receiver Status</h1>
    <div class="status">
        <h2>✓ Service Running</h2>
        <p>Faro receiver is active and accepting frontend monitoring data</p>
    </div>
    <div class="info">
        <h3>Configuration:</h3>
        <ul>
            <li>Faro Receiver Endpoint: <code>http://&lt;instance-ip&gt;:12345</code></li>
            <li>Source Maps Location: <code>/mnt/source-maps</code></li>
            <li>S3 Bucket: <code>${BUCKET_NAME}</code></li>
        </ul>
        <h3>Upload Source Maps:</h3>
        <p>To upload source maps to S3, you can:</p>
        <ul>
            <li>SSH to this instance and copy files to <code>/mnt/source-maps</code></li>
            <li>Use AWS CLI: <code>aws s3 cp your-sourcemap.js.map s3://${BUCKET_NAME}/</code></li>
            <li>Use AWS Console to upload to the S3 bucket</li>
        </ul>
    </div>
</body>
</html>
EOF

# Install and start nginx to serve status page
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Faro receiver setup completed!"
