provider "aws" {
    region = "us-east-2"
}


# Retrieve the proper machine image for EC2 instance
data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Create Security Group for compute http access
resource "aws_security_group" "allow-http" {
  name = "allow-http"
}

# Security Group - Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Security Group - Egress Rule
resource "aws_vpc_security_group_egress_rule" "allow-all-traffic" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

# Create AWS Compute Instance 
resource "aws_instance" "ec2_test" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"

  security_groups = [aws_security_group.allow-http.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo ${var.server_message} > /var/www/html/index.html
              EOF

  tags = {
    Name = "EC2 TF.Test"
  }
}


