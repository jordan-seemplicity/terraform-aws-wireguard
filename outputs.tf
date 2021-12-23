output "vpn_sg_admin_id" {
  value       = aws_security_group.sg_wireguard_admin.id
  description = "ID of the internal Security Group to associate with other resources needing to be accessed on VPN."
}

output "vpn_sg_external_id" {
  value       = aws_security_group.sg_wireguard_external.id
  description = "ID of the external Security Group to associate with the VPN."
}

output "vpn_asg_name" {
  value       = aws_autoscaling_group.wireguard_asg.name
  description = "ID of the internal Security Group to associate with other resources needing to be accessed on VPN."
}
output "client_config_template" {
  description = "Wireguard client configuration example"
  value       = <<-EOT
    [Interface]
    PrivateKey = $${client_private_key}
    Address = 10.254.0.2/24
    DNS = ${cidrhost(var.wg_server_net, 1)}
    DNS = 8.8.8.8,8.8.4.4

    [Peer]
    PublicKey = ${local.wg_config.server.0.pubkey}
    AllowedIPs = ${join(",", [var.wg_server_net, data.aws_vpc.main.cidr_block])}
    Endpoint = ${aws_eip.main.0.public_ip}:${var.wg_server_port}
    PersistentKeepalive = ${var.wg_persistent_keepalive}
  EOT
}
