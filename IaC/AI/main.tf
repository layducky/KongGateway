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
resource "aws_security_group" "ai_sg" {
  name = "ai-server-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9178
    to_port     = 9178
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
resource "aws_instance" "ai_server" {
  ami           = "ami-00d8fc944fb171e29"
  instance_type = "m7i-flex.large"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.ai_sg.id]

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

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

  # Copy folder AI lên server
  provisioner "file" {
    source      = "../../AI"
    destination = "/home/ubuntu/AI"
  }

  # Chạy setup_AI.sh sau khi copy xong
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/AI/setup_AI.sh",
      "cd /home/ubuntu/AI",
      "sudo ./setup_AI.sh"
    ]
  }
}
