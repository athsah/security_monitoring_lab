variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "Short name prefix for all resources"
  type        = string
  default     = "seclab"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_cidr" {
  description = "IP in CIDR format (e.g. 1.2.3.4/32) — restricts RDP/SSH/Splunk access"
  type        = string
  # Set this in terraform.tfvars — do NOT leave as 0.0.0.0/0 in production
}

variable "key_name" {
  description = "Name of an existing AWS EC2 key pair for SSH/RDP access"
  type        = string
}
