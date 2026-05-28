output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "windows_server_public_ip" {
  description = "Public IP of the Windows Server (for RDP)"
  value       = module.compute.windows_public_ip
}

output "linux_collector_public_ip" {
  description = "Public IP of the Linux Collector (for SSH)"
  value       = module.compute.linux_collector_public_ip
}

output "splunk_public_ip" {
  description = "Public IP of the Splunk Server — web UI on port 8000"
  value       = module.compute.splunk_public_ip
}

output "splunk_web_url" {
  description = "Direct URL to Splunk Web UI"
  value       = "http://${module.compute.splunk_public_ip}:8000"
}

output "sql_server_private_ip" {
  description = "Private IP of the SQL Server (access via Linux Collector)"
  value       = module.compute.sql_private_ip
}
