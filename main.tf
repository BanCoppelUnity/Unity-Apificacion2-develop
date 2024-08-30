# Se especifica la versión del proveedore AWS necesario para este código.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Se configura el proveedor AWS, especificando la región.
provider "aws" {
  region  = var.region
  profile = var.profile
}


locals {

  # Se agregan los tags de Date/Time y Environment
  tags = merge(var.tags, {
    "Date/Time"   = timeadd(timestamp(), "-6h")
    "Environment" = var.environment
  })

  # Define una variable que se usará como sufijo en los nombres de los recursos.
  postfix_name = "${var.partial_name}-${var.environment}"

  # Obtiene los identificadores de los grupos de seguridad de la infraestructura de red existente definida en el archivo 'networking-apificacion.tfstate'
  # La obtención de los identificadores se realiza a través del nombre de los mismos, estos deben contener el valor de "jenkins"
  security_groups_id = {
    for security_group_name, security_group_id in data.terraform_remote_state.networking_state.outputs.security_groups_id :
    security_group_name => security_group_id if can(regex("jenkins", security_group_name))
  }

  # Obtiene  el identificador de la subred de la infraestructura de red existente definida en el archivo 'networking-apificacion.tfstate'
  # La obtención del identificador se realiza a través del nombre del mismo, este debe contener el valor de "jenkins"
  subnet_id = [
    for subnet_name, subnet_id in data.terraform_remote_state.networking_state.outputs.subnets_id :
  subnet_id if can(regex("jenkins", subnet_name))][0]

  # Crea una estructura para definir los roles y las politicas que se deben crear
  role_policies_list = flatten([
    for role, policies in var.roles : [
      for policy, values in policies : {
        role        = role
        policy      = policy
        description = values.description
        file        = values.file
      }
    ]
  ])

  # Crea un mapa a partir de la estructura 'local.role_policies_list'  con un identificador a partir del role y la politica
  role_policies = {
    for values in local.role_policies_list :
    "${values.role}-${values.policy}" => values
  }
}

# Crea un rol IAM con la política especificada en el archivo 'assume_role_policy.json'.
resource "aws_iam_role" "iam_roles" {
  for_each           = var.roles
  name               = "bcpl-iam-${var.environment}-apificacion-${each.key}"
  assume_role_policy = file("policies/assume_role_policy.json")
  # Define las etiquetas para el NAT gateway, incluyendo las etiquetas 'Name' y 'Service Name'
  tags = merge(local.tags, {
    "Name"         = "bcpl-iam-${var.environment}-apificacion-${each.key}",
    "Service Name" = "iam",
  })
  # Ignora los cambias en la etiqueta 'Date/Time', dado que esta solo se considera al momento de la creación de los recursos
  lifecycle {
    ignore_changes = [tags["Date/Time"]]
  }
}

# Crea las políticas especificadas en 'var.policies'
resource "aws_iam_policy" "iam_policies" {
  for_each    = local.role_policies
  name        = "bcpl-iamp-${var.environment}-apificacion-${each.key}"
  description = each.value.description
  policy      = file("policies/${each.value.file}")
  # Define las etiquetas para el NAT gateway, incluyendo las etiquetas 'Name' y 'Service Name'
  tags = merge(local.tags, {
    "Name"         = "bcpl-iamp-${var.environment}-apificacion-${each.key}",
    "Service Name" = "iamp",
  })
  # Ignora los cambias en la etiqueta 'Date/Time', dado que esta solo se considera al momento de la creación de los recursos
  lifecycle {
    ignore_changes = [tags["Date/Time"]]
  }
}

# Asocia las políticas al rol
resource "aws_iam_role_policy_attachment" "policies_attachment" {
  for_each = aws_iam_policy.iam_policies
  role = aws_iam_role.iam_roles[[
    for role_name in keys(var.roles) :
    role_name if can(regex(role_name, each.key))
  ][0]].name
  policy_arn = each.value.arn

  # Especifica una dependencia explícita con el rol IAM y las políticas garantizando que se cree el recurso posterior a dichas dependencias
  depends_on = [
    aws_iam_role.iam_roles,
    aws_iam_policy.iam_policies
  ]
}


# Crea un nuevo perfil de instancia IAM a partir del rol IAM creado previamente.
# El perfil será asociado a cada una de las instancias EC2 que se crearán.
resource "aws_iam_instance_profile" "iam_instance_profiles" {
  for_each = var.roles
  name     = "bcpl-iamip-${var.environment}-apificacion-${each.key}"
  role     = aws_iam_role.iam_roles[each.key].name
  # Define las etiquetas para el NAT gateway, incluyendo las etiquetas 'Name' y 'Service Name'
  tags = merge(local.tags, {
    "Name"         = "bcpl-iamip-${var.environment}-apificacion-${each.key}",
    "Service Name" = "iamip",
  })
  # Ignora los cambias en la etiqueta 'Date/Time', dado que esta solo se considera al momento de la creación de los recursos
  lifecycle {
    ignore_changes = [tags["Date/Time"]]
  }
  # Especifica una dependencia explícita con el las asociaciones de politicas garantizando que se cree el recurso posterior a dicha dependencia.
  depends_on = [aws_iam_role.iam_roles]
}


# Crea la instancia EC2 espcificada utilizando el módulo 'Unity-VM-module'.
# Las características de la imagen de la instancia son especificadas en 'var.ami_filters' y 'var.ami_owners.'
# Se toman los grupos de seguridad y la subnet que serán asociados a la instancia de los valores especificados en 'local.security_groups_id' y 'local.subnet_id' respectivamente.
# Se especifica el tipo de instancia por el valor especificado en 'var.instance_type'.
# Se especifica si las intancias tendrán IP pública a través de 'var.associate_public_ip_address'
# Se espcifica la IP privada de la instancia a través de 'var.private_ip'
# Los volúmenes que serán asociados en la instancia se especifican con los valores contenidos en 'var.root_volume' y 'var.ebs_volumes'.
# En que caso de que se proporcione un script de inicio, estos se especifican en 'var.user_data'
module "module_VM" {
  source                      = "git::https://github.com/BanCoppelUnity/Unity-VM-module.git?ref=release_1.0.0_rc2"
  ami_filters                 = var.ami_filters
  ami_owners                  = var.ami_owners
  subnet_id                   = local.subnet_id
  security_groups_ids         = local.security_groups_id
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  iam_instance_profile        = aws_iam_instance_profile.iam_instance_profiles["jenkins-slave"].id
  partial_name                = var.partial_name
  profile                     = var.profile
  environment                 = var.environment
  instance_type               = var.instance_type
  region                      = var.region
  root_volume                 = var.root_volume
  ebs_volumes                 = var.ebs_volumes
  cpu_credits                 = var.cpu_credits
  monitoring                  = var.monitoring
  tags                        = local.tags
}