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

resource "aws_mq_broker" "rabbitmq" {
  broker_name = "${var.env}-rabbitmq"
  deployment_mode = "SINGLE_INSTANCE"
  engine_type    = var.engine_type
  engine_version = var.engine_version
  host_instance_type = "mq.t3.micro"
  security_groups    = [aws_security_group.rabbitmq.id]
  subnet_ids =var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids

#  configuration {
#    id       = aws_mq_configuration.rabbitmq.id
#    revision = aws_mq_configuration.rabbitmq.latest_revision
#  }



  user {
    username = data.aws_ssm_parameter.USER.value
    password = data.aws_ssm_parameter.PASS.value
  }
}

resource "aws_ssm_parameter" "rabbitmq_endpoint" {
  name  = "${var.env}.rabbitmq_ENDPOINT"
  type  = "String"
  value = replace(replace(aws_mq_broker.rabbitmq.instances.0.endpoints.0, "amqps://", ""), ":5671", "")
}