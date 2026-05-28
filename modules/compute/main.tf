# Windows Server 2022 
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Ubuntu 22.04 LTS 
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Windows Server (Log Source)
resource "aws_instance" "windows_server" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.windows_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.windows_sg_id]

  # Increase root volume — Windows needs space
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-windows-server"
    Role = "LogSource"
  }
}


# Linux Collector
resource "aws_instance" "linux_collector" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.linux_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.linux_collector_sg_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # Bootstrap: install rsyslog, tshark, tcpdump on first boot
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y rsyslog tshark tcpdump python3 python3-pip
    systemctl enable rsyslog
    systemctl start rsyslog
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-linux-collector"
    Role = "LogCollector"
  }
}

# Splunk Server
# t3.medium minimum — Splunk needs 2GB+ RAM
resource "aws_instance" "splunk_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.splunk_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.splunk_sg_id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # Bootstrap: just prep the system — install Splunk manually (Splunk requires accepting a license interactively)
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y wget curl net-tools
    echo "Splunk server ready — install Splunk manually via SSH" > /home/ubuntu/README.txt
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-splunk-server"
    Role = "SIEM"
  }
}

# SQL Server (PostgreSQL on Ubuntu)
resource "aws_instance" "sql_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.linux_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.sql_sg_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  # Bootstrap: install PostgreSQL
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y postgresql postgresql-contrib
    systemctl enable postgresql
    systemctl start postgresql
    # Allow connections from VPC (you'll tune pg_hba.conf manually)
    echo "PostgreSQL installed — configure pg_hba.conf and postgresql.conf to allow VPC access" \
      >> /home/ubuntu/README.txt
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-sql-server"
    Role = "Database"
  }
}
