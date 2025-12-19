variable "aws_region" {
  default = "ap-southeast-1"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}


variable "instance_name" {
  default = "ai-server"
}
