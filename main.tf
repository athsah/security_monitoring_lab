terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SecurityMonitoringLab"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Networking (VPC, Subnets, IGW, Route Tables)
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  aws_region         = var.aws_region
}

# Security Groups
module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  allowed_cidr = var.allowed_cidr
  vpc_cidr     = var.vpc_cidr
}

# Compute (EC2 Instances)
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.networking.public_subnet_id
  key_name              = var.key_name
  windows_sg_id         = module.security_groups.windows_sg_id
  linux_collector_sg_id = module.security_groups.linux_collector_sg_id
  splunk_sg_id          = module.security_groups.splunk_sg_id
  sql_sg_id             = module.security_groups.sql_sg_id
}
