resource "aws_iam_role" "role" {
  name = "${var.env}-${var.component}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(local.common_tags, { Name = "${var.env}-${var.component}-role"} )
}

resource "aws_iam_policy" "policy" {
  name        = "${var.env}-${var.component}-parameter-store-policy"
  path        = "/"
  description = "${var.env}-${var.component}-parameter-store-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": [
          "arn:aws:ssm:us-east-1:588365094154:parameter/${var.env}.${var.component}*",
          "arn:aws:ssm:us-east-1:588365094154:parameter/nexus*",
          "arn:aws:ssm:us-east-1:588365094154:parameter/${var.env}.docdb*",
          "arn:aws:ssm:us-east-1:588365094154:parameter/${var.env}.elasticache*",
          "arn:aws:ssm:us-east-1:588365094154:parameter/${var.env}.rds*",
          "arn:aws:ssm:us-east-1:588365094154:parameter/${var.env}.rabbitmq*"




        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
resource "aws_iam_instance_profile" "profile" {
  name = "${var.env}-${var.component}-role"
  role = aws_iam_role.role.name
}

resource "aws_security_group" "rabbitmq" {
  name        = "${var.env}-rabbitmq_security_group"
  description = "${var.env}-rabbitmq_security_group"
  vpc_id      = var.vpc_id

  ingress {
    description = "rabbitmq"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.allow_cidr
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.env}-rabbitmq_security_group"} )
}

#resource "aws_mq_configuration" "rabbitmq" {
#  description    = "${var.env}-rabbitmq"
#  name           = "${var.env}-rabbitmq"
#  engine_type    = var.engine_type
#  engine_version = var.engine_version
#
#  data = ""
#}
#
#resource "aws_mq_broker" "rabbitmq" {
#  broker_name = "${var.env}-rabbitmq"
#  deployment_mode = "SINGLE_INSTANCE"
#  engine_type    = var.engine_type
#  engine_version = var.engine_version
#  host_instance_type = "mq.t3.micro"
#  security_groups    = [aws_security_group.rabbitmq.id]
#  subnet_ids =var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids
#
##  configuration {
##    id       = aws_mq_configuration.rabbitmq.id
##    revision = aws_mq_configuration.rabbitmq.latest_revision
##  }
#
#
#
#  user {
#    username = data.aws_ssm_parameter.USER.value
#    password = data.aws_ssm_parameter.PASS.value
#  }
#}


resource "aws_spot_instance_request" "rabbitmq" {

  ami           = data.aws_ami.centos8.image_id
  instance_type = "t3.small"
  subnet_id = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  wait_for_fulfillment = true
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {component = "rabbitmq", env= var.env}))
  iam_instance_profile = aws_iam_instance_profile.profile.name


  tags = merge(local.common_tags, { Name = "${var.env}-rabbitmq"} )

}

resource "aws_route53_record" "rabbitmq" {
  zone_id = "Z01783243D3S1K1FW0QID"
  name    = "rabbitmq-${var.env}.pappik.online"
  type    = "A"
  ttl     = 30
  records = [aws_spot_instance_request.rabbitmq.private_ip]
}