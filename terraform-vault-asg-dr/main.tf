resource "aws_autoscaling_group" "asg" {
  name                 = "${var.system_name}-${terraform.workspace}"
  desired_capacity     = var.asg_desired_cap
  min_size             = var.asg_min_cap
  max_size             = var.asg_max_cap
  termination_policies = ["OldestInstance"]
  availability_zones   = data.aws_availability_zones.zones.names

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
  target_group_arns = ["${aws_lb_target_group.vault-port.arn}"]
}

resource "aws_launch_template" "template" {
  name                   = "${var.system_name}-${terraform.workspace}"
  instance_type          = var.instance_type
  image_id               = data.aws_ami.ami.id
  ebs_optimized          = true
  vpc_security_group_ids = [aws_security_group.ec2_secgrp.id]
  key_name               = var.ssh_key_name

  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.profile.arn
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name          = "${var.system_name}-${terraform.workspace}"
      Source        = "Autoscaling"
      vault-cluster = "${var.cluster_name}"
    }
  }


  user_data = base64encode(data.template_file.user_data.rendered)
}

resource "aws_security_group" "ec2_secgrp" {
  name        = "${var.system_name}-instance-secgrp"
  description = "${var.system_name} instance secgrp"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port = var.application_port
    to_port   = var.application_port
    protocol  = "tcp"
    #cidr_blocks = [aws_default_vpc.default.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = var.api_port
    to_port   = var.api_port
    protocol  = "tcp"
    #cidr_blocks = [aws_default_vpc.default.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.cluster_port
    to_port     = var.cluster_port
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.system_name}-ec2-secgrp"
  }

}

resource "aws_default_vpc" "default" {
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.system_name}-${terraform.workspace}"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name               = "${var.system_name}-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_role_policy" "ec2_describe" {
  name   = "raft_ec2_describe"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.ec2_describe.json
}

resource "aws_kms_key" "vault-asg" {
  description             = "Vault ASG Key"
  deletion_window_in_days = 10
}

resource "aws_lb" "vault-asg-lb" {
  name               = "${var.system_name}-lb"
  internal           = false
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id            = data.aws_subnet.az-sub-a.id
  }
  subnet_mapping {
    subnet_id            = data.aws_subnet.az-sub-b.id
  }
  subnet_mapping {
    subnet_id            = data.aws_subnet.az-sub-c.id
  }
}

resource "aws_lb_listener" "vault-port" {
  load_balancer_arn = aws_lb.vault-asg-lb.arn
  port              = "8200"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault-port.arn
  }
}

resource "aws_lb_target_group" "vault-port" {
  name     = "${var.system_name}-tg"
  port     = 8200
  protocol = "TCP"
  vpc_id   = aws_default_vpc.default.id

  health_check {
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200-399"
    path                = "/v1/sys/health?perfstandbyok=true"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 2
  }
}