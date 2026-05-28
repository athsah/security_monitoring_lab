variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "subnet_id"             { type = string }
variable "key_name"              { type = string }
variable "windows_sg_id"         { type = string }
variable "linux_collector_sg_id" { type = string }
variable "splunk_sg_id"          { type = string }
variable "sql_sg_id"             { type = string }

variable "windows_instance_type" {
  description = "Instance type for Windows Server"
  type        = string
  default     = "t3.small"
}

variable "linux_instance_type" {
  description = "Instance type for Linux instances"
  type        = string
  default     = "t3.micro"
}

variable "splunk_instance_type" {
  description = "Instance type for Splunk"
  type        = string
  default     = "t3.small"
}
