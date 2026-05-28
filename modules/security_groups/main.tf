# ─────────────────────────────────────────────
# Windows Server Security Group
# Allows: RDP from your IP, WinRM from VPC
# ─────────────────────────────────────────────
resource "aws_security_group" "windows" {
  name        = "${var.project_name}-${var.environment}-windows-sg"
  description = "Windows Server - RDP + internal log forwarding"
  vpc_id      = var.vpc_id

  ingress {
    description = "RDP from allowed IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "WinRM from VPC (for automation)"
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-windows-sg" }
}

# Linux Collector Security Group
# Allows: SSH from your IP, syslog from VPC
resource "aws_security_group" "linux_collector" {
  name        = "${var.project_name}-${var.environment}-linux-collector-sg"
  description = "Linux Collector - SSH + syslog receiver"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Syslog UDP from VPC"
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Syslog TCP from VPC"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-linux-collector-sg" }
}

# Splunk Server Security Group
# Allows: Web UI (8000) + HEC (8088) from your IP, mgmt from VPC
resource "aws_security_group" "splunk" {
  name        = "${var.project_name}-${var.environment}-splunk-sg"
  description = "Splunk - Web UI, HEC, and forwarder ports"
  vpc_id      = var.vpc_id

  ingress {
    description = "Splunk Web UI from allowed IP"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Splunk HEC (HTTP Event Collector) from VPC"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Splunk forwarder receiver from VPC"
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-splunk-sg" }
}

# SQL Server Security Group
# Allows: PostgreSQL from VPC only (no public exposure)
resource "aws_security_group" "sql" {
  name        = "${var.project_name}-${var.environment}-sql-sg"
  description = "SQL Server - PostgreSQL internal only"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "SSH from allowed IP (for admin)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-sql-sg" }
}
