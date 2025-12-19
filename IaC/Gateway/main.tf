terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --------------------------
# Security Group
# --------------------------
resource "aws_security_group" "gateway_sg" {
  name = "gateway-server-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------
# EC2 Instance
# --------------------------

resource "aws_instance" "gateway_server" {
  ami           = "ami-00d8fc944fb171e29"
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.gateway_sg.id]

  tags = {
    Name = var.instance_name
  }

  # SSH connection
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  # Copy folder Gateway lên server
  provisioner "file" {
    source      = "../../Gateway"
    destination = "/home/ubuntu/Gateway"
  }

  # Chạy setup_gateway.sh sau khi copy xong
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/Gateway/setup_gateway.sh",
      "cd /home/ubuntu/Gateway",
      "sudo env AI_SERVER_IP=${var.ai_server_ip} ./setup_gateway.sh"
    ]
  }
}