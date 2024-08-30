# Se especifica el backend para el estado de Terraform, en este caso un bucket S3.
terraform {
  backend "s3" {
    bucket               = "bcpl-s3-nonprod-dev-terraform-state"
    key                  = "tfstate/Apificacion.tfstate"
    workspace_key_prefix = "UnityHA"
    region               = "us-east-1"
    endpoints = {
      s3 = "https://s3.us-east-1.amazonaws.com"
    }
  }
}

# Obtiene el estado de Terraform 'networking-apificacion.tfstate' de la infraestructura de red existente desde un bucket S3.
data "terraform_remote_state" "networking_state" {
  backend   = "s3"
  workspace = terraform.workspace
  config = {
    bucket               = "bcpl-s3-nonprod-dev-terraform-state"
    key                  = "tfstate/networking-apificacion.tfstate"
    workspace_key_prefix = "UnityHA"
    region               = "us-east-1"
    endpoints = {
      s3 = "https://s3.us-east-1.amazonaws.com"
    }
  }
}