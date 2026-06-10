variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "subnet_id"             { type = string }
variable "key_name"              { type = string }
variable "windows_sg_id"         { type = string }
variable "linux_collector_sg_id" { type = string }
variable "splunk_sg_id"          { type = string }
variable "sql_sg_id"             { type = string }

variable "windows_instance_type" {
  default     = "t3.small"
}

variable "linux_instance_type" {
  default     = "t3.micro"
}

variable "splunk_instance_type" {
  default     = "t3.small"
}

variable "splunk_password" {
  description = "Splunk admin password (min 8 chars, must contain letter + number)"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL seclab_user password"
  type        = string
  sensitive   = true
}

# ── Splunk download URLs ───────────────────────────────────────
# Get latest URLs from: https://www.splunk.com/en_us/download/splunk-enterprise.html
variable "splunk_download_url" {
  description = "Direct download URL for Splunk Enterprise .deb"
  type        = string
  default     = "https://download.splunk.com/products/splunk/releases/9.2.1/linux/splunk-9.2.1-78803f08aabb-linux-2.6-amd64.deb"
}

# Get latest URLs from: https://www.splunk.com/en_us/download/universal-forwarder.html
variable "splunk_uf_linux_url" {
  description = "Direct download URL for Splunk Universal Forwarder .deb (Linux)"
  type        = string
  default     = "https://download.splunk.com/products/universalforwarder/releases/9.2.1/linux/splunkforwarder-9.2.1-78803f08aabb-linux-2.6-amd64.deb"
}

variable "splunk_uf_windows_url" {
  description = "Direct download URL for Splunk Universal Forwarder .msi (Windows)"
  type        = string
  default     = "https://download.splunk.com/products/universalforwarder/releases/9.2.1/windows/splunkforwarder-9.2.1-78803f08aabb-x64-release.msi"
}
