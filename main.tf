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

# Check if the security group exists
data "aws_security_group" "existing" {
  filter {
    name   = "group-name"
    values = [var.sg_name_allow_http]
  }

  # Uncomment the VPC ID if you need to specify the VPC
  # vpc_id = "vpc-xxxxxxxx"
}

# check existing instance count for naming tag
data "aws_instances" "existing_simple_ec2" {
  filter{
    name = "tag:Group"
    values = ["ServiceNow Simple EC2"]
  }
}


locals {
  sg_exists = length(data.aws_security_group.existing.id)
  simple_ec2_count = length(data.aws_instances.existing_simple_ec2.ids)
}

# Create Security Group for compute http access
resource "aws_security_group" "allow-http" {
  count = local.sg_exists == 0 ? 1 : 0
  name  = "allow-http"
}

# Security Group - Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  count = local.sg_exists == 0 ? 1 : 0

  security_group_id = aws_security_group.allow-http[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Security Group - Egress Rule
resource "aws_vpc_security_group_egress_rule" "allow-all-traffic" {
  count = local.sg_exists == 0 ? 1 : 0

  security_group_id = aws_security_group.allow-http[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}


# Create AWS Compute Instance 
resource "aws_instance" "ec2_test" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"

  security_groups = [var.sg_name_allow_http]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo ${var.server_message} > /var/www/html/index.html
              EOF

  tags = {
    Name = "EC2 ServiceNow Test ${local.simple_ec2_count +1}"
    Group = "ServiceNow Simple EC2"
  }
}


