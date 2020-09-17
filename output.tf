output "clients_IP_Address" {
  value = aws_instance.clients.*.public_ip
}

output "servers_IP_Address" {
  value = aws_instance.server.*.public_ip
}

# output "spot_IP_Address" {
#   value = aws_spot_instance_request.spot.*.public_ip
# }

output "clientsFriendlyURL" {
  value       = aws_route53_record.clientsURL.*.fqdn
  description = "List of DNS records for clients"
}

output "serversFriendlyURL" {
  value       = aws_route53_record.serversURL.*.fqdn
  description = "List of DNS records for servers"
}