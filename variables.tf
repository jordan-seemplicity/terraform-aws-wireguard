variable "ssh_key_id" {
  description = "A SSH public key ID to add to the VPN instance."
}

variable "instance_type" {
  default     = "t3a.micro"
  description = "The machine type to launch, some machines may offer higher throughput for higher use cases."
}

variable "vpc_id" {
  description = "The VPC ID in which Terraform will launch the resources."
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnets for the Autoscaling Group to use for launching instances. May be a single subnet, but it must be an element in a list."
}

variable "client_config_file" {
  type        = string
  description = "JSON configuration file containing peer configuration."
}

variable "wg_server_net" {
  default     = "10.254.0.1/24"
  description = "Private IP range in CIDR notation for VPN server. Make sure your clients do not conflict with the server IP."
}

variable "wg_server_port" {
  default     = 51820
  description = "Port for the vpn server."
}

variable "wg_persistent_keepalive" {
  default     = 25
  description = "Persistent Keepalive - useful for helping connection stability over NATs."
}

variable "use_eip" {
  type        = bool
  default     = false
  description = "Whether to enable Elastic IP switching code in user-data on wg server startup."
}

variable "eip_id" {
  type        = string
  default     = null
  description = "ID of the Elastic IP to use. When use_eip is enabled and eip_id is not provided, a new EIP will be generated and used."
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = [""]
  description = "Additional security groups if provided, default empty."
}

variable "wg_server_private_key_param" {
  default     = "/wireguard/wg-server-private-key"
  description = "The SSM parameter containing the WG server private key."
}


variable "ami_id" {
  default     = null # we check for this and use a data provider since we can't use it here
  description = "The AWS AMI to use for the WG server, defaults to the latest Ubuntu 20.04 AMI if not specified."
}

variable "wg_server_interface" {
  default     = "ens5"
  description = "The default interface to forward network traffic to."
}
