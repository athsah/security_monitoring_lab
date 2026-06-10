# ─────────────────────────────────────────────
# AMI Data Sources
# ─────────────────────────────────────────────

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

# ─────────────────────────────────────────────
# Splunk Server (created first — others depend on its private IP)
# ─────────────────────────────────────────────
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

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y wget curl net-tools

    # ── Seed admin password before first start ──────────────
    wget -q -O /tmp/splunk.deb "${var.splunk_download_url}"
    dpkg -i /tmp/splunk.deb

    mkdir -p /opt/splunk/etc/system/local

    cat > /opt/splunk/etc/system/local/user-seed.conf << SEED
[user_info]
USERNAME = admin
PASSWORD = ${var.splunk_password}
SEED

    # ── First start — accept license non-interactively ──────
    /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
    /opt/splunk/bin/splunk enable boot-start

    # ── Wait for Splunk REST API to be ready ─────────────────
    sleep 20

    # ── Create indexes ───────────────────────────────────────
    /opt/splunk/bin/splunk add index windows_events  -auth admin:${var.splunk_password}
    /opt/splunk/bin/splunk add index linux_logs       -auth admin:${var.splunk_password}
    /opt/splunk/bin/splunk add index network_traffic  -auth admin:${var.splunk_password}

    # ── Enable forwarder receiving on 9997 ───────────────────
    /opt/splunk/bin/splunk enable listen 9997 -auth admin:${var.splunk_password}

    # ── Enable HTTP Event Collector ──────────────────────────
    curl -sk -u admin:${var.splunk_password} \
      https://localhost:8089/services/data/inputs/http/http \
      -d disabled=0 -d enableSSL=0

    # ── Create HEC token for log ingestion ───────────────────
    curl -sk -u admin:${var.splunk_password} \
      https://localhost:8089/servicesNS/admin/splunk_httpinput/data/inputs/http \
      -d name=seclab_token \
      -d index=windows_events \
      -d indexes=windows_events,linux_logs,network_traffic

    /opt/splunk/bin/splunk restart
    echo "Splunk setup complete" > /home/ubuntu/splunk_setup.log
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-splunk-server"
    Role = "SIEM"
  }
}

# ─────────────────────────────────────────────
# SQL Server — PostgreSQL
# ─────────────────────────────────────────────
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

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y postgresql postgresql-contrib

    systemctl enable postgresql
    systemctl start postgresql

    # ── Create database, tables, and user ────────────────────
    sudo -u postgres psql << SQL
CREATE DATABASE securitylab;
\c securitylab

CREATE TABLE windows_events (
    id         SERIAL PRIMARY KEY,
    timestamp  TIMESTAMP DEFAULT NOW(),
    event_id   INT,
    source     VARCHAR(100),
    message    TEXT,
    raw_log    TEXT
);

CREATE TABLE failed_logins (
    id         SERIAL PRIMARY KEY,
    timestamp  TIMESTAMP DEFAULT NOW(),
    username   VARCHAR(100),
    source_ip  VARCHAR(50),
    event_id   INT
);

CREATE TABLE network_traffic (
    id         SERIAL PRIMARY KEY,
    timestamp  TIMESTAMP DEFAULT NOW(),
    src_ip     VARCHAR(50),
    dst_ip     VARCHAR(50),
    protocol   VARCHAR(20),
    port       INT,
    bytes      INT
);

CREATE USER seclab_user WITH PASSWORD '${var.db_password}';
GRANT ALL PRIVILEGES ON DATABASE securitylab TO seclab_user;
\c securitylab
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO seclab_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO seclab_user;
SQL

    # ── Allow connections from VPC ────────────────────────────
    PG_CONF=$(find /etc/postgresql -name "postgresql.conf" | head -1)
    PG_HBA=$(find /etc/postgresql -name "pg_hba.conf"    | head -1)

    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

    echo "host  securitylab  seclab_user  10.0.0.0/16  md5" >> $PG_HBA

    systemctl restart postgresql
    echo "PostgreSQL setup complete" > /home/ubuntu/sql_setup.log
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-sql-server"
    Role = "Database"
  }
}

# ─────────────────────────────────────────────
# Linux Collector
# Depends implicitly on splunk_server (uses its private IP)
# ─────────────────────────────────────────────
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

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y rsyslog tshark tcpdump python3 python3-pip postgresql-client

    # ── Configure rsyslog to receive from Windows ─────────────
    cat > /etc/rsyslog.d/99-seclab.conf << RSYSLOG
# Receive syslog over UDP and TCP
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")

# Write all received logs to a dedicated file
*.* /var/log/seclab/received.log
RSYSLOG

    mkdir -p /var/log/seclab
    systemctl restart rsyslog

    # ── Install Splunk Universal Forwarder ────────────────────
    wget -q -O /tmp/splunkuf.deb "${var.splunk_uf_linux_url}"
    dpkg -i /tmp/splunkuf.deb

    /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt \
      --seed-passwd "${var.splunk_password}"
    /opt/splunkforwarder/bin/splunk enable boot-start

    # ── Point forwarder at Splunk server ──────────────────────
    /opt/splunkforwarder/bin/splunk add forward-server \
      ${aws_instance.splunk_server.private_ip}:9997 \
      -auth admin:${var.splunk_password}

    # ── Monitor syslog and received logs ─────────────────────
    /opt/splunkforwarder/bin/splunk add monitor /var/log/syslog \
      -index linux_logs -auth admin:${var.splunk_password}
    /opt/splunkforwarder/bin/splunk add monitor /var/log/seclab/received.log \
      -index linux_logs -auth admin:${var.splunk_password}

    /opt/splunkforwarder/bin/splunk restart
    echo "Linux Collector setup complete" > /home/ubuntu/collector_setup.log
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-linux-collector"
    Role = "LogCollector"
  }
}

# ─────────────────────────────────────────────
# Windows Server
# Depends implicitly on splunk_server (uses its private IP)
# ─────────────────────────────────────────────
resource "aws_instance" "windows_server" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.windows_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.windows_sg_id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  # Windows user_data must be wrapped in <powershell> tags
  user_data = <<-EOF
    <powershell>
    $ErrorActionPreference = "Continue"
    $sysmonDir = "C:\Sysmon"

    # ── Install Sysmon ────────────────────────────────────────
    New-Item -ItemType Directory -Force -Path $sysmonDir | Out-Null

    Invoke-WebRequest `
      -Uri "https://download.sysinternals.com/files/Sysmon.zip" `
      -OutFile "$sysmonDir\Sysmon.zip" `
      -UseBasicParsing
    Expand-Archive -Path "$sysmonDir\Sysmon.zip" -DestinationPath $sysmonDir -Force

    Invoke-WebRequest `
      -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" `
      -OutFile "$sysmonDir\sysmonconfig.xml" `
      -UseBasicParsing

    & "$sysmonDir\Sysmon64.exe" -accepteula -i "$sysmonDir\sysmonconfig.xml"

    # ── Enable PowerShell Script Block Logging ────────────────
    $sbPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
    New-Item -Path $sbPath -Force | Out-Null
    Set-ItemProperty -Path $sbPath -Name "EnableScriptBlockLogging" -Value 1

    $mlPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
    New-Item -Path $mlPath -Force | Out-Null
    Set-ItemProperty -Path $mlPath -Name "EnableModuleLogging" -Value 1

    # ── Install Splunk Universal Forwarder ────────────────────
    Invoke-WebRequest `
      -Uri "${var.splunk_uf_windows_url}" `
      -OutFile "C:\splunkforwarder.msi" `
      -UseBasicParsing

    Start-Process msiexec.exe -ArgumentList (
      "/i C:\splunkforwarder.msi " +
      "RECEIVING_INDEXER=`"${aws_instance.splunk_server.private_ip}:9997`" " +
      "SPLUNK_ENABLE_BOOT_START=1 " +
      "AGREETOLICENSE=Yes " +
      "/quiet /norestart"
    ) -Wait

    # Wait for UF to finish installing
    Start-Sleep -Seconds 30

    # ── Configure what to monitor ─────────────────────────────
    $ufLocal = "C:\Program Files\SplunkUniversalForwarder\etc\system\local"
    New-Item -ItemType Directory -Force -Path $ufLocal | Out-Null

    @"
[WinEventLog://Security]
disabled = 0
index = windows_events

[WinEventLog://System]
disabled = 0
index = windows_events

[WinEventLog://Application]
disabled = 0
index = windows_events

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = 0
index = windows_events
renderXml = true
"@ | Out-File -FilePath "$ufLocal\inputs.conf" -Encoding ASCII

    @"
[tcpout]
defaultGroup = splunk_indexer

[tcpout:splunk_indexer]
server = ${aws_instance.splunk_server.private_ip}:9997
"@ | Out-File -FilePath "$ufLocal\outputs.conf" -Encoding ASCII

    Restart-Service SplunkForwarder -ErrorAction SilentlyContinue

    # ── Signal setup is done ──────────────────────────────────
    "Windows setup complete $(Get-Date)" | Out-File C:\setup_complete.txt
    </powershell>
    <persist>false</persist>
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-windows-server"
    Role = "LogSource"
  }
}
