# Security Monitoring Lab — Terraform Infrastructure

AWS infrastructure for a cloud-based security monitoring lab. Deploys a full log collection
and SIEM pipeline using Windows Server, Linux Collector, PostgreSQL, and Splunk.

## Architecture

```
Your IP (SSH/RDP)
        │
        ▼
  ┌─────────────────────────────────────────────┐
  │                  AWS VPC                    │
  │              10.0.0.0/16                    │
  │                                             │
  │  ┌───────────┐       ┌───────────────────┐  │
  │  │  Windows  │─────▶│  Linux Collector  │  │
  │  │  Server   │ logs  │  (rsyslog/tshark) │  │
  │  └───────────┘       └────────┬──────────┘  │
  │                               │             │
  │                    ┌──────────┴──────────┐  │
  │                    │                     │  │
  │             ┌──────▼──────┐   ┌──────────▼┐ │
  │             │ PostgreSQL  │   │  Splunk   │ │
  │             │ (SQL Store) │   │  Server   │ │
  │             └─────────────┘   └───────────┘ │
  └─────────────────────────────────────────────┘
```

## Prerequisites

- AWS account with CLI configured (`aws configure`)
- Terraform >= 1.5.0 installed
- An EC2 key pair created in your target region

## Quick Start

```bash
# 1. Clone and enter the directory
git clone <your-repo>
cd security-monitoring-lab

# 2. Set your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your IP and key pair name

# 3. Initialize
terraform init

# 4. Preview
terraform plan

# 5. Deploy
terraform apply
```

After apply, Terraform outputs the IPs for every instance.

## Cost Estimate (us-east-1)

| Instance         | Type       | ~Monthly Cost |
|------------------|------------|---------------|
| Windows Server   | t3.medium  | ~$30          |
| Linux Collector  | t2.micro   | ~$0 (free tier)|
| Splunk Server    | t3.medium  | ~$30          |
| SQL Server       | t2.micro   | ~$0 (free tier)|

> **Tip:** Run `terraform destroy` when not actively working to avoid charges.

## Module Structure

```
├── main.tf                  # Root module, calls all child modules
├── variables.tf             # Input variable declarations
├── outputs.tf               # Output values (IPs, URLs)
├── terraform.tfvars.example # Variable template (copy → terraform.tfvars)
├── .gitignore
└── modules/
    ├── networking/          # VPC, Subnet, IGW, Route Tables
    ├── security_groups/     # Per-instance firewall rules
    └── compute/             # EC2 instances with bootstrap user_data
```
