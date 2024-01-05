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

resource "aws_mq_configuration" "rabbitmq" {
  description    = "${var.env}-rabbitmq"
  name           = "${var.env}-rabbitmq"
  engine_type    = var.engine_type
  engine_version = var.engine_version

  data = ""
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name = "${var.env}-rabbitmq"

  configuration {
    id       = aws_mq_configuration.rabbitmq.id
    revision = aws_mq_configuration.rabbitmq.latest_revision
  }

  engine_type    = var.engine_type
  engine_version = var.engine_version
  host_instance_type = "mq.t2.micro"
  security_groups    = [aws_security_group.rabbitmq.id]

  user {
    username = "ExampleUser"
    password = "MindTheGap"
  }
}