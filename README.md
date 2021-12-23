# terraform-aws-wireguard

A Terraform module to deploy a WireGuard VPN server on AWS.

## Prerequisites
Before using this module, you'll need to generate a key pair for your server and client, and store the server's private key and client's public key in AWS SSM, which `cloud-init` will source and add to WireGuard's configuration.

- Install the WireGuard tools for your OS: https://www.wireguard.com/install/
- Generate a key pair for each client
  - `wg genkey | tee client1.key | wg pubkey > client1.pub`
- Generate a key pair for the server
  - `wg genkey | tee server.key | wg pubkey > server.pub`
- Add the server private key to the AWS SSM parameter: `/wireguard/wg-server-private-key`
  - `aws ssm put-parameter --name /wireguard/wg-server-private-key --type SecureString --value $(cat server.key)`

Peers are templated from a JSON-formatted configuration file specified in `client_config_file`. This file must exist prior to executing the module. See [examples/config.json](examples/config.json) for example.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Additional security groups if provided, default empty. | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | The AWS AMI to use for the WG server, defaults to the latest Ubuntu 20.04 AMI if not specified. | `any` | `null` | no |
| <a name="input_client_config_file"></a> [client\_config\_file](#input\_client\_config\_file) | JSON configuration file containing peer configuration. | `string` | n/a | yes |
| <a name="input_eip_id"></a> [eip\_id](#input\_eip\_id) | ID of the Elastic IP to use. When use\_eip is enabled and eip\_id is not provided, a new EIP will be generated and used. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The machine type to launch, some machines may offer higher throughput for higher use cases. | `string` | `"t3a.micro"` | no |
| <a name="input_ssh_key_id"></a> [ssh\_key\_id](#input\_ssh\_key\_id) | A SSH public key ID to add to the VPN instance. | `any` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnets for the Autoscaling Group to use for launching instances. May be a single subnet, but it must be an element in a list. | `list(string)` | n/a | yes |
| <a name="input_use_eip"></a> [use\_eip](#input\_use\_eip) | Whether to enable Elastic IP switching code in user-data on wg server startup. | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID in which Terraform will launch the resources. | `any` | n/a | yes |
| <a name="input_wg_persistent_keepalive"></a> [wg\_persistent\_keepalive](#input\_wg\_persistent\_keepalive) | Persistent Keepalive - useful for helping connection stability over NATs. | `number` | `25` | no |
| <a name="input_wg_server_interface"></a> [wg\_server\_interface](#input\_wg\_server\_interface) | The default interface to forward network traffic to. | `string` | `"ens5"` | no |
| <a name="input_wg_server_net"></a> [wg\_server\_net](#input\_wg\_server\_net) | Private IP range in CIDR notation for VPN server. Make sure your clients do not conflict with the server IP. | `string` | `"10.254.0.1/24"` | no |
| <a name="input_wg_server_port"></a> [wg\_server\_port](#input\_wg\_server\_port) | Port for the vpn server. | `number` | `51820` | no |
| <a name="input_wg_server_private_key_param"></a> [wg\_server\_private\_key\_param](#input\_wg\_server\_private\_key\_param) | The SSM parameter containing the WG server private key. | `string` | `"/wireguard/wg-server-private-key"` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_config_template"></a> [client\_config\_template](#output\_client\_config\_template) | Wireguard client configuration example |
| <a name="output_vpn_asg_name"></a> [vpn\_asg\_name](#output\_vpn\_asg\_name) | ID of the internal Security Group to associate with other resources needing to be accessed on VPN. |
| <a name="output_vpn_sg_admin_id"></a> [vpn\_sg\_admin\_id](#output\_vpn\_sg\_admin\_id) | ID of the internal Security Group to associate with other resources needing to be accessed on VPN. |
| <a name="output_vpn_sg_external_id"></a> [vpn\_sg\_external\_id](#output\_vpn\_sg\_external\_id) | ID of the external Security Group to associate with the VPN. |


# Peer configuration

On Mac OS, install `wireguard-tools` to generate keys and manage the VPN tunnel.

A configuration template is produced by the module.