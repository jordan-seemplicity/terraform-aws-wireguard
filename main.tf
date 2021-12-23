data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.txt")

  vars = {
    wg_server_private_key_param = var.wg_server_private_key_param
    wg_server_net               = var.wg_server_net
    wg_server_port              = var.wg_server_port
    peers                       = local.peer_config
    use_eip                     = var.use_eip ? "enabled" : "disabled"
    eip_id                      = local.eip_id
    wg_server_interface         = var.wg_server_interface
  }
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

locals {
  wg_config   = jsondecode(file(var.client_config_file))
  peer_config = <<-EOT
    %{~for peer in local.wg_config.peers}
    [Peer]
    PublicKey = ${peer.pubkey}
    AllowedIPs = ${peer.ip}
    PersistentKeepalive = ${var.wg_persistent_keepalive}
    %{endfor~}
  EOT
}

# We're using ubuntu images - this lets us grab the latest image for our region from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

locals {
  eip_id = var.eip_id != null ? var.eip_id : aws_eip.main.0.id
  # turn the sg into a sorted list of string
  sg_wireguard_external = sort([aws_security_group.sg_wireguard_external.id])
  # clean up and concat the above wireguard default sg with the additional_security_group_ids
  security_groups_ids = compact(concat(var.additional_security_group_ids, local.sg_wireguard_external))
}

resource "aws_eip" "main" {
  count = var.use_eip && var.eip_id == null ? 1 : 0
  vpc   = true
  tags = {
    Name = "wireguard-eip"
  }
}

resource "aws_launch_configuration" "wireguard_launch_config" {
  name_prefix                 = "wireguard-"
  image_id                    = var.ami_id == null ? data.aws_ami.ubuntu.id : var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_id
  iam_instance_profile        = (var.use_eip ? aws_iam_instance_profile.wireguard_profile[0].name : null)
  user_data                   = data.template_file.user_data.rendered
  security_groups             = local.security_groups_ids
  associate_public_ip_address = var.use_eip

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wireguard_asg" {
  name                 = aws_launch_configuration.wireguard_launch_config.name
  launch_configuration = aws_launch_configuration.wireguard_launch_config.name
  min_size             = 1
  desired_capacity     = 1
  max_size             = 1
  vpc_zone_identifier  = var.subnet_ids
  health_check_type    = "EC2"
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = aws_launch_configuration.wireguard_launch_config.name
      propagate_at_launch = true
    },
    {
      key                 = "Service"
      value               = "wireguard"
      propagate_at_launch = true
    },
  ]
}
