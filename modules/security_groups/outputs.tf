output "windows_sg_id"         { value = aws_security_group.windows.id }
output "linux_collector_sg_id" { value = aws_security_group.linux_collector.id }
output "splunk_sg_id"          { value = aws_security_group.splunk.id }
output "sql_sg_id"             { value = aws_security_group.sql.id }
