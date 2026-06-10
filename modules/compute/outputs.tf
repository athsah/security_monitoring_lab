output "windows_public_ip"        { value = aws_instance.windows_server.public_ip }
output "linux_collector_public_ip" { value = aws_instance.linux_collector.public_ip }
output "splunk_public_ip"          { value = aws_instance.splunk_server.public_ip }
output "sql_private_ip"            { value = aws_instance.sql_server.private_ip }
output "splunk_private_ip"         { value = aws_instance.splunk_server.private_ip }
