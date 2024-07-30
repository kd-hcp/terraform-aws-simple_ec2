# Output the public ip address for the created EC2 instance
output "aws_instance_ip" {
  value = aws_instance.ec2_test.public_ip
  description = "Public IP address for web access"
}
