# Creación de recursos adicionales para la prueba
locals {

  # Crea un bloque CIDR para crear la VPC y la subnet de la prueba
  ip_parts = split(".", var.private_ip)
  network  = join(".", [local.ip_parts[0], local.ip_parts[1]])


  # Definición del bloque CIDR para la VPC que se generará para la prueba 
  vpc_cidr_block = "${local.network}.0.0/16"

  # Definición del bloque CIDR para la subnet que se generará para la prueba
  subnet_cidr_block = "${local.network}.${local.ip_parts[2]}.0/24"

  # Definición de la zona de disponibilidad  para la subnet que se generará para la prueba
  subnet_availability_zone = "${var.region}a"

  # Variable para almacenar el valor de los identificadores de los grupos de seguridad para la prueba
  security_groups_config = {
    "sg-${var.partial_name}-1" = aws_security_group.security_group_test_1.id,
    "sg-${var.partial_name}-2" = aws_security_group.security_group_test_2.id
    "sg-${var.partial_name}-3" = aws_security_group.security_group_test_3.id
  }

  # Variable para almacenar el valor del identificador de la subnet para la prueba
  subnet_config = {
    "snet-${var.partial_name}" = aws_subnet.subnet_test.id
  }
}

# Recurso para crear una VPC (Virtual Private Cloud) para la prueba
resource "aws_vpc" "vpc_test" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Recurso para crear una subnet para la prueba
resource "aws_subnet" "subnet_test" {
  vpc_id            = aws_vpc.vpc_test.id
  cidr_block        = local.subnet_cidr_block
  availability_zone = local.subnet_availability_zone
}

# Recurso para crear un grupo de seguridad para la prueba que permite tráfico HTTP
resource "aws_security_group" "security_group_test_1" {
  vpc_id = aws_vpc.vpc_test.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Recurso para crear un grupo de seguridad para la prueba que permite tráfico SSH
resource "aws_security_group" "security_group_test_2" {
  vpc_id = aws_vpc.vpc_test.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Recurso para crear un grupo de seguridad para la prueba que permite tráfico SSH
resource "aws_security_group" "security_group_test_3" {
  vpc_id = aws_vpc.vpc_test.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Recurso para crear un rolee para la prueba
resource "aws_iam_role" "test_iam_role" {
  name = "test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Recurso para crear un instance profile para la prueba
resource "aws_iam_instance_profile" "test_instance_profile" {
  name = "test-profile"
  role = aws_iam_role.test_iam_role.name
}
