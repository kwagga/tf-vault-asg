data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon", "self"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}


data "aws_availability_zones" "zones" {
  state = "available"
}

data "template_file" "user_data" {
  template = file(var.user_data)

  vars = {
    region        = var.region
    kms_key_id    = aws_kms_key.vault-asg.key_id
    vault_cluster = var.cluster_name
    vault_version = var.vault_version
    vault_license = var.vault_license
  }

}

data "aws_iam_policy_document" "ec2_describe" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      "${aws_kms_key.vault-asg.arn}",
    ]
  }
}

# We need to collect the existing subnets per AZ to add to the LB
data "aws_subnet" "az-sub-a" {
  filter {
    name   = "availability-zone"
    values = ["${var.region}a"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_default_vpc.default.id]
  }
}
data "aws_subnet" "az-sub-b" {
  filter {
    name   = "availability-zone"
    values = ["${var.region}b"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_default_vpc.default.id]
  }
}
data "aws_subnet" "az-sub-c" {
  filter {
    name   = "availability-zone"
    values = ["${var.region}c"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_default_vpc.default.id]
  }
}
