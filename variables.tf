variable "aws_region"         { type = string; default = "us-west-1" }
variable "project_name"       { type = string; default = "seclab" }
variable "environment"        { type = string; default = "dev" }
variable "vpc_cidr"           { type = string; default = "10.0.0.0/16" }
variable "public_subnet_cidr" { type = string; default = "10.0.1.0/24" }

variable "allowed_cidr" {
  description = "Your home IP in CIDR format (e.g. 1.2.3.4/32)"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH/RDP access"
  type        = string
}

variable "splunk_password" {
  description = "Splunk admin password — min 8 chars, must contain letter + number"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL seclab_user password"
  type        = string
  sensitive   = true
}

variable "splunk_download_url" {
  description = "Splunk Enterprise .deb download URL"
  type        = string
  default     = "https://download.splunk.com/products/splunk/releases/9.2.1/linux/splunk-9.2.1-78803f08aabb-linux-2.6-amd64.deb"
}

variable "splunk_uf_linux_url" {
  description = "Splunk UF .deb download URL (Linux)"
  type        = string
  default     = "https://download.splunk.com/products/universalforwarder/releases/9.2.1/linux/splunkforwarder-9.2.1-78803f08aabb-linux-2.6-amd64.deb"
}

variable "splunk_uf_windows_url" {
  description = "Splunk UF .msi download URL (Windows)"
  type        = string
  default     = "https://download.splunk.com/products/universalforwarder/releases/9.2.1/windows/splunkforwarder-9.2.1-78803f08aabb-x64-release.msi"
}
