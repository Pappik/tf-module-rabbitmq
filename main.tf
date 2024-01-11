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


  tags = merge(local.common_tags, { Name = "${var.env}-rabbitmq"} )

}

resource "aws_route53_record" "rabbitmq" {
  zone_id = "Z01783243D3S1K1FW0QID"
  name    = "rabbitmq-${var.env}.pappik.online"
  type    = "A"
  ttl     = 300
  records = [aws_spot_instance_request.rabbitmq.private_ip]
}