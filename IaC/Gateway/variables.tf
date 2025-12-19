variable "aws_region" {
  default = "ap-southeast-1"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
  default     = "Hp_Envy-keypair"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "instance_name" {
  default = "gateway-server"
}

variable "ai_server_ip" {
  description = "Public IP of AI server"
}