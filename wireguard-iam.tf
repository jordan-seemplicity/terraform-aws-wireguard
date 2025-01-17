data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "wireguard_policy_doc" {
  statement {
    actions = [
      "ec2:AssociateAddress",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      format("arn:aws:ssm:%s:%s:parameter%s",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
        var.wg_server_private_key_param
      )
    ]
  }
}

resource "aws_iam_policy" "wireguard_policy" {
  name_prefix = "tf-wireguard"
  description = "Allows Wireguard instance to attach EIP."
  policy      = data.aws_iam_policy_document.wireguard_policy_doc.json
  count       = (var.use_eip ? 1 : 0) # only used for EIP mode
}

resource "aws_iam_role" "wireguard_role" {
  name_prefix        = "tf-wireguard"
  description        = "Role to allow Wireguard instance to attach EIP."
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  count              = (var.use_eip ? 1 : 0) # only used for EIP mode
}

resource "aws_iam_role_policy_attachment" "wireguard_roleattach" {
  role       = aws_iam_role.wireguard_role[0].name
  policy_arn = aws_iam_policy.wireguard_policy[0].arn
  count      = (var.use_eip ? 1 : 0) # only used for EIP mode
}

resource "aws_iam_instance_profile" "wireguard_profile" {
  name_prefix = "tf-wireguard"
  role        = aws_iam_role.wireguard_role[0].name
  count       = (var.use_eip ? 1 : 0) # only used for EIP mode
}
