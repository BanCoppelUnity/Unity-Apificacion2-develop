variable "profile" {
  description = "Nombre de perfil para el despliegue de la infraestructura"
  type        = string
}

variable "region" {
  description = "Región en la que se desplegarán los recursos AWS"
  type        = string
}

variable "ami_filters" {
  description = "Filtros para seleccionar la AMI que se utilizará para desplegar la instancia"
  type = map(object({
    name   = string
    values = string
  }))
}

variable "ami_owners" {
  description = "Identificadores de cuenta que se utilizan para definir a quién le pertenece la AMI que se especifica a través de ami_filters"
  type        = string
}

variable "partial_name" {
  description = "Variable utilizada para el nombrado estándar de los recursos"
  type        = string
}

variable "environment" {
  description = "Variable utilizada para el nombrado estándar de los recursos"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia que será desplegada"
  type        = string
}

variable "root_volume" {
  description = "Estructuta que contendrá el tamaño y el tipo de la unidad de almacenamiento raíz de la instancia"
  type = object({
    size = string
    type = string
  })
}

variable "ebs_volumes" {
  description = "Estructuta que contendrá el nombre, el tamaño, el tipo de las unidades EBS que se asociaran a la instancia y si estás deben mantener la información aunque la instancia cambie"
  type = map(object({
    device_name = string
    volume_size = string
    volume_type = string
    stateful    = bool
  }))
  default = {}
}

variable "associate_public_ip_address" {
  description = "Variable utilizada para indicar si deben asociarse o no una dirección IP públicas a la instancia"
  type        = bool
}

variable "cpu_credits" {
  description = "Opción de creditos para el uso del CPU. Los valores valirdo son 'standard' y 'unlimited'. Es aplicable solo para las instancias de la serie T."
  type        = string
  default     = null
}

variable "monitoring" {
  description = "Habilita el monitoreo detallado para la instancia."
  type        = bool
}

variable "roles" {
  description = "Objeto que contiene mapas de objetos que definen el rol para el esclavo de Jenkins ('jenkins-slave')"
  type = object({
    jenkins-slave = map(object({
      description = string,
      file        = string
    }))
  })
}

variable "private_ip" {
  description = "IP privada a asociar a la instancias"
  type        = string
}

variable "tags" {
  description = "Etiquetas base para el recurso, adicionalmente se asignará la etiqueta Name"
  type        = map(string)
}